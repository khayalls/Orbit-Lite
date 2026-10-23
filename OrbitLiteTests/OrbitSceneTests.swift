import RealityKit
import Testing
import UIKit
@testable import OrbitLite

@Suite(.serialized)
@MainActor
struct OrbitSceneTests {
    @Test func initialSceneAndOrbitalResourcesLoad() {
        let scene = OrbitScene()
        #expect(scene.errorMessage == nil)
        #expect(scene.colorName == "Azure")
        #expect(scene.form == .saturn)
        #expect(scene.finish == .pearl)
        #expect(scene.subject.position == OrbitScene.home)
        #expect(scene.subject.scale == .one)
        #expect(scene.subject.components[InputTargetComponent.self] != nil)
        #expect(scene.sphere.components[CollisionComponent.self] != nil)
        #expect(scene.sphere.components[HoverEffectComponent.self] != nil)
        #expect(scene.orbits.children.count == 1)
    }

    @Test func paletteCyclesAndWraps() {
        let scene = OrbitScene()
        for name in ["Iris", "Rose", "Amber", "Jade", "Ice", "Azure"] {
            scene.nextColor(reduceMotion: true)
            #expect(scene.colorName == name)
        }
        scene.selectColor(-1, reduceMotion: true)
        #expect(scene.colorName == "Azure")
    }

    @Test func doublePinchCommandCyclesForms() {
        let scene = OrbitScene()
        for form: OrbitForm in [.atom, .orb, .saturn] {
            scene.nextForm(reduceMotion: true)
            #expect(scene.form == form)
            #expect(scene.orbits.children.count == (form == .atom ? 3 : 1))
        }
    }

    @Test func finishesChangeMaterialWithoutLosingColor() throws {
        let scene = OrbitScene()
        scene.selectColor(2, reduceMotion: true)
        scene.setFinish(.glow, reduceMotion: true)
        var material = try #require(scene.sphere.model?.materials.first as? PhysicallyBasedMaterial)
        #expect(material.emissiveIntensity == 0.75)
        scene.setFinish(.chrome, reduceMotion: true)
        material = try #require(scene.sphere.model?.materials.first as? PhysicallyBasedMaterial)
        #expect(material.emissiveIntensity == 0)
        #expect(scene.colorName == "Rose")
    }

    @Test func dragUsesItsStartingPositionAndSuppressesTapCommands() {
        let scene = OrbitScene()
        scene.drag(by: [0.1, 0.02, -0.03])
        scene.drag(by: [0.15, 0.03, -0.05])
        #expect(abs(scene.subject.position.x - 0.15) < 0.0001)
        #expect(abs(scene.subject.position.y - 0.07) < 0.0001)
        #expect(abs(scene.subject.position.z + 0.05) < 0.0001)
        scene.nextColor(reduceMotion: true)
        scene.nextForm(reduceMotion: true)
        scene.toggleOrbit(reduceMotion: false)
        #expect(scene.colorName == "Azure")
        #expect(scene.form == .saturn)
        #expect(!scene.isPlaying)
        scene.endDrag()
        scene.drag(by: [0.02, 0, 0])
        #expect(abs(scene.subject.position.x - 0.17) < 0.0001)
        scene.endDrag()
    }

    @Test func twoHandStretchIsRelativeAndClamped() {
        let scene = OrbitScene()
        scene.magnify(by: 1.1)
        scene.magnify(by: 1.2)
        #expect(abs(scene.size - 1.2) < 0.0001)
        scene.endMagnify()
        scene.magnify(by: 1.1)
        #expect(abs(scene.size - 1.32) < 0.0001)
        scene.endMagnify()
        scene.setSize(100)
        #expect(scene.size == OrbitScene.sizeRange.upperBound)
        scene.setSize(0.01)
        #expect(scene.size == OrbitScene.sizeRange.lowerBound)
    }

    @Test func twoHandTwistUsesTheGestureOrigin() {
        let scene = OrbitScene()
        scene.rotate(by: simd_quatf(angle: 0.3, axis: [0, 1, 0]))
        scene.rotate(by: simd_quatf(angle: 0.6, axis: [0, 1, 0]))
        var expected = simd_quatf(angle: 0.6, axis: [0, 1, 0])
        #expect(abs(simd_dot(scene.subject.orientation.vector, expected.vector)) > 0.9999)
        scene.endRotate()
        scene.rotate(by: simd_quatf(angle: 0.2, axis: [0, 1, 0]))
        expected = simd_quatf(angle: 0.8, axis: [0, 1, 0])
        #expect(abs(simd_dot(scene.subject.orientation.vector, expected.vector)) > 0.9999)
        scene.endRotate()
    }

