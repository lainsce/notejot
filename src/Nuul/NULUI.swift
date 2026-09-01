import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Compact Metro switch used by visible settings controls.
///
/// Menu toggles continue to use the platform menu presentation; this style is
/// for an in-content toggle where the track and thumb are visible. Its
/// intrinsic width lets the containing form control its alignment.
struct NULToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        Button(action: { toggle(&configuration.isOn) }) {
            HStack(spacing: 8) {
                configuration.label
                toggleTrack(isOn: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityRemoveTraits(.isButton)
        .accessibilityAddTraits(.isToggle)
    }

    private func toggle(_ isOn: inout Bool) {
        if reduceMotion {
            isOn.toggle()
        } else {
            withAnimation(NotejotMotion.control) { isOn.toggle() }
        }
    }

    private func toggleTrack(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(isOn ? NotejotColors.accent : Color.primary.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(NotejotColors.industrialRule(for: colorScheme), lineWidth: 1)
                }

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(NotejotColors.industrialRule(for: colorScheme), lineWidth: 1)
                }
                .frame(width: 24, height: 24)
                .padding(4)
        }
        .frame(width: 48, height: 32)
        .animation(reduceMotion ? nil : NotejotMotion.control, value: isOn)
    }
}

/// Simple two-column form row using flat, native controls.
struct NULFormRow<Control: View>: View {
    private let title: LocalizedStringKey
    private let control: Control

    init(_ title: LocalizedStringKey, @ViewBuilder control: () -> Control) {
        self.title = title
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .top, spacing: NotejotColors.formRowSpacing) {
            Text(title)
                .font(NotejotTypography.caption)
                .textCase(.uppercase)
                .kerning(0.4)
                .foregroundStyle(.secondary)
                .frame(width: NotejotColors.formLabelWidth, alignment: .leading)
            control
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NULIcon: View {
    let systemImage: String
    let foregroundColor: Color

    init(systemImage: String, foregroundColor: Color = .primary) {
        self.systemImage = systemImage
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(foregroundColor)
            .frame(width: NotejotLayoutMetrics.toolbarIconSize, height: NotejotLayoutMetrics.toolbarIconSize)
            .accessibilityHidden(true)
            .nulWindowActivityAppearance()
    }
}

/// Flat in-content action treatment backed by the native button behavior.
struct NULButtonStyle: ButtonStyle {
    enum Kind { case primary, neutral, quiet }

    private let kind: Kind
    private let accentColor: Color
    private let horizontalPadding: CGFloat?
    private let labelColor: Color?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(
        kind: Kind = .primary,
        accentColor: Color = NotejotColors.accent,
        horizontalPadding: CGFloat? = nil,
        labelColor: Color? = nil
    ) {
        self.kind = kind
        self.accentColor = accentColor
        self.horizontalPadding = horizontalPadding
        self.labelColor = labelColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NotejotTypography.contentBlockSubtitle)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(resolvedForegroundColor())
            .padding(.horizontal, resolvedHorizontalPadding())
            .frame(minWidth: NotejotLayoutMetrics.compactToolbarControlSize, minHeight: NotejotLayoutMetrics.compactToolbarControlSize)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: NotejotColors.controlRadius)
            )
            .overlay {
                if configuration.isPressed && kind != .quiet {
                    RoundedRectangle(cornerRadius: NotejotColors.controlRadius)
                        .fill(Color.primary.opacity(0.10))
                }
            }
            .contentShape(Rectangle())
            .opacity(controlOpacity(isPressed: configuration.isPressed))
            .scaleEffect(controlScale(isPressed: configuration.isPressed))
            .animation(reduceMotion ? nil : NotejotMotion.control, value: configuration.isPressed)
            .nulWindowActivityAppearance()
    }

    private func resolvedForegroundColor() -> Color {
        labelColor ?? (kind == .primary ? .black : .primary)
    }

    private func resolvedHorizontalPadding() -> CGFloat {
        horizontalPadding ?? (kind == .quiet ? NotejotColors.gridUnit : NotejotColors.gridUnit * 2)
    }

    private func controlOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.42 }
        return isPressed ? 0.84 : 1
    }

    private func controlScale(isPressed: Bool) -> CGFloat {
        isPressed && !reduceMotion ? 0.98 : 1
    }

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            accentColor
        case .neutral, .quiet:
            NotejotColors.itemSurface
        }
    }
}

/// Nuul progress indicator used for loading states.
struct NULSpinner: View {
    var tint: Color = NotejotColors.accent

    var body: some View {
        ProgressView()
            .controlSize(.small)
            .tint(tint)
            .accessibilityLabel("Loading")
    }
}

