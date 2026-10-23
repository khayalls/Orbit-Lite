import RealityKit
import SwiftUI
import UIKit

enum OrbitForm: String, CaseIterable, Identifiable {
    case orb = "Halo", saturn = "Saturn", atom = "Atom"
    var id: Self { self }
    var radius: Float {
        switch self {
        case .orb: 0.16
        case .saturn: 0.20
        case .atom: 0.17
        }
    }
}

enum OrbitFinish: String, CaseIterable, Identifiable {
    case pearl = "Pearl", chrome = "Chrome", glow = "Glow"
    var id: Self { self }
}

struct OrbitColor: Identifiable {
    let id: Int
    let name: String
    let rgb: SIMD3<Float>
    var color: Color { Color(red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z)) }
    static let palette: [Self] = [
        .init(id: 0, name: "Azure", rgb: [0.18, 0.48, 0.95]),
        .init(id: 1, name: "Iris", rgb: [0.55, 0.32, 0.94]),
        .init(id: 2, name: "Rose", rgb: [0.95, 0.34, 0.52]),
        .init(id: 3, name: "Amber", rgb: [0.98, 0.63, 0.20]),
        .init(id: 4, name: "Jade", rgb: [0.20, 0.79, 0.65]),
        .init(id: 5, name: "Ice", rgb: [0.50, 0.88, 1.00])
    ]
}

/// A small procedural torus, shared by the rings. No downloaded 3D assets.
enum OrbitMesh {
    @MainActor
    static func torus(tube: Float, segments: Int = 128, sides: Int = 16) throws -> MeshResource {
        let data = torusData(tube: tube, segments: segments, sides: sides)
        var descriptor = MeshDescriptor(name: "OrbitRing")
        descriptor.positions = MeshBuffers.Positions(data.positions)
        descriptor.normals = MeshBuffers.Normals(data.normals)
        descriptor.primitives = .triangles(data.indices)
        return try MeshResource.generate(from: [descriptor])
    }

    static func torusData(tube: Float, segments: Int, sides: Int)
        -> (positions: [SIMD3<Float>], normals: [SIMD3<Float>], indices: [UInt32]) {
        precondition(segments >= 3 && sides >= 3 && tube > 0 && tube < 1)
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for ring in 0..<segments {
            let u = Float(ring) / Float(segments) * 2 * .pi
            for side in 0..<sides {
                let v = Float(side) / Float(sides) * 2 * .pi
                let normal = SIMD3<Float>(cos(u) * cos(v), sin(v), sin(u) * cos(v))
                positions.append([cos(u) * (1 + tube * cos(v)), tube * sin(v), sin(u) * (1 + tube * cos(v))])
                normals.append(normal)
                let a = UInt32(ring * sides + side)
                let b = UInt32(((ring + 1) % segments) * sides + side)
                let c = UInt32(((ring + 1) % segments) * sides + (side + 1) % sides)
                let d = UInt32(ring * sides + (side + 1) % sides)
                indices += [a, d, b, b, d, c]
            }
        }
        return (positions, normals, indices)
    }
}
