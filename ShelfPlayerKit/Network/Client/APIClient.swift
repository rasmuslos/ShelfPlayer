//
//  APIClient.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation
@preconcurrency import Security
import OSLog
import CryptoKit
@preconcurrency import Combine

public final actor APIClient: Sendable {
    let logger: Logger
    
    var requestQueue: [any APIRequestProtocol] = []
    var activeRequests: [String: Task<Void, Error>] = [:]
    
    var attempts: [String: Int] = [:]
    var authorizationRefreshTask: Task<Void, Error>?
    
    let responseSubject = PassthroughSubject<(String, (Decodable?, Error?)), Never>()
    
    var subscribers = [UUID: AnyCancellable]()
    nonisolated let responsePublisher: AnyPublisher<(String, (Decodable?, Error?)), Never>
    
    nonisolated(unsafe) let cache = NSCache<NSString, CachedAPIResponse>()
    
    let connectionID: ItemIdentifier.ConnectionID
    
    let session: URLSession
    
    let host: URL
    let headers: [HTTPHeader]
    
    let credentialProvider: APICredentialProvider
    
    #if DEBUG
    public var requestCount = 0

    public func incrementRequestCount() {
        requestCount += 1
    }
    public func resetRequestCount() {
        requestCount = 0
    }
    #endif
    
    public init(connectionID: ItemIdentifier.ConnectionID, credentialProvider: APICredentialProvider) async throws {
        logger = .init(subsystem: "io.rfk.shelfPlayerKit", category: "APIClient::\(connectionID)")
        
        cache.countLimit = 120
        
        self.connectionID = connectionID
        self.credentialProvider = credentialProvider
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = ShelfPlayerKit.httpCookieStorage
        configuration.urlCache = nil
        
        session = URLSession(configuration: configuration, delegate: URLSessionDelegate(), delegateQueue: nil)
        session.sessionDescription = "ShelfPlayer APIClient::\(connectionID)"
        
        (host, headers) = try await credentialProvider.configuration
        
        responsePublisher = responseSubject.eraseToAnyPublisher()
    }
    deinit {
        activeRequests.forEach {
            $0.value.cancel()
        }
    }
    
    final class URLSessionDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            await PersistenceManager.shared.authorization.handleURLSessionChallenge(challenge)
        }
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
            if let path = task.originalRequest?.url?.pathComponents, path.count == 3 && path[1] == "auth" && path[2] == "openid" {
                nil
            } else {
                request
            }
        }
    }
}

extension APIClient {
    func clearCookies() {
        guard let cookies = ShelfPlayerKit.httpCookieStorage.cookies else {
            return
        }
        
        for cookie in cookies {
            ShelfPlayerKit.httpCookieStorage.deleteCookie(cookie)
        }
    }
    
    final class CachedAPIResponse {
        let validUntil: Date
        let response: Decodable & Sendable
        
        init(validUntil: Date, response: Decodable & Sendable) {
            self.validUntil = validUntil
            self.response = response
        }
    }
}

public extension APIClient {
    var requestHeaders: [String: String] {
        get async throws {
            var headers: [String: String] = [:]
            
            for pair in self.headers.sorted(by: { $0.key < $1.key }) {
                headers[pair.key] = pair.value
            }
            
            if let accessToken = try await credentialProvider.accessToken {
                headers["Authorization"] = "Bearer \(accessToken)"
            }
            
            return headers
        }
    }
    
    func request(_ request: any APIRequestProtocol) async throws -> URLRequest {
        var url = host.appending(path: request.path)
        
        url.append(queryItems: request.query)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.value
        urlRequest.timeoutInterval = request.timeout
        
        urlRequest.allHTTPHeaderFields?.removeAll()
        
        try await authorizeRequest(&urlRequest)
        
        for header in request.headers {
            urlRequest.setValue(header.1, forHTTPHeaderField: header.0)
        }
        
        if let body = request.body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                if let encodable = body as? Encodable {
                    urlRequest.httpBody = try JSONEncoder().encode(encodable)
                } else {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                }
            } catch {
                logger.error("Failed to encode body: \(error, privacy: .public)")
                throw APIClientError.serializeError
            }
        }
        
        return urlRequest
    }
    func response<R: Sendable>(_ request: APIRequest<R>) async throws -> R {
        resetAttempts(request.id)
        
        if request.bypassesScheduler {
            let response = try await perform(request)
            return try request.typecast(decodable: response)
        } else {
            if !request.bypassesOffline, await !OfflineMode.shared.isAvailable(connectionID) {
                throw APIClientError.offline
            }
            
            if !activeRequests.keys.contains(request.id) {
                let exists = requestQueue.contains { $0.id == request.id }
                
                if !exists {
                    requestQueue.append(request)
                }
            }
            
            return try await waitForCompletion(id: request.id)
        }
    }
    
    func flush() {
        attempts.removeAll()
        cache.removeAllObjects()
    }
}

