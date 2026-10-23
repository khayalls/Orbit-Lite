import RealityKit
import SwiftUI

struct OrbitView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    let orbit: OrbitScene
    let dock: PalmDockState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @GestureState private var isDragging = false
    @GestureState private var isMagnifying = false
    @GestureState private var isRotating = false

    var body: some View {
        RealityView { content in
            content.add(orbit.root)
        }
        // A drag wins over a hold; a hold wins over taps. A double pinch wins
        // over a single pinch, so one interaction never triggers two commands.
        .gesture(drag.exclusively(before: hold.exclusively(before: doubleTap.exclusively(before: tap))))
        .simultaneousGesture(magnify)
        .simultaneousGesture(rotate)
        .ornament(visibility: .visible, attachmentAnchor: .scene(.bottomFront), contentAlignment: .bottom) {
            VStack(spacing: 10) {
                if dock.isPresented {
                    HStack(spacing: 14) {
                        Image(systemName: "hand.raised.fingers.spread.fill").foregroundStyle(.cyan)
                        Text(PalmDockState.isSimulator ? "Palm dock preview" : "Left palm dock")
                            .font(.subheadline.weight(.medium))
                        Button("Float toolbar") { leavePalm() }.buttonStyle(.bordered)
                            .disabled(dock.isBusy)
                    }
                    .padding(14)
                    .glassBackgroundEffect(in: Capsule())
                } else {
                    OrbitToolbar(orbit: orbit, reduceMotion: reduceMotion, placement: .floating,
                                 startsExpanded: true, relocate: enterPalm)
                        .disabled(dock.isBusy)
                }
                if let message = dock.message {
                    Text(message).font(.caption).padding(12).glassBackgroundEffect()
                }
            }
            .padding(.top, 12)
        }
        .onChange(of: isDragging) { _, active in if !active { orbit.endDrag() } }
        .onChange(of: isMagnifying) { _, active in if !active { orbit.endMagnify() } }
        .onChange(of: isRotating) { _, active in if !active { orbit.endRotate() } }
        .onAppear { syncMotionPolicy() }
        .onChange(of: scenePhase) { _, _ in syncMotionPolicy() }
        .onChange(of: reduceMotion) { _, _ in syncMotionPolicy() }
        .onDisappear {
            orbit.setMotionPolicy(isActive: false, reduceMotion: reduceMotion)
            orbit.stopAnimations()
        }
    }

    private var tap: some Gesture {
        SpatialTapGesture()
            .targetedToEntity(orbit.subject)
            .onEnded { _ in orbit.nextColor(reduceMotion: reduceMotion) }
    }

    private var doubleTap: some Gesture {
        SpatialTapGesture(count: 2)
            .targetedToEntity(orbit.subject)
            .onEnded { _ in orbit.nextForm(reduceMotion: reduceMotion) }
    }

    private var hold: some Gesture {
        LongPressGesture(minimumDuration: 0.65, maximumDistance: 12)
            .targetedToEntity(orbit.subject)
            .onEnded { _ in orbit.toggleOrbit(reduceMotion: reduceMotion) }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6)
            .targetedToEntity(orbit.subject)
            .updating($isDragging) { _, active, _ in active = true }
            .onChanged { value in
                orbit.drag(by: value.convert(value.translation3D, from: .local, to: .scene))
            }
            .onEnded { _ in orbit.endDrag() }
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .targetedToEntity(orbit.subject)
            .updating($isMagnifying) { _, active, _ in active = true }
            .onChanged { value in orbit.magnify(by: value.magnification) }
            .onEnded { _ in orbit.endMagnify() }
    }

    private var rotate: some Gesture {
        RotateGesture3D()
            .targetedToEntity(orbit.subject)
            .updating($isRotating) { _, active, _ in active = true }
            .onChanged { value in
                orbit.rotate(by: value.convert(value.rotation, from: .local, to: .scene))
            }
            .onEnded { _ in orbit.endRotate() }
    }

    private func enterPalm() {
        guard dock.beginOpening() else { return }
        Task {
            switch await openImmersiveSpace(id: PalmDockState.spaceID) {
            case .opened: dock.didOpen()
            case .userCancelled: dock.openingFailed()
            case .error: dock.openingFailed("The palm dock couldn't open. Try again from the floating toolbar.")
            @unknown default: dock.openingFailed("Please try opening the palm dock again.")
            }
        }
    }

    private func leavePalm() {
        guard dock.beginClosing() else { return }
        Task { await dismissImmersiveSpace(); dock.didClose() }
    }

    private func syncMotionPolicy() {
        orbit.setMotionPolicy(isActive: scenePhase != .background, reduceMotion: reduceMotion)
    }
}
