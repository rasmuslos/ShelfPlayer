//
//  API+Authorization.swift
//  ShelfPlayerKit
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "API+Authorization")

public extension APIClient {
    func login(username: String, password: String) async throws -> (username: String, accessToken: String, refreshToken: String?) {
        logger.info("User login attempt for connection \(self.connectionID, privacy: .public)")

        do {
            let response = try await response(APIRequest<AuthorizationResponse>(
                path: "login",
                method: .post,
                body: [
                    "username": username,
                    "password": password,
                ],
                headers: ["x-return-tokens": "true"],
                bypassesOffline: true,
                bypassesScheduler: true
            ))

            return try (response.user.username, response.versionSafeAccessToken, response.versionSafeRefreshToken)
        } catch {
            logger.warning("Login failed for connection \(self.connectionID, privacy: .public): \(error, privacy: .public)")
            throw error
        }
    }

    func status() async throws -> (String, [AuthorizationStrategy], Bool) {
        logger.debug("Fetching server status for connection \(self.connectionID, privacy: .public)")

        let response = try await response(APIRequest<StatusResponse>(path: "status", method: .get, maxAttempts: 4, bypassesOffline: true, bypassesScheduler: true))

        let strategies: [AuthorizationStrategy] = response.authMethods.compactMap {
            switch $0 {
            case "local":
                .usernamePassword
            case "openid":
                .openID
            default:
                nil
            }
        }

        return (response.serverVersion, strategies, response.isInit)
    }

    func ping(timeout: TimeInterval = OfflineMode.availabilityTimeout) async -> Bool {
        logger.debug("Pinging connection \(self.connectionID, privacy: .public)")
        return (try? await response(APIRequest<APIClient.EmptyResponse>(path: "ping", method: .get, timeout: timeout, maxAttempts: 2, bypassesOffline: true, bypassesScheduler: true))) != nil
    }

    func me() async throws -> (String, String) {
        logger.debug("Fetching me for connection \(self.connectionID, privacy: .public)")

        let request = APIRequest<MeResponse>(path: "api/me", method: .get, maxAttempts: 4, bypassesOffline: true)

        do {
            let response = try await response(request)
            return (response.id, response.username)
        } catch {
            logger.warning("me() failed for connection \(self.connectionID, privacy: .public): \(error, privacy: .public)")
            throw error
        }
    }

    func authorize() async throws -> ([ProgressPayload], [BookmarkPayload], UserPermissionsPayload?) {
        logger.info("Authorizing connection \(self.connectionID, privacy: .public)")

        let request = APIRequest<AuthorizationResponse>(path: "api/authorize", method: .post, ttl: 3, bypassesOffline: true, bypassesScheduler: true)

        do {
            let response = try await response(request)
            return (response.user.mediaProgress, response.user.bookmarks, response.user.permissions)
        } catch {
            logger.warning("authorize() failed for connection \(self.connectionID, privacy: .public): \(error, privacy: .public)")
            throw error
        }
    }

    func refresh(refreshToken: String) async throws -> (String, String?) {
        logger.info("Refreshing access token for connection \(self.connectionID, privacy: .public)")

        do {
            let response = try await response(APIRequest<AuthorizationResponse>(
                path: "auth/refresh",
                method: .post,
                headers: ["x-refresh-token": refreshToken],
                maxAttempts: 1,
                bypassesOffline: true,
                bypassesScheduler: true
            ))
            return try (response.versionSafeAccessToken, response.versionSafeRefreshToken)
        } catch {
            logger.warning("Token refresh failed for connection \(self.connectionID, privacy: .public): \(error, privacy: .public)")
            throw error
        }
    }
}

public extension APIClient {
    func openIDLoginURL(verifier: String) async throws -> URL {
        logger.info("OpenID auth flow initiated for connection \(self.connectionID, privacy: .public)")

        clearCookies()

        var challenge = Data(verifier.compactMap { $0.asciiValue }).sha256.base64EncodedString()

        challenge = challenge.replacingOccurrences(of: "+", with: "-")
        challenge = challenge.replacingOccurrences(of: "/", with: "_")
        challenge = challenge.replacingOccurrences(of: "=", with: "")

        let request = try await request(APIRequest<APIClient.EmptyResponse>(
            path: "auth/openid",
            method: .get,
            query: [
                URLQueryItem(name: "client_id", value: "ShelfPlayer"),
                URLQueryItem(name: "redirect_uri", value: "shelfplayer://callback"),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "code_challenge", value: "\(challenge)"),
            ]
        ))
        let (_, response) = try await session.data(for: request)

        if let location = (response as? HTTPURLResponse)?.allHeaderFields["Location"] as? String, let url = URL(string: location) {
            return url
        }

        logger.warning("Missing Location header in OpenID redirect for connection \(self.connectionID, privacy: .public)")
        throw APIClientError.notFound
    }

    func openIDExchange(code: String, state: String, verifier: String) async throws -> (username: String, accessToken: String, refreshToken: String?) {
        logger.info("OpenID code exchange started for connection \(self.connectionID, privacy: .public)")

        let request = APIRequest<AuthorizationResponse>(
            path: "auth/openid/callback",
            method: .get,
            query: [
                .init(name: "code", value: code),
                .init(name: "state", value: state),
                .init(name: "code_verifier", value: verifier),
            ],
            bypassesOffline: true,
            bypassesScheduler: true
        )

        do {
            let response = try await response(request)
            return try (response.user.username, response.versionSafeAccessToken, response.versionSafeRefreshToken)
        } catch {
            logger.warning("OpenID exchange failed for connection \(self.connectionID, privacy: .public): \(error, privacy: .public)")
            throw error
        }
    }
}