private extension APIClient {
    // MARK: Queue
    
    func waitForCompletion<R: Sendable>(id: String) async throws -> R {
        let uuid = UUID()
        let continuationBox = CheckedContinuationBox<R>()
        
        return try await withTaskCancellationHandler {
            defer {
                cleanup(uuid: uuid)
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                continuationBox.store(continuation)
                
                let responseSubscriber = self.responsePublisher
                    .first { $0.0 == id }
                    .sink {
                        let (response, error) = $1
                        
                        if let response = response as? R {
                            continuationBox.resume(returning: response)
                        } else if let error {
                            continuationBox.resume(throwing: error)
                        } else {
                            continuationBox.resume(throwing: APIClientError.serializeError)
                        }
                    }
      
                subscribers[uuid] = responseSubscriber
                dispatchQueued()
            }
        } onCancel: {
            continuationBox.resume(throwing: CancellationError())
            
            Task {
                await cleanup(uuid: uuid)
            }
        }
    }
    func cleanup(uuid: UUID) {
        subscribers[uuid] = nil
    }
    
    func dispatchQueued() {
        guard activeRequests.count <= 5 && !requestQueue.isEmpty else {
            return
        }
        
        let request = requestQueue.removeFirst()
        
        logger.info("Spawning request to \(request.path) (\(self.activeRequests.count) active, \(self.requestQueue.count) in queue)")
        
        activeRequests[request.id] = Task<Void, Error> {
            await performQueuedRequest(request.id, request)
            activeRequests[request.id] = nil
        }
        
        dispatchQueued()
    }
    func requeue(_ request: any APIRequestProtocol) {
        requestQueue.insert(request, at: 0)
        dispatchQueued()
    }
    
    func performQueuedRequest(_ id: String, _ request: any APIRequestProtocol) async {
        do {
            let response = try await perform(request)
            responseSubject.send((id, (response, nil)))
        } catch {
            responseSubject.send((id, (nil, error)))
        }
        
        dispatchQueued()
    }
    @concurrent
    nonisolated func perform(_ request: any APIRequestProtocol) async throws -> Decodable & Sendable {
        logger.info("Performing \(request.method.value) \(request.path)")
        
        #if DEBUG
        await incrementRequestCount()
        #endif
        
        let cacheKey = NSString(string: request.id)
        
        if let cached = cache.object(forKey: cacheKey), cached.validUntil > .now {
            logger.info("Used cached response for \(request.path)")
            return cached.response
        }
        
        guard await hasAttemptsLeft(request) else {
            await markAsUnavailableAndInvalidateRequests()
            throw APIClientError.noAttemptsLeft
        }
        
        if !request.bypassesOffline, await !OfflineMode.shared.isAvailable(connectionID) {
            throw APIClientError.offline
        }
        
        var urlRequest = try await self.request(request)
        
        try? await authorizationRefreshTask?.value
        let token = try? await credentialProvider.accessToken
        
        do {
            try await authorizeRequest(&urlRequest)
            
            let data = try await execute(requestID: request.id, request: urlRequest)
            let response = try request.typecast(data: data)
            
            if let ttl = request.ttl {
                let cached = CachedAPIResponse(validUntil: .now.advanced(by: ttl), response: response)
                cache.setObject(cached, forKey: cacheKey)
            }
            
            await resetAttempts(request.id)
            await OfflineMode.shared.markAsAvailable(connectionID)
            
            logger.info("Received successful response for \(request.path)")
            
            return response
        } catch APIClientError.unauthorized {
            logger.warning("Got 401 while performing request \(request.path)")
            await increaseAttempts(request.id)
            
            try await refreshAccessToken(currentToken: token)
            return try await perform(request)
        } catch APIClientError.notFound {
            logger.warning("Resource not found at \(request.path)")
            throw APIClientError.notFound
        } catch URLError.cancelled {
            logger.warning("Cancelled request to \(request.path)")
            throw APIClientError.cancelled
        } catch {
            logger.warning("Failed to perform request \(request.path): \(error)")
            
            await increaseAttempts(request.id)
            return try await perform(request)
        }
    }
    