    @Test func simultaneousMoveStretchAndTwistPreserveEachOther() {
        let scene = OrbitScene()
        scene.drag(by: [0.08, 0.02, 0])
        scene.magnify(by: 1.2)
        scene.rotate(by: simd_quatf(angle: 0.5, axis: [0, 1, 0]))
        scene.drag(by: [0.10, 0.03, 0])
        #expect(abs(scene.subject.position.x - 0.10) < 0.0001)
        #expect(abs(scene.size - 1.2) < 0.0001)
        #expect(abs(scene.subject.orientation.angle - 0.5) < 0.0001)
        scene.endDrag()
        #expect(scene.isInteracting)
        scene.endMagnify()
        #expect(scene.isInteracting)
        scene.endRotate()
        #expect(!scene.isInteracting)
    }

    @Test func ringBoundsStayInsideVolumeAtEverySize() {
        for form in OrbitForm.allCases {
            for size: Float in [0.65, 1, 1.55] {
                for sign: Float in [-1, 1] {
                    let p = OrbitScene.clampedPosition([10 * sign, 10 * sign, 10 * sign], size: size, form: form)
                    let radius = form.radius * size
                    #expect(abs(p.x) + radius < 0.5)
                    #expect(abs(p.y) + radius < 0.4)
                    #expect(abs(p.z) + radius < 0.4)
                }
            }
        }
    }

    @Test func resizingReclampsAnObjectNearTheVolumeEdge() {
        let scene = OrbitScene()
        scene.setForm(.orb, reduceMotion: true)
        scene.setSize(0.65)
        scene.drag(by: [10, 10, 10])
        scene.endDrag()
        scene.setForm(.saturn, reduceMotion: true)
        scene.setSize(1.55)
        #expect(abs(scene.subject.position.x) + 0.20 * scene.size < 0.5)
        #expect(abs(scene.subject.position.y) + 0.20 * scene.size < 0.4)
        #expect(abs(scene.subject.position.z) + 0.20 * scene.size < 0.4)
    }

    @Test func cancellationReleasesAllGestureOrigins() {
        let scene = OrbitScene()
        scene.drag(by: [0.1, 0, 0])
        scene.magnify(by: 1.2)
        scene.rotate(by: simd_quatf(angle: 0.5, axis: [1, 0, 0]))
        scene.endAllTransforms()
        #expect(!scene.hasActiveTransform)
        #expect(!scene.isInteracting)
        scene.nextColor(reduceMotion: true)
        #expect(scene.colorName == "Iris")
        scene.magnify(by: 1)
        #expect(abs(scene.size - 1.2) < 0.0001)
        scene.endMagnify()
    }

    @Test func reducedMotionDisablesOrbitalPlayback() {
        let scene = OrbitScene()
        scene.toggleOrbit(reduceMotion: false)
        #expect(scene.isPlaying)
        scene.setMotionPolicy(isActive: false, reduceMotion: false)
        #expect(scene.isPlaying)
        scene.setMotionPolicy(isActive: true, reduceMotion: true)
        #expect(!scene.isPlaying)
        scene.toggleOrbit(reduceMotion: true)
        #expect(!scene.isPlaying)
    }

    @Test func stylingAndTransformUpdatesPreserveChildAnimation() throws {
        let scene = OrbitScene()
        let renderer = try RealityRenderer()
        renderer.entities.append(contentsOf: [scene.root])
        try renderer.update(0.016)
        let animation = try AnimationResource.generate(with: FromToByAnimation<Transform>(
            from: .identity, to: Transform(rotation: simd_quatf(angle: 1, axis: [0, 1, 0])),
            duration: 30, bindTarget: .transform
        ))
        let controller = scene.orbits.playAnimation(animation)
        defer { controller.stop() }
        try renderer.update(0.05)
        try #require(controller.isPlaying)
        scene.setFinish(.chrome, reduceMotion: true)
        scene.setForm(.atom, reduceMotion: true)
        scene.setSize(1.2)
        scene.drag(by: [0.05, 0, 0])
        scene.endDrag()
        try renderer.update(0.05)
        #expect(controller.isPlaying)
    }

    @Test func resetRestoresEveryStudioSettingAndPose() {
        let scene = OrbitScene()
        scene.selectColor(4, reduceMotion: true)
        scene.setForm(.atom, reduceMotion: true)
        scene.setFinish(.glow, reduceMotion: true)
        scene.setSize(1.3)
        scene.drag(by: [0.1, 0.02, 0.03])
        scene.rotate(by: simd_quatf(angle: 0.7, axis: [0, 1, 0]))
        scene.endAllTransforms()
        scene.toggleOrbit(reduceMotion: false)
        scene.reset(reduceMotion: true)
        #expect(scene.colorName == "Azure")
        #expect(scene.form == .saturn && scene.finish == .pearl)
        #expect(scene.subject.position == OrbitScene.home)
        #expect(scene.subject.scale == .one)
        #expect(abs(scene.subject.orientation.real - 1) < 0.0001)
        #expect(scene.visual.scale == .one)
        #expect(!scene.isPlaying && !scene.hasActiveTransform)
    }

