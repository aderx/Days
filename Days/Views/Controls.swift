import AppKit
import SwiftUI

struct ControlButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(title)
                    .font(.ndMono(11, weight: .medium))
            }
            .foregroundStyle(ND.textPrimary(colorScheme))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Capsule())
            .overlay {
                if !isGlassSkin {
                    Capsule()
                        .stroke(ND.borderVisible(colorScheme), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }
}

struct IconControlButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ND.textPrimary(colorScheme))
                .frame(width: 34, height: 34)
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Circle())
                .overlay {
                    if !isGlassSkin {
                        Circle()
                            .stroke(ND.borderVisible(colorScheme), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }
}

struct GhostIconButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ND.textSecondary(colorScheme))
                .frame(width: 30, height: 30)
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }
}

struct SoftIconButton: View {
    enum Prominence {
        case primary
        case secondary
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let systemImage: String
    let prominence: Prominence
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Circle())
                .opacity(isHovering ? 1 : 0.86)
                .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }

    private var foreground: Color {
        switch prominence {
        case .primary:
            return ND.textDisplay(colorScheme)
        case .secondary:
            return ND.textPrimary(colorScheme)
        }
    }

}

private struct PointingHandHoverModifier: ViewModifier {
    @Binding var isHovering: Bool

    func body(content: Content) -> some View {
        content.onHover { isInside in
            isHovering = isInside
            if isInside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func pointingHandOnHover(_ isHovering: Binding<Bool>) -> some View {
        modifier(PointingHandHoverModifier(isHovering: isHovering))
    }
}

// MARK: - Liquid Glass skin propagation

private struct GlassSkinKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when the panel skin is the macOS 26 Liquid Glass treatment.
    var isGlassSkin: Bool {
        get { self[GlassSkinKey.self] }
        set { self[GlassSkinKey.self] = newValue }
    }
}

/// Backs a small control with a Liquid Glass capsule/circle when the glass skin
/// is active, otherwise falls back to the flat hover wash.
struct GlassControlBackground<S: Shape>: ViewModifier {
    let isGlass: Bool
    let isHovering: Bool
    let shape: S

    func body(content: Content) -> some View {
        if isGlass, #available(macOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content
                .background(isHovering ? ND.hoverWash : Color.clear)
                .clipShape(shape)
        }
    }
}

extension View {
    func glassControlBackground(isGlass: Bool, isHovering: Bool, shape: some Shape) -> some View {
        modifier(GlassControlBackground(isGlass: isGlass, isHovering: isHovering, shape: shape))
    }
}

struct StepTextButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ndMono(13, weight: .medium))
                .foregroundStyle(ND.textSecondary(colorScheme))
                .frame(width: 30, height: 28)
                .glassControlBackground(
                    isGlass: isGlassSkin,
                    isHovering: isHovering,
                    shape: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .overlay {
                    if !isGlassSkin {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(ND.border(colorScheme), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }
}

struct ToggleRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.ndMono(11, weight: .medium))
                        .foregroundStyle(ND.textSecondary(colorScheme))
                    Text(detail)
                        .font(.ndBody(14))
                        .foregroundStyle(ND.textPrimary(colorScheme))
                }

                Spacer()

                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? ND.textDisplay(colorScheme) : ND.borderVisible(colorScheme))
                    Circle()
                        .fill(isOn ? ND.black(colorScheme) : ND.textDisabled(colorScheme))
                        .padding(4)
                }
                .frame(width: 52, height: 30)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SectionLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.ndMono(11, weight: .medium))
            .foregroundStyle(ND.textSecondary(colorScheme))
    }
}
