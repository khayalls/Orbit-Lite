# Orbit Lite 1.2 — Palm Dock

A small native spatial playground for Apple Vision Pro, made with SwiftUI and RealityKit. One polished sphere becomes a Halo, a ringed Saturn, or an Atom. All geometry is generated locally. The collapsible glass dock can float below the sculpture or follow your left hand. There are no third-party packages or raw hand-tracking permissions.

## Get the project

Clone [khayalls/Orbit-Lite](https://github.com/khayalls/Orbit-Lite), or choose **Code > Download ZIP** on GitHub. Open `OrbitLite.xcodeproj` from the downloaded folder. No new Xcode project or GitHub Project board is needed.

GitHub stores the source and version history. The native app runs through Xcode on a simulator or paired Vision Pro. A downloaded project still needs your own Apple development team selected for device signing.

[Read validation results](Validation/Results.txt). Simulator screenshots and recordings are kept locally on the original Mac and omitted from this source repository to keep downloads small.

## Open and run

Open **OrbitLite.xcodeproj**, choose the **OrbitLite** scheme, select your headset or an Apple Vision Pro simulator, and click **Run**. Running again installs this expanded version over the earlier Orbit Lite app.

The scene starts with an Azure Saturn in the Pearl finish, with motion paused.

## Hand gestures

Look at the **center sphere** before starting a gesture. The decorative rings and moons leave the center sphere as the clear interaction target.

| Gesture | Action |
| --- | --- |
| Pinch and release | Cycle six colors: Azure, Iris, Rose, Amber, Jade, Ice |
| Quickly pinch twice | Cycle Saturn, Atom, and Halo forms |
| Pinch and hold still for about 0.65 seconds, then release | Start or pause orbital motion |
| Pinch and immediately drag | Move the entire sculpture left/right, up/down, or in depth |
| Pinch with both hands and move them apart/together | Resize the sculpture between 65% and 155% |
| Pinch with both hands and twist | Rotate the sculpture and its rings in 3D |

Dragging, stretching, and twisting can run together. Movement limits adapt to the current form and size so the rings stay inside the volume. A canceled gesture releases its interaction state. Reset also cancels unfinished color and feedback animations.

These use standard SwiftUI gestures targeting RealityKit entities. No fist, palm, or custom finger-pose recognizer is used. [Apple's native gesture example](https://developer.apple.com/documentation/realitykit/transforming-realitykit-entities-with-gestures).

## Palm dock

The toolbar now collapses into a small glass capsule with a color-matched orb. Pinch it to expand the controls; pinch the down chevron to collapse it again. The inspector unfolds above the dock, keeping the dock's bottom edge in place. Reduce Motion removes the spring transitions and pauses orbital animation.

On **your physical Vision Pro**:

1. Run Orbit Lite and select **Attach to left palm** on the floating dock.
2. Keep your left hand in view, comfortably in front of you. A small glass handle appears just above it.
3. Look at the handle and pinch with your **right hand** to expand it.
4. Use **Style**, **Orbit / Pause**, **Gestures**, or **Reset**. Look and pinch each control, or use direct touch where comfortable.
5. Select the down chevron to collapse it. Select **Float toolbar** to return to the floating dock. A separate Float toolbar control remains below the sphere, even if your hand is out of view.

The native RealityKit anchor targets the **left hand, aboveHand** location. Apple's orientation keeps the dock upright as the wrist turns; the view has an additional small offset away from the hand. The dock follows the hand while the sculpture remains in its volume. It starts collapsed each time you attach it. Expansion is deliberate; raising or turning the palm does not automatically open it.

Palm attachment opens a **mixed ImmersiveSpace**: your room and the app's sculpture remain visible, and other apps are hidden until you leave this mode. No custom fist, palm-up detector, or finger skeleton recognizer runs. RealityKit owns the hand pose and the app never reads or stores it. [Apple's hand anchor locations](https://developer.apple.com/documentation/realitykit/anchoringcomponent/target-swift.enum/handlocation), [privacy-preserving anchoring](https://developer.apple.com/documentation/realitykit/spatialtrackingsession), [immersive spaces](https://developer.apple.com/documentation/swiftui/immersive-spaces).

### Dock controls

- **Style** opens the inspector: choose Halo / Saturn / Atom, pick a color, switch Pearl / Chrome / Glow finishes, or adjust the size slider.
- **Orbit / Pause** controls the slow orbital animation of the rings and moons.
- **Gestures** opens the in-app guide, including the two-hand interactions.
- **Reset** restores Azure, Saturn, Pearl, 100% size, the initial position and orientation, and paused motion.

## Test in the simulator

On a simulator, **Preview palm dock** opens a stationary layout preview to the left of the sculpture. It intentionally uses an ordinary entity rather than pretending to track a hand: native anchor entities did not resolve in this simulator session. You can expand, collapse, and use every control in this preview. Following a real left hand and checking comfort require the headset.

Select the arrow control in Device Hub. Click to simulate a pinch, double-click for a double pinch, click and hold for the hold command, and drag to move. Shift-drag up/down moves in depth. Two-hand interaction should be checked on the physical headset. [Apple's simulator controls](https://developer.apple.com/documentation/xcode/interacting-with-your-visionos-app-in-device-hub).

From this folder, `./Scripts/run-simulator.sh` builds and launches the newest installed Vision Pro simulator. `./Scripts/run-simulator.sh --test` first runs the scene tests and native toolbar test. The script uses no physical-device provisioning.

## Run on your physical Vision Pro

1. Connect the Mac and headset to the same Wi-Fi network. Apple's current guide requires IPv6 on that network.
2. On Vision Pro, open **Settings > General > Remote Devices** and leave it open.
3. On the Mac, open **Xcode > Open Developer Tool > Device Hub**. Choose **+ > Pair Nearby Device > Apple Vision Pro**. Select the headset, enter its PIN on your Mac, and accept Trust on the headset if prompted.
4. On Vision Pro, enable **Settings > Privacy & Security > Developer Mode**. Restart and confirm the prompt afterward. This setting may appear only after pairing begins.
5. In Xcode, select the **OrbitLite target > Signing & Capabilities**. Keep **Automatically manage signing** enabled and **Khayal Mammadaliyev (Personal Team)** selected. The bundle identifier remains `com.khayalius.OrbitLite`.
6. Choose the physical headset in the run destination menu and click **Run**. Keep it awake and unlocked while Xcode registers it, creates its profile, and installs the app. Complete Apple Account, passcode, or signing-key permission prompts yourself if requested.

References: [Apple pairing guide](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub), [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device), [signing and deployment](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

## Headset checklist

- [ ] Pair, trust, and enable Developer Mode.
- [ ] Select the physical device and finish automatic signing in Xcode.
- [ ] Check single pinch, double pinch, and stationary hold as separate actions.
- [ ] Move the sculpture, then release; releasing a drag should not change its color.
- [ ] Stretch with two hands, including the smallest and largest sizes.
- [ ] Twist, then combine rotation, movement, and resizing.
- [ ] Compare all three forms and finishes in your room's lighting.
- [ ] Select Attach to left palm and verify the collapsed handle follows the left hand.
- [ ] Raise, lower, and gently turn the wrist; check readability and tracking stability.
- [ ] Open and close the dock using the right hand; check touch targets and accidental activation.
- [ ] Check the dock's offset from the hand and the system Home indicator. System hand menus remain available.
- [ ] Move the left hand out of view, then bring it back; use the floating recovery control if needed.
- [ ] Select Float toolbar and confirm the sculpture's appearance is preserved.
- [ ] Start and pause motion, open both inspectors, and verify Reset restores every setting.
- [ ] Verify comfortable placement, text readability, and Reduce Motion behavior.

## Project structure

- **OrbitLiteApp.swift**: shared sculpture state, 1.0 × 0.8 × 0.8 meter volume, and mixed palm-dock space.
- **OrbitView.swift**: native sculpture gestures, floating dock, palm-mode entry, and recovery control.
- **OrbitScene.swift**: scene entities, simultaneous transforms, adaptive bounds, materials, motion, feedback, and Reset.
- **OrbitStyle.swift**: forms, finishes, palette, and procedural ring geometry.
- **OrbitToolbar.swift**: glass capsule, expanded dock, style inspector, gesture guide, and motion accessibility.
- **PalmDock.swift**: native left-hand anchoring, fixed-edge attachment layout, simulator preview, and guarded scene lifecycle.
- **OrbitLiteTests/**: 20 focused scene, geometry, animation-isolation, anchor-layout, and lifecycle tests.
- **StudioUITests/**: two native simulator UI tests for controls, expansion, palm preview, and return with preserved state.
- **Validation/**: build/test evidence and composited simulator captures.

## Validation and limits

Xcode 27.1, visionOS 27.0 SDK, deployment target visionOS 2.0. Automatic signing still uses the Personal Team. No physical headset was detected during this update.

The scene tests exercise simultaneous transforms, gesture-origin cleanup, bounds at every size, material changes, palette/form cycles, invalid inputs, Reset, and ring triangle winding. The two native UI tests operate Style, form/color/finish controls, Orbit/Pause, the gesture guide, Reset, dock expansion, the mixed-space preview, and returning to floating mode with the same appearance.

Automated input targeting the 3D entity still fails with `Received invalid activation point transform (nil) from Accessibility`. Toolbar automation succeeds. State tests establish the transform logic; they do not establish actual eye/hand gesture delivery. Physical gesture testing and device provisioning remain pending. See **Validation/Results.txt** for the final run results.

Earlier local versions are preserved separately as **OrbitLite-v1.zip** and **OrbitLite-v1.1.zip** beside this project on the original Mac; those archives are not part of this repository. No App Store upload or publication has been performed.
