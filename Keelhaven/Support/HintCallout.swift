import SwiftUI

/// Inline callout for the wizard's warning and error messages: a tinted
/// rounded box with a semantic icon, so severity reads from the icon and
/// background while the text keeps the normal foreground color (issue #50).
///
/// Gray guidance text ("nothing is wrong yet", issue #38) stays plain
/// `.secondary` and deliberately does not use this view — a box would
/// promote guidance to the same visual weight as a problem.
struct HintCallout: View {
    enum Style {
        case warning
        case error

        var symbol: String {
            switch self {
            case .warning: "exclamationmark.triangle.fill"
            case .error: "exclamationmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .warning: .orange
            case .error: .red
            }
        }
    }

    let style: Style
    let text: Text
    var lineLimit: Int?

    init(_ style: Style, _ key: LocalizedStringKey) {
        self.style = style
        self.text = Text(key)
    }

    /// For messages that arrive as runtime strings (e.g. restic error output).
    init(_ style: Style, verbatim: String, lineLimit: Int? = nil) {
        self.style = style
        self.text = Text(verbatim)
        self.lineLimit = lineLimit
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: style.symbol)
                .foregroundStyle(style.color)
                .accessibilityHidden(true)
            text
                .font(.callout)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(style.color.opacity(0.12)))
        .accessibilityElement(children: .combine)
    }
}