    // MARK: Builder
    
    func authorizeRequest(_ request: inout URLRequest) async throws {
        for (key, value) in try await requestHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    // MARK: Execute
    
    func execute(requestID: String, request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                throw APIClientError.unauthorized
            } else if httpResponse.statusCode == 404 {
                throw APIClientError.notFound
            } else if !(200..<299).contains(httpResponse.statusCode) {
                logger.error("Got invalid response code \(httpResponse.statusCode)")
                throw APIClientError.invalidResponseCode
            }
        }
        
        return data
    }
    
    // MARK: Attempts
    
    func hasAttemptsLeft(_ request: any APIRequestProtocol) -> Bool {
        guard let attempts = attempts[request.id] else {
            return true
        }
        
        logger.info("Request \(request.id) \(attempts)/\(request.maxAttempts) attempts used")
        
        return attempts < request.maxAttempts
    }
    func resetAttempts(_ id: String) {
        attempts[id] = nil
    }
    func increaseAttempts(_ id: String) {
        if let attempts = attempts[id] {
            self.attempts[id] = attempts + 1
        } else {
            attempts[id] = 1
        }
    }
    
    // MARK: Token refresh
    
    func refreshAccessToken(currentToken: String?) async throws {
        guard await currentToken == (try? credentialProvider.accessToken) else {
            return
        }
        
        if authorizationRefreshTask == nil {
            logger.info("Spawning new token refresh task")
            
            authorizationRefreshTask = .init {
                do {
                    try await credentialProvider.refreshAccessToken()
                    authorizationRefreshTask = nil
                } catch {
                    await markAsUnavailableAndInvalidateRequests()
                    logger.warning("Access token refresh failed: \(error). Now \(self.connectionID) unreachable")
                 
                    authorizationRefreshTask = nil
                    
                    throw error
                }
            }
        } else {
            logger.info("Reusing existing token refresh ceremony")
        }
        
        return try await authorizationRefreshTask!.value
    }
    
    func markAsUnavailableAndInvalidateRequests() async {
        await OfflineMode.shared.markAsUnavailable(connectionID)
        
        let requests = requestQueue
        requestQueue.removeAll()
        
        for request in requests {
            responseSubject.send((request.id, (nil, APIClientError.cancelled)))
        }
        
        for task in activeRequests.values {
            task.cancel()
        }
    }
}

private struct PipelinedError: Error {
    let requestID: String
    let error: Error
}

private final class CheckedContinuationBox<T: Sendable>: @unchecked Sendable {
    private enum PendingState {
        case value(T)
        case error(any Error)
    }
    
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?
    private var pendingState: PendingState?
    
    func store(_ continuation: CheckedContinuation<T, Error>) {
        lock.lock()
        
        if let pendingState {
            self.pendingState = nil
            lock.unlock()
            
            switch pendingState {
                case .value(let value):
                    continuation.resume(returning: value)
                case .error(let error):
                    continuation.resume(throwing: error)
            }
            
            return
        }
        
        self.continuation = continuation
        lock.unlock()
    }
    
    func resume(returning value: T) {
        lock.lock()
        
        if let continuation {
            self.continuation = nil
            lock.unlock()
            
            continuation.resume(returning: value)
            return
        }
        
        if pendingState == nil {
            pendingState = .value(value)
        }
        
        lock.unlock()
    }
    func resume(throwing error: any Error) {
        lock.lock()
        
        if let continuation {
            self.continuation = nil
            lock.unlock()
            
            continuation.resume(throwing: error)
            return
        }
        
        if pendingState == nil {
            pendingState = .error(error)
        }
        
        lock.unlock()
    }
}
