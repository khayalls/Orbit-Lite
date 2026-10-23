import Observation
import OSLog
import RealityKit
import UIKit

/// Separate entities own user transforms, feedback, and orbital motion. A pulse
/// can therefore never overwrite a simultaneous drag, stretch, or twist.
@MainActor
@Observable
final class OrbitScene {
    let root = Entity()
    let subject = Entity()
    let sphere = ModelEntity(mesh: .generateSphere(radius: 0.105))
    let visual = Entity()
    let orbits = Entity()

    private(set) var colorIndex = 0
    private(set) var form: OrbitForm = .saturn
    private(set) var finish: OrbitFinish = .pearl
    private(set) var size: Float = 1
    private(set) var isPlaying = false
    private(set) var isInteracting = false
    private(set) var errorMessage: String?
    var colorName: String { OrbitColor.palette[colorIndex].name }
    var status: String { isInteracting ? "In your hands" : (isPlaying ? "Orbiting" : "Pinch to explore") }
    var hasActiveTransform: Bool { dragOrigin != nil || scaleOrigin != nil || rotationOrigin != nil }

    static let home: SIMD3<Float> = [0, 0.04, 0]
    static let sizeRange: ClosedRange<Float> = 0.65...1.55
    @ObservationIgnored private var displayedRGB = OrbitColor.palette[0].rgb
    @ObservationIgnored private var dragOrigin: SIMD3<Float>?
    @ObservationIgnored private var scaleOrigin: Float?
    @ObservationIgnored private var rotationOrigin: simd_quatf?
    @ObservationIgnored private var colorTask: Task<Void, Never>?
    @ObservationIgnored private var feedbackTask: Task<Void, Never>?
    @ObservationIgnored private var thinRing: MeshResource?
    @ObservationIgnored private var wideRing: MeshResource?
    @ObservationIgnored private var orbitAnimation: AnimationResource?
    @ObservationIgnored private var playback: AnimationPlaybackController?
    @ObservationIgnored private var isSceneActive = true
    @ObservationIgnored private var reducesMotion = false
    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OrbitLite", category: "Interaction")

