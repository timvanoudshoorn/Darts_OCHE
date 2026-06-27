import SwiftUI

/// Named corner-radius tiers — replaces the ad-hoc 10/13/14/16/18 literals
/// scattered (and sometimes mixed within a single view) across the app.
/// Tiered by what the element *is*, not by preserving each call site's
/// current accidental value.
enum Corner {
    /// Small chips / pad buttons.
    static let sm: CGFloat = 10
    /// List rows, setup rows, toggles.
    static let md: CGFloat = 14
    /// Score/stat cards.
    static let lg: CGFloat = 16
    /// Primary CTA buttons.
    static let xl: CGFloat = 18
    /// Large hero containers.
    static let xxl: CGFloat = 24
}

/// Named spring presets consolidating the ~5 animation "families" already in
/// use across the app (previously hand-typed per call site with slightly
/// different numbers each time).
enum Motion {
    /// Button press feedback (`SquashButtonStyle`).
    static let tap = Animation.spring(response: 0.22, dampingFraction: 0.45)
    /// Selector/segmented switches (e.g. `MultiplierSelector`).
    static let snap = Animation.spring(response: 0.25, dampingFraction: 0.7)
    /// Celebratory bounces (popups, game-over reveals).
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.5)
    /// Content fade/slide-in reveals (menus, lists appearing).
    static let reveal = Animation.spring(response: 0.5, dampingFraction: 0.85)
    /// Position/settle transitions (popup placement, card movement).
    static let settle = Animation.spring(response: 0.35, dampingFraction: 0.65)
    /// Quick punchy impact (score slam, bust shake) — snappier and bouncier
    /// than `settle`, for the instant something registers on screen.
    static let impact = Animation.spring(response: 0.25, dampingFraction: 0.4)
}
