import SwiftUI

/// Center-screen, non-blocking popup card for `PopupEvent`s (double/triple/bull
/// hits, checkouts, busts, "Turn Done — Next: ..."). Auto-dismisses on its own
/// and never intercepts touches, so the player can keep tapping immediately.
struct PopupCard: View {
    let event: PopupEvent

    @State private var bounce = false

    /// Checkouts and game-overs get the signature gradient treatment;
    /// everything else keeps its semantic color for clarity.
    private var isCelebration: Bool { event.kind == .checkout }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: event.icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(isCelebration ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(event.color))
            Text(event.title.uppercased())
                .font(OcheFont.heading(24))
                .foregroundStyle(isCelebration ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.textPrimary))
            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(OcheFont.body(14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Corner.xxl))
        .overlay(
            Group {
                if isCelebration {
                    RoundedRectangle(cornerRadius: Corner.xxl)
                        .strokeBorder(Theme.accentGradient, lineWidth: 2)
                } else {
                    RoundedRectangle(cornerRadius: Corner.xxl)
                        .strokeBorder(event.color.opacity(0.45), lineWidth: 1.5)
                }
            }
        )
        .shadow(color: event.color.opacity(0.3), radius: 20)
        .scaleEffect(bounce ? 1.0 : 0.7)
        .onAppear {
            if isCelebration {
                withAnimation(Motion.bounce) {
                    bounce = true
                }
            } else {
                bounce = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title)\(event.subtitle.map { ", " + $0 } ?? "")")
    }
}

/// How long a popup stays on screen before auto-dismissing.
private let popupDismissDelay: TimeInterval = 1.4

extension View {
    /// Overlays a center-screen, auto-dismissing popup driven by `event`.
    /// Respects `SettingsStore.popupsEnabled` — when disabled, the binding is
    /// still cleared on schedule so callers don't need to branch.
    func popupOverlay(_ event: Binding<PopupEvent?>, settings: SettingsStore) -> some View {
        overlay(
            Group {
                if let value = event.wrappedValue {
                    // The dismiss timer always runs while `event` is non-nil,
                    // regardless of `popupsEnabled` — only the card's visibility
                    // is gated by the setting. Otherwise, disabling popups mid-game
                    // would leave a stale event in the binding forever, ready to
                    // flash back up the moment popups are re-enabled.
                    Group {
                        if settings.popupsEnabled {
                            PopupCard(event: value)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }
                    }
                    .id(value.id)
                    // `.task(id:)` cancels and restarts automatically whenever
                    // `value.id` changes (a new popup arrived before the old one
                    // dismissed) or the view disappears — unlike a bare
                    // `DispatchQueue.asyncAfter`, there's no way for a stale
                    // timer to fire late or for a new popup's timer to never
                    // get scheduled, which is what made popups occasionally
                    // stick on screen under fast back-to-back throws.
                    .task(id: value.id) {
                        try? await Task.sleep(for: .seconds(popupDismissDelay))
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            event.wrappedValue = nil
                        }
                    }
                }
            }
            .animation(Motion.settle, value: event.wrappedValue?.id)
            .allowsHitTesting(false)
        )
    }
}

/// Full-screen color flash for big hits (180s, checkouts), gated by
/// `SettingsStore.flashEnabled`. Purely decorative, never blocks input.
extension View {
    func screenFlash(_ color: Binding<Color?>, settings: SettingsStore) -> some View {
        overlay(
            Group {
                if settings.flashEnabled, let flashColor = color.wrappedValue {
                    flashColor
                        .opacity(0.18)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.35)) {
                                color.wrappedValue = nil
                            }
                        }
                }
            }
            .allowsHitTesting(false)
        )
    }
}