    init() {
        root.name = "OrbitRoot"
        subject.name = "OrbitSculpture"
        sphere.name = "OrbitSphere"
        orbits.name = "OrbitalDetails"
        subject.position = Self.home
        subject.components.set(InputTargetComponent())
        sphere.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.105)]))
        sphere.components.set(HoverEffectComponent())
        root.addChild(subject)
        subject.addChild(visual)
        visual.addChild(sphere)
        visual.addChild(orbits)
        var accessibility = AccessibilityComponent()
        accessibility.isAccessibilityElement = true
        accessibility.label = "Orbit sculpture"
        sphere.components.set(accessibility)
        do {
            thinRing = try OrbitMesh.torus(tube: 0.012)
            wideRing = try OrbitMesh.torus(tube: 0.15)
            // Sampling a complete turn avoids the zero-radius path of an orbit
            // animation and the identical endpoints of a 360-degree quaternion tween.
            let frames = (0...64).map { step in
                Transform(rotation: simd_quatf(angle: Float(step) * 2 * .pi / 64, axis: [0, 1, 0]))
            }
            let definition = SampledAnimation<Transform>(
                frames: frames, name: "Gentle orbit", frameInterval: 0.25, bindTarget: .transform
            )
            orbitAnimation = try AnimationResource.generate(with: definition).repeat()
        } catch {
            form = .orb
            errorMessage = "The orbit could not load. Try reopening Orbit Lite."
            logger.error("Orbital resources failed: \(error.localizedDescription, privacy: .public)")
        }
        rebuildDetails()
        applyColor(displayedRGB)
        updateAccessibility()
        logger.info("Scene ready: Saturn, Pearl, Azure")
    }

    func nextColor(reduceMotion: Bool) {
        guard !hasActiveTransform else { return }
        selectColor((colorIndex + 1) % OrbitColor.palette.count, reduceMotion: reduceMotion)
    }

    func selectColor(_ index: Int, reduceMotion: Bool) {
        guard OrbitColor.palette.indices.contains(index) else { return }
        colorIndex = index
        transitionColor(to: OrbitColor.palette[index].rgb, animated: !reduceMotion)
        pulse(reduceMotion: reduceMotion)
        updateAccessibility()
        logger.info("Color: \(self.colorName, privacy: .public)")
    }

    func nextForm(reduceMotion: Bool) {
        guard !hasActiveTransform, let index = OrbitForm.allCases.firstIndex(of: form) else { return }
        setForm(OrbitForm.allCases[(index + 1) % OrbitForm.allCases.count], reduceMotion: reduceMotion)
    }

    func setForm(_ newForm: OrbitForm, reduceMotion: Bool) {
        guard errorMessage == nil || newForm == .orb else { return }
        settleTransformAnimation()
        form = newForm
        rebuildDetails()
        keepInsideVolume()
        pulse(reduceMotion: reduceMotion)
        updateAccessibility()
    }

    func setFinish(_ newFinish: OrbitFinish, reduceMotion: Bool) {
        finish = newFinish
        applyColor(displayedRGB)
        pulse(reduceMotion: reduceMotion)
        updateAccessibility()
    }

    func setSize(_ value: Float) {
        guard value.isFinite else { return }
        settleTransformAnimation()
        size = min(max(value, Self.sizeRange.lowerBound), Self.sizeRange.upperBound)
        subject.scale = SIMD3(repeating: size)
        keepInsideVolume()
        updateAccessibility()
    }

    func drag(by translation: SIMD3<Float>) {
        guard translation.x.isFinite && translation.y.isFinite && translation.z.isFinite else { return }
        if dragOrigin == nil {
            beginTransform()
            dragOrigin = subject.position
        }
        guard let origin = dragOrigin else { return }
        subject.position = Self.clampedPosition(origin + translation, size: size, form: form)
    }

    func endDrag() { dragOrigin = nil; finishTransform() }

    func magnify(by factor: Double) {
        guard factor.isFinite && factor > 0 else { return }
        if scaleOrigin == nil {
            beginTransform()
            scaleOrigin = size
        }
        guard let origin = scaleOrigin else { return }
        setSize(origin * Float(factor))
    }

    func endMagnify() { scaleOrigin = nil; finishTransform() }

    func rotate(by rotation: simd_quatf) {
        guard rotation.vector.x.isFinite && rotation.vector.y.isFinite &&
                rotation.vector.z.isFinite && rotation.vector.w.isFinite &&
                simd_length(rotation.vector) > 0.0001 else { return }
        if rotationOrigin == nil {
            beginTransform()
            rotationOrigin = subject.orientation
        }
        if let origin = rotationOrigin { subject.orientation = simd_normalize(rotation * origin) }
    }

    func endRotate() { rotationOrigin = nil; finishTransform() }

    func endAllTransforms() {
        dragOrigin = nil; scaleOrigin = nil; rotationOrigin = nil
        finishTransform()
    }

    func toggleOrbit(reduceMotion: Bool) {
        guard !hasActiveTransform && !reduceMotion && orbitAnimation != nil else { return }
        isPlaying.toggle()
        updatePlayback()
    }

    func setMotionPolicy(isActive: Bool, reduceMotion: Bool) {
        isSceneActive = isActive
        reducesMotion = reduceMotion
        if reduceMotion { isPlaying = false }
        if !isActive { endAllTransforms(); stopFeedback() }
        updatePlayback()
    }

    func reset(reduceMotion: Bool) {
        endAllTransforms()
        stopFeedback()
        subject.stopAllAnimations(recursive: false)
        playback?.stop()
        playback = nil
        isPlaying = false
        orbits.transform = .identity
        colorIndex = 0
        form = thinRing == nil ? .orb : .saturn
        finish = .pearl
        size = 1
        rebuildDetails()
        transitionColor(to: OrbitColor.palette[0].rgb, animated: !reduceMotion)
        let target = Transform(translation: Self.home)
        if reduceMotion { subject.transform = target }
        else { subject.move(to: target, relativeTo: root, duration: 0.45, timingFunction: .easeInOut) }
        updateAccessibility()
        logger.info("Reset: Saturn, Pearl, Azure, home pose, motion paused")
    }

    func stopAnimations() {
        colorTask?.cancel()
        stopFeedback()
        settleTransformAnimation()
        endAllTransforms()
        playback?.pause()
        applyColor(OrbitColor.palette[colorIndex].rgb)
    }

    static func clampedPosition(_ p: SIMD3<Float>, size: Float, form: OrbitForm) -> SIMD3<Float> {
        // A bounding sphere covers rings in every orientation, including a two-hand twist.
        let radius = form.radius * min(max(size, sizeRange.lowerBound), sizeRange.upperBound) + 0.015
        let limits = SIMD3<Float>(0.48, 0.375, 0.375) - SIMD3(repeating: radius)
        return simd_min(simd_max(p, -limits), limits)
    }

    private func beginTransform() {
        settleTransformAnimation()
        stopFeedback()
        isInteracting = true
    }

    private func finishTransform() {
        isInteracting = hasActiveTransform
        if !isInteracting { updateAccessibility() }
    }

    private func settleTransformAnimation() {
        subject.stopAllAnimations(recursive: false)
        size = min(max(subject.scale.x, Self.sizeRange.lowerBound), Self.sizeRange.upperBound)
    }

    private func keepInsideVolume() {
        subject.position = Self.clampedPosition(subject.position, size: size, form: form)
    }

    private func updatePlayback() {
        guard isPlaying && isSceneActive && !reducesMotion else { playback?.pause(); return }
        if let playback { playback.resume() }
        else if let orbitAnimation {
            // RealityView manages its scene; animation doesn't require Entity.scene.
            playback = orbits.playAnimation(orbitAnimation)
        }
    }

    private func updateAccessibility() {
        guard var accessibility = sphere.components[AccessibilityComponent.self] else { return }
        accessibility.value = "\(colorName), \(form.rawValue), \(finish.rawValue), \(Int(size * 100)) percent"
        sphere.components.set(accessibility)
    }

    private func applyColor(_ rgb: SIMD3<Float>) {
        displayedRGB = rgb
        let color = UIColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.emissiveIntensity = 0
        switch finish {
        case .pearl:
            material.metallic = .init(floatLiteral: 0.25)
            material.roughness = .init(floatLiteral: 0.22)
            material.clearcoat = .init(floatLiteral: 0.85)
            material.clearcoatRoughness = .init(floatLiteral: 0.14)
        case .chrome:
            material.metallic = .init(floatLiteral: 0.95)
            material.roughness = .init(floatLiteral: 0.10)
            material.clearcoat = .init(floatLiteral: 0.6)
        case .glow:
            material.metallic = .init(floatLiteral: 0.05)
            material.roughness = .init(floatLiteral: 0.35)
            material.emissiveColor = .init(color: color)
            material.emissiveIntensity = 0.75
        }
        sphere.model?.materials = [material]
    }

    private func rebuildDetails() {
        for child in Array(orbits.children) { child.removeFromParent() }
        guard let thinRing, let wideRing else { return }
        var silver = PhysicallyBasedMaterial()
        silver.baseColor = .init(tint: UIColor(red: 0.72, green: 0.84, blue: 0.96, alpha: 1))
        silver.metallic = .init(floatLiteral: 0.8)
        silver.roughness = .init(floatLiteral: 0.23)
        let light = UnlitMaterial(color: UIColor(red: 0.62, green: 0.87, blue: 1, alpha: 1))
        func ring(_ mesh: MeshResource, radius: Float, flatten: Float = 1, material: any Material) -> ModelEntity {
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.scale = [radius, radius * flatten, radius]
            return entity
        }
        func moon(at position: SIMD3<Float>, radius: Float = 0.008) -> ModelEntity {
            let entity = ModelEntity(mesh: .generateSphere(radius: radius), materials: [light])
            entity.position = position
            return entity
        }
        switch form {
        case .orb:
            let plane = Entity()
            plane.orientation = simd_quatf(angle: 0.65, axis: [1, 0, 0])
            plane.addChild(ring(thinRing, radius: 0.145, material: light))
            plane.addChild(moon(at: [0.145, 0, 0]))
            orbits.addChild(plane)
        case .saturn:
            let plane = Entity()
            plane.orientation = simd_quatf(angle: 0.48, axis: [1, 0, 0]) * simd_quatf(angle: -0.22, axis: [0, 0, 1])
            plane.addChild(ring(wideRing, radius: 0.15, flatten: 0.14, material: silver))
            plane.addChild(ring(thinRing, radius: 0.181, material: light))
            plane.addChild(moon(at: [0.19, 0, 0]))
            orbits.addChild(plane)
        case .atom:
            for index in 0..<3 {
                let plane = Entity()
                plane.orientation = simd_quatf(angle: Float(index) * .pi / 3, axis: [0, 0, 1]) *
                    simd_quatf(angle: .pi / 2.8, axis: [1, 0, 0])
                plane.addChild(ring(thinRing, radius: 0.153, material: silver))
                let phase = Float(index) * 2.1
                plane.addChild(moon(at: [cos(phase) * 0.153, 0, sin(phase) * 0.153], radius: 0.01))
                orbits.addChild(plane)
            }
        }
    }

    private func transitionColor(to target: SIMD3<Float>, animated: Bool) {
        colorTask?.cancel()
        guard animated else { applyColor(target); return }
        let start = displayedRGB
        colorTask = Task { [weak self] in
            for frame in 1...20 {
                do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
                guard let self, !Task.isCancelled else { return }
                let t = Float(frame) / 20
                self.applyColor(start + (target - start) * (t * t * (3 - 2 * t)))
            }
        }
    }

    private func stopFeedback() {
        feedbackTask?.cancel()
        visual.stopAllAnimations(recursive: false)
        visual.scale = .one
    }

    private func pulse(reduceMotion: Bool) {
        stopFeedback()
        guard !reduceMotion && !hasActiveTransform else { return }
        visual.move(to: Transform(scale: SIMD3(repeating: 1.035)), relativeTo: subject,
                    duration: 0.14, timingFunction: .easeInOut)
        feedbackTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(145)) } catch { return }
            guard let self, !Task.isCancelled, !self.hasActiveTransform else { return }
            self.visual.move(to: .identity, relativeTo: self.subject, duration: 0.2, timingFunction: .easeInOut)
        }
    }
}
