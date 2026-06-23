import SwiftUI

/// Displays one or more checkout suggestions for the current remaining score.
/// The first is labeled "CHECKOUT:"; any further same-dart-count alternatives
/// (see `CheckoutTable.suggestions`) are listed below as dimmer "or" rows.
struct CheckoutSuggestionList: View {
    let suggestions: [CheckoutTable.Suggestion]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(suggestions.indices, id: \.self) { i in
                HStack(spacing: 6) {
                    Text(i == 0 ? "CHECKOUT:" : "OR:")
                        .font(OcheFont.label(12))
                        .foregroundStyle(Theme.textTertiary)
                    Text(suggestions[i].labels.joined(separator: "  ·  "))
                        .font(i == 0 ? OcheFont.bodyBold(15) : OcheFont.bodyBold(13))
                        .foregroundStyle(i == 0 ? color : color.opacity(0.7))
                }
            }
        }
    }
}
