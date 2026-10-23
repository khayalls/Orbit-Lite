import SwiftUI

struct OrbitToolbar: View {
    enum Placement { case floating, palm, preview }
    let orbit: OrbitScene
    let reduceMotion: Bool
    let placement: Placement
    let relocate: () -> Void
    @State private var isExpanded: Bool
    @State private var panel: Panel?
    private enum Panel { case style, gestures }

    init(orbit: OrbitScene, reduceMotion: Bool, placement: Placement,
         startsExpanded: Bool, relocate: @escaping () -> Void) {
        self.orbit = orbit
        self.reduceMotion = reduceMotion
        self.placement = placement
        self.relocate = relocate
        _isExpanded = State(initialValue: startsExpanded)
    }

    private var accent: Color { OrbitColor.palette[orbit.colorIndex].color }
    private var animation: Animation? { reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.88) }
    private var location: String {
        switch placement {
        case .floating: "ORBIT LITE"
        case .palm: "LEFT PALM"
        case .preview: "PALM PREVIEW"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            if isExpanded {
                if panel == .style { stylePanel.transition(.opacity.combined(with: .move(edge: .bottom))) }
                if panel == .gestures { gesturePanel.transition(.opacity.combined(with: .move(edge: .bottom))) }
                expandedDock.transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .bottom)))
            } else {
                collapsedDock.transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
            if let error = orbit.errorMessage {
                Text(error).font(.caption).padding(12).glassBackgroundEffect()
            }
        }
        .frame(width: 360, alignment: .bottom)
    }

    private var collapsedDock: some View {
        Button {
            withAnimation(animation) { isExpanded = true }
        } label: {
            HStack(spacing: 13) {
                orbMark.frame(width: 22, height: 22)
                Capsule().fill(.white.opacity(0.5)).frame(width: 24, height: 3)
                Image(systemName: "chevron.up").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
            }
            .frame(width: 116, height: 48)
            .contentShape(Capsule())
            .glassBackgroundEffect(in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel("Expand toolbar")
        .accessibilityHint(placement == .floating ? "Opens the Orbit controls." : "Opens the Orbit controls above your left palm.")
    }

    private var expandedDock: some View {
        VStack(spacing: 13) {
            HStack(spacing: 10) {
                orbMark.frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 3) {
                    Text(location).font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(1.8).foregroundStyle(.secondary)
                    Text(orbit.status).font(.system(size: 13, weight: .medium))
                }
                Spacer()
                Button {
                    withAnimation(animation) { panel = nil; isExpanded = false }
                } label: {
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold))
                        .frame(width: 44, height: 44).contentShape(Circle())
                }
                .buttonStyle(.plain).hoverEffect(.highlight)
                .accessibilityLabel("Collapse toolbar")
            }
            HStack(spacing: 9) {
                tool("Style", symbol: "slider.horizontal.3", selected: panel == .style) { toggle(.style) }
                tool(orbit.isPlaying ? "Pause" : "Orbit", symbol: orbit.isPlaying ? "pause.fill" : "play.fill", selected: orbit.isPlaying) {
                    orbit.toggleOrbit(reduceMotion: reduceMotion)
                }
                .disabled(reduceMotion || orbit.errorMessage != nil)
                tool("Gestures", symbol: "hand.draw", selected: panel == .gestures) { toggle(.gestures) }
                tool("Reset", symbol: "arrow.counterclockwise", selected: false) { orbit.reset(reduceMotion: reduceMotion) }
            }
            Rectangle().fill(.white.opacity(0.10)).frame(height: 0.5)
            Button(action: relocate) {
                HStack(spacing: 8) {
                    Image(systemName: placement == .floating ? "hand.raised" : "rectangle.on.rectangle")
                    Text(placement == .floating
                         ? (PalmDockState.isSimulator ? "Preview palm dock" : "Attach to left palm")
                         : "Float toolbar")
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(minHeight: 32)
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain).hoverEffect(.highlight)
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
    }

    private var orbMark: some View {
        Circle()
            .fill(RadialGradient(colors: [.white.opacity(0.95), accent.opacity(0.95), accent.opacity(0.35)],
                                 center: .topLeading, startRadius: 0, endRadius: 26))
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
            .shadow(color: accent.opacity(0.20), radius: 8)
            .accessibilityHidden(true)
    }

    private var stylePanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            panelHeader("Make it yours", subtitle: "\(orbit.form.rawValue) · \(orbit.finish.rawValue) · \(orbit.colorName)")
            Picker("Form", selection: Binding(get: { orbit.form }, set: { orbit.setForm($0, reduceMotion: reduceMotion) })) {
                ForEach(OrbitForm.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(orbit.errorMessage != nil)
            HStack(spacing: 8) {
                ForEach(OrbitColor.palette) { color in
                    Button { orbit.selectColor(color.id, reduceMotion: reduceMotion) } label: {
                        Circle().fill(color.color).frame(width: 26, height: 26)
                            .overlay {
                                if orbit.colorIndex == color.id {
                                    Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5).padding(-4)
                                }
                            }
                            .frame(width: 44, height: 44).contentShape(Circle())
                    }
                    .buttonStyle(.plain).hoverEffect(.highlight)
                    .accessibilityLabel(color.name)
                    .accessibilityAddTraits(orbit.colorIndex == color.id ? .isSelected : [])
                }
            }
            .frame(maxWidth: .infinity)
            Picker("Finish", selection: Binding(get: { orbit.finish }, set: { orbit.setFinish($0, reduceMotion: reduceMotion) })) {
                ForEach(OrbitFinish.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.left.and.arrow.down.right").font(.caption).foregroundStyle(.secondary)
                Slider(value: Binding(get: { Double(orbit.size) }, set: { orbit.setSize(Float($0)) }),
                       in: Double(OrbitScene.sizeRange.lowerBound)...Double(OrbitScene.sizeRange.upperBound))
                    .accessibilityLabel("Sculpture size")
                    .accessibilityValue("\(Int(orbit.size * 100)) percent")
                Text("\(Int(orbit.size * 100))%")
                    .font(.caption.monospacedDigit()).frame(width: 37, alignment: .trailing)
            }
        }
        .padding(18)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
    }

    private var gesturePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            panelHeader("A little hand magic", subtitle: "Look at the sphere to begin.")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 17) {
                gesture("Pinch", detail: "Next color", symbol: "hand.tap")
                gesture("Double pinch", detail: "Next form", symbol: "hand.tap.fill")
                gesture("Pinch + hold", detail: "Play or pause", symbol: "hand.point.up.left.fill")
                gesture("Pinch + drag", detail: "Move in space", symbol: "arrow.up.and.down.and.arrow.left.and.right")
                gesture("Two-hand stretch", detail: "Resize", symbol: "arrow.up.left.and.arrow.down.right")
                gesture("Two-hand twist", detail: "Turn the rings", symbol: "rotate.3d")
            }
            if placement != .floating {
                Text(placement == .preview
                     ? "Simulator layout preview. Hand following needs Vision Pro."
                     : "Hold your left hand comfortably. Look at the dock and pinch with your right hand.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if reduceMotion {
                Text("Reduce Motion is on. Orbital animation and pulses are paused.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
    }

    private func panelHeader(_ title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 17, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("Done") { withAnimation(animation) { panel = nil } }
                .font(.caption).buttonStyle(.bordered)
        }
    }

    private func tool(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 19, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
                Text(title).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.78))
            .frame(width: 74, height: 59)
            .background(selected ? .white.opacity(0.14) : .white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain).hoverEffect(.highlight)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func gesture(_ title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol).font(.system(size: 16)).frame(width: 22).foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 11, weight: .semibold))
                Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggle(_ selected: Panel) {
        withAnimation(animation) { panel = panel == selected ? nil : selected }
    }
}
