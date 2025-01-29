//
//  PlayButtonStyle.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayerKit

protocol PlayButtonStyle {
    associatedtype MenuBody: View
    associatedtype LabelBody: View
    
    typealias Configuration = PlayButtonConfiguration
    
    func makeMenu(configuration: Self.Configuration) -> Self.MenuBody
    func makeLabel(configuration: Self.Configuration) -> Self.LabelBody
    
    var cornerRadius: CGFloat { get }
    var hideRemainingWhenUnplayed: Bool { get }
}
extension PlayButtonStyle where Self == LargePlayButtonStyle {
    static var large: LargePlayButtonStyle { .init() }
}
extension PlayButtonStyle where Self == MediumPlayButtonStyle {
    static var medium: MediumPlayButtonStyle { .init() }
}

struct AnyLargePlayButtonStyle: PlayButtonStyle {
    private var _makeMenu: (Configuration) -> AnyView
    private var _makeLabel: (Configuration) -> AnyView
    
    private var _cornerRadius: CGFloat
    private var _hideRemainingWhenUnplayed: Bool
    
    init<S: PlayButtonStyle>(style: S) {
        _makeMenu = { configuration in
            AnyView(style.makeMenu(configuration: configuration))
        }
        _makeLabel = { configuration in
            AnyView(style.makeLabel(configuration: configuration))
        }
        
        _cornerRadius = style.cornerRadius
        _hideRemainingWhenUnplayed = style.hideRemainingWhenUnplayed
    }
    
    func makeMenu(configuration: Configuration) -> some View {
        _makeMenu(configuration)
    }
    func makeLabel(configuration: Configuration) -> some View {
        _makeLabel(configuration)
    }
    
    var cornerRadius: CGFloat {
        _cornerRadius
    }
    var hideRemainingWhenUnplayed: Bool {
        _hideRemainingWhenUnplayed
    }
}

extension EnvironmentValues {
    @Entry var playButtonStyle: AnyLargePlayButtonStyle = .init(style: LargePlayButtonStyle())
}

struct PlayButtonConfiguration {
    let progress: Percentage?
    let background: Color
    
    struct Content: View {
        init<Content: View>(content: Content) {
            body = AnyView(content)
        }
        
        var body: AnyView
    }
    
    let content: PlayButtonConfiguration.Content
}