    @Test func invalidGestureValuesCannotCorruptThePose() {
        let scene = OrbitScene()
        scene.setSize(.nan)
        scene.magnify(by: .infinity)
        scene.drag(by: [.nan, 0, 0])
        scene.rotate(by: simd_quatf(vector: .zero))
        #expect(scene.size == 1)
        #expect(scene.subject.position == OrbitScene.home)
        #expect(!scene.hasActiveTransform)
    }

    @Test func resetCancelsAnInFlightColorAnimation() async throws {
        let scene = OrbitScene()
        scene.nextColor(reduceMotion: false)
        try await Task.sleep(for: .milliseconds(45))
        scene.nextColor(reduceMotion: false)
        scene.reset(reduceMotion: true)
        try await Task.sleep(for: .milliseconds(400))
        #expect(scene.colorName == "Azure")
        let material = try #require(scene.sphere.model?.materials.first as? PhysicallyBasedMaterial)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #expect(material.baseColor.tint.getRed(&r, green: &g, blue: &b, alpha: &a))
        #expect(abs(r - 0.18) < 0.001 && abs(g - 0.48) < 0.001 && abs(b - 0.95) < 0.001)
    }

    @Test func proceduralRingsHaveValidOutwardFacingTriangles() {
        let mesh = OrbitMesh.torusData(tube: 0.15, segments: 32, sides: 12)
        #expect(mesh.positions.count == 384)
        #expect(mesh.indices.count == 2304)
        for i in stride(from: 0, to: mesh.indices.count, by: 3) {
            let a = Int(mesh.indices[i]), b = Int(mesh.indices[i + 1]), c = Int(mesh.indices[i + 2])
            #expect(a < mesh.positions.count && b < mesh.positions.count && c < mesh.positions.count)
            let face = simd_cross(mesh.positions[b] - mesh.positions[a], mesh.positions[c] - mesh.positions[a])
            #expect(simd_dot(face, mesh.normals[a]) > 0)
        }
        for p in mesh.positions { #expect(simd_length(p) <= 1.1501) }
    }
}

@Suite(.serialized)
@MainActor
struct PalmDockTests {
    @Test func transitionsPreventDuplicateOpenAndCloseRequests() {
        let dock = PalmDockState()
        #expect(!dock.isPresented)
        #expect(dock.beginOpening())
        #expect(dock.isBusy)
        #expect(!dock.beginOpening())
        #expect(!dock.beginClosing())
        dock.didOpen()
        #expect(dock.isPresented)
        #expect(!dock.isBusy)
        #expect(!dock.beginOpening())
        #expect(dock.beginClosing())
        #expect(!dock.beginClosing())
        #expect(dock.isPresented)
        dock.didClose()
        #expect(!dock.isPresented)
        #expect(dock.beginOpening())
    }

    @Test func canceledOrFailedOpeningCanBeRetried() {
        let dock = PalmDockState()
        #expect(dock.beginOpening())
        dock.openingFailed("Try again")
        #expect(dock.message == "Try again")
        #expect(!dock.isBusy)
        #expect(dock.beginOpening())
        #expect(dock.message == nil)
        dock.openingFailed()
        // A late open callback after dismissal must not leave the toolbar hidden.
        dock.didOpen()
        #expect(!dock.isPresented)
    }

    @Test func anchorUsesLeftPalmAndKeepsExpansionAboveTheHandle() {
        let rig = PalmDockRig(preview: false)
        let handAnchor = rig.anchor as? AnchorEntity
        #expect(handAnchor?.anchoring.target == .hand(.left, location: .aboveHand))
        let facing = rig.surface.orientation.act(SIMD3<Float>(0, 0, 1))
        #expect(simd_length(facing - [0, 1, 0]) < 0.0001)
        #expect(rig.surface.position.z < 0)
        let view = Entity()
        rig.attach(view)
        #expect(view.parent === rig.surface)
        #expect(abs(view.scale.x - 0.72) < 0.0001)
        let bottom = view.position.y - PalmDockRig.canvasHeight * view.scale.y / 2000
        #expect(abs(bottom) < 0.0001)
        let preview = PalmDockRig(preview: true)
        #expect(preview.anchor.name != rig.anchor.name)
        #expect(preview.anchor.components[AnchoringComponent.self] == nil)
    }
}
