import Observation
import RealityKit
import SwiftUI

/// Only lifecycle state is shared. RealityKit owns the private hand pose; Orbit
/// never reads, stores, or recognizes the person's hand skeleton.
@MainActor
@Observable
final class PalmDockState {
    enum Phase { case closed, opening, open, closing }
    private(set) var phase: Phase = .closed
    private(set) var message: String?
    var isPresented: Bool { phase == .open || phase == .closing }
    var isBusy: Bool { phase == .opening || phase == .closing }

    static let spaceID = "left-palm-dock"
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    func beginOpening() -> Bool {
        guard phase == .closed else { return false }
        message = nil
        phase = .opening
        return true
    }
    func didOpen() { if phase == .opening { phase = .open } }
    func openingFailed(_ message: String? = nil) { phase = .closed; self.message = message }
    func beginClosing() -> Bool {
        guard phase == .open else { return false }
        phase = .closing
        return true
    }
    func didClose() { phase = .closed }
}

/// The bottom edge stays at the same position as the dock expands upward.
/// Apple's above-hand orientation keeps labels upright as the wrist turns.
@MainActor
final class PalmDockRig {
    static let canvasHeight: Float = 560
    static let scale: Float = 0.72
    let anchor: Entity
    let surface = Entity()

    init(preview: Bool) {
        if preview {
            // Explicitly a simulator layout preview, never a synthetic hand test.
            anchor = Entity()
            anchor.position = [-0.25, 1.32, -0.65]
        } else {
            anchor = AnchorEntity(.hand(.left, location: .aboveHand),
                                  trackingMode: .continuous, physicsSimulation: .none)
            // aboveHand's +Y faces the head and +Z faces the ground. Rotate
            // the view's +Z normal toward +Y, with text rising away from ground.
            surface.position = [0, 0.025, -0.045]
            surface.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        }
        anchor.name = preview ? "PalmDockSimulatorPreview" : "LeftPalmDockAnchor"
        anchor.addChild(surface)
    }

    func attach(_ entity: Entity) {
        entity.name = "PalmDockSurface"
        entity.scale = SIMD3(repeating: Self.scale)
        entity.position = [0, Self.canvasHeight * Self.scale / 2000, 0]
        surface.addChild(entity)
    }
}

struct PalmDockSpace: View {
    let orbit: OrbitScene
    let dock: PalmDockState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var rig = PalmDockRig(preview: PalmDockState.isSimulator)

    var body: some View {
        RealityView { content, attachments in
            if let view = attachments.entity(for: "palm-controls") { rig.attach(view) }
            content.add(rig.anchor)
        } update: { _, attachments in
            if let view = attachments.entity(for: "palm-controls"), view.parent !== rig.surface {
                rig.attach(view)
            }
        } attachments: {
            Attachment(id: "palm-controls") {
                OrbitToolbar(orbit: orbit, reduceMotion: reduceMotion,
                             placement: PalmDockState.isSimulator ? .preview : .palm,
                             startsExpanded: false, relocate: leavePalm)
                    .frame(width: 360, height: CGFloat(PalmDockRig.canvasHeight), alignment: .bottom)
            }
        }
        .onAppear { dock.didOpen() }
        .onDisappear { dock.didClose() }
    }

    private func leavePalm() {
        guard dock.beginClosing() else { return }
        Task { await dismissImmersiveSpace(); dock.didClose() }
    }
}