/// SwiftUI's native segmented picker.
struct NULSegmentedPicker<Selection: Hashable, ItemLabel: View>: View {
    @Binding private var selection: Selection
    private let options: [Selection]
    private let label: (Selection) -> ItemLabel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    init(
        selection: Binding<Selection>,
        options: [Selection],
        label: @escaping (Selection) -> ItemLabel
    ) {
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    withAnimation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion)) {
                        selection = option
                    }
                } label: {
                    label(option)
                        .font(NotejotTypography.body)
                        .foregroundStyle(option == selection ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: NotejotLayoutMetrics.compactToolbarSegmentSize)
                        .padding(.horizontal, NotejotColors.gridUnit * 2)
                        .background {
                            RoundedRectangle(cornerRadius: NotejotColors.gridUnit / 2, style: .continuous)
                                .fill(option == selection ? Color.primary.opacity(0.12) : .clear)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .padding(NotejotColors.gridUnit / 2)
        .background(NotejotColors.itemSurface, in: .rect(cornerRadius: NotejotColors.controlRadius))
        .overlay {
            RoundedRectangle(cornerRadius: NotejotColors.controlRadius, style: .continuous)
                .strokeBorder(NotejotColors.industrialRule(for: colorScheme), lineWidth: 1)
        }
    }
}

/// Nuul plain sidebar row treatment; selection supplies platform chrome.
struct NULSidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isHovered: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, NotejotColors.gridUnit * 2)
            .background(fill(for: configuration.isPressed), in: RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius))
            .overlay {
                RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion), value: isSelected)
            .animation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion), value: isHovered)
    }

    private func fill(for isPressed: Bool) -> Color {
        if isPressed {
            return NotejotColors.accent.opacity(NotejotColors.sidebarPressedFillOpacity)
        } else if isSelected {
            return NotejotColors.accent.opacity(NotejotColors.sidebarSelectedFillOpacity)
        } else if isHovered {
            return Color.primary.opacity(NotejotColors.sidebarHoverFillOpacity)
        }
        return .clear
    }

    private var borderColor: Color {
        isSelected && isHovered
            ? NotejotColors.accent.opacity(NotejotColors.sidebarSelectedBorderOpacity)
            : .clear
    }
}

#if os(macOS)
/// Ordinary window background rather than a custom visual effect.
struct NULSidebarSurface: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NotejotColors.sidebarBackground(for: colorScheme)
            .ignoresSafeArea(.container, edges: .top)
    }
}
#endif

/// Nuul rounded text field style.
struct NULTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(NotejotTypography.body)
            .padding(.horizontal, NotejotColors.fieldHorizontalPadding)
            .frame(minHeight: NotejotColors.fieldHeight)
            .textFieldStyle(.plain)
            .background(
                NotejotColors.surface(for: colorScheme),
                in: RoundedRectangle(
                    cornerRadius: NotejotColors.controlRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: NotejotColors.controlRadius, style: .continuous)
                    .strokeBorder(NotejotColors.industrialRule(for: colorScheme), lineWidth: 2)
            }
    }
}

/// Nuul menu button wrapper used by the destination toolbar.
struct NULMenuButton<Label: View, MenuContent: View>: View {
    private let accessibilityLabel: LocalizedStringKey
    private let label: () -> Label
    private let menuContent: () -> MenuContent

    init(
        accessibilityLabel: LocalizedStringKey,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.label = label
        self.menuContent = menuContent
    }

    var body: some View {
        Menu {
            menuContent()
        } label: {
            label()
                .frame(width: NotejotLayoutMetrics.compactToolbarControlSize,
                       height: NotejotLayoutMetrics.compactToolbarControlSize)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(accessibilityLabel)
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .background {
            RoundedRectangle(cornerRadius: NotejotColors.controlRadius)
                .fill(NotejotColors.surface(for: colorScheme))
        }
        .fixedSize()
        .nulWindowActivityAppearance()
    }

    @Environment(\.colorScheme) private var colorScheme
}

/// Nuul search field used in the sidebar safe-area inset.
struct NULSearchField: View {
    @Binding var text: String
    let prompt: LocalizedStringKey
    let focusLabel: LocalizedStringKey
    @FocusState.Binding var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: NotejotColors.gridUnit * 2) {
            NULIcon(systemImage: "magnifyingglass", foregroundColor: .secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(NotejotTypography.contentBlockSubtitle)
                .focused($isFocused)
                .submitLabel(.search)
                .accessibilityLabel(focusLabel)

            if !text.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle.fill") {
                    text = ""
                    isFocused = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Clear Search")
            }
        }
        .padding(.horizontal, NotejotColors.fieldHorizontalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: NotejotLayoutMetrics.sidebarSearchHeight)
        .background(
            NotejotColors.surface(for: colorScheme),
            in: RoundedRectangle(cornerRadius: NotejotColors.controlRadius)
        )
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: NotejotColors.controlRadius)
                    .strokeBorder(NotejotColors.accent.opacity(0.72), lineWidth: 2)
            }
        }
        .onTapGesture { isFocused = true }
    }
}

/// Nuul toolbar group sizing without a custom material surface.
struct NULToolbarSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .frame(height: NotejotLayoutMetrics.compactToolbarControlSize)
            .background(NotejotColors.surface(for: colorScheme), in: shape)
            .nulWindowActivityAppearance()
    }
}

extension View {
    func nulToolbarSurface<S: InsettableShape>(
        _ shape: S
    ) -> some View {
        modifier(NULToolbarSurface(shape: shape))
    }
}

/// Removes chroma from a window while it is inactive, preserving its layout and controls.
struct NULWindowActivityAppearance: ViewModifier {
    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .saturation(appearsActive ? 1 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.18),
                value: appearsActive
            )
    }
}

extension View {
    func nulWindowActivityAppearance() -> some View {
        modifier(NULWindowActivityAppearance())
    }
}
