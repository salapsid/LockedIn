//
//  Theme.swift
//  LockedIn
//
//  Centralized colors, gradients, and typography helpers for a cohesive look.
//

import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Core Palette
    // Deep, modern dark with blue→violet emphasis
    static let backgroundTop = Color(red: 0.06, green: 0.09, blue: 0.20)       // navy #0F1733
    static let backgroundMid = Color(red: 0.16, green: 0.23, blue: 0.52)       // blue #293C85
    static let backgroundBottom = Color(red: 0.22, green: 0.11, blue: 0.44)    // violet #381C70
    static let surface = Color(red: 0.12, green: 0.14, blue: 0.26)             // dark indigo
    static let surfaceElevated = Color(red: 0.16, green: 0.18, blue: 0.32)     // elevated indigo

    static let accentPrimary = Color(red: 0.41, green: 0.67, blue: 1.00)       // richer blue
    static let accentSecondary = Color(red: 0.62, green: 0.48, blue: 1.00)     // vibrant violet

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.78)
    static let textMuted = Color.white.opacity(0.62)

    static let warning = Color.orange
    static let danger = Color(red: 1.0, green: 0.33, blue: 0.36)

    // MARK: - Gradients & Styles
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: backgroundTop, location: 0.0),
            .init(color: backgroundMid, location: 0.55),
            .init(color: backgroundBottom, location: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let controlFill = LinearGradient(
        gradient: Gradient(colors: [accentPrimary, accentSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleShadow = Color.black.opacity(0.30)

    // MARK: - UIKit bridge (for UINavigationBarAppearance)
    static let navBarBackgroundUIColor = UIColor(red: 0.06, green: 0.09, blue: 0.20, alpha: 1.0)
    static let navBarTitleUIColor = UIColor(white: 1.0, alpha: 0.95)
    static let tintUIColor = UIColor(red: 0.62, green: 0.48, blue: 1.00, alpha: 1.0)

    // MARK: - Typography
    static let navBarTitleFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .semibold)
    static let navBarLargeTitleFont: UIFont = .monospacedSystemFont(ofSize: 34, weight: .bold)
}


