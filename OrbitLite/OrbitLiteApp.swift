import SwiftUI

@main
struct OrbitLiteApp: App {
    @State private var orbit = OrbitScene()
    @State private var dock = PalmDockState()
    @State private var immersionStyle: ImmersionStyle = .mixed

    var body: some Scene {
        WindowGroup(id: "orbit") {
            OrbitView(orbit: orbit, dock: dock)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.0, height: 0.8, depth: 0.8, in: .meters)
        .windowResizability(.contentSize)

        ImmersiveSpace(id: PalmDockState.spaceID) {
            PalmDockSpace(orbit: orbit, dock: dock)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
        .upperLimbVisibility(.visible)
    }
}
