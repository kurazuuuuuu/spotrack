# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A macOS SwiftUI mini-game where the player uses up to 4 trackpad fingers as "spotlights" to track auto-running characters. Single Xcode app target, no tests, no CI.

- Xcode project: `spotrack/spotrack.xcodeproj`
- Bundle ID: `net.krz-tech.spotrack`
- Deployment target: macOS 26.4 (Swift 5, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- Window is locked to 800×500 (`spotrackApp.swift` + `windowResizability(.contentSize)`)

## Build / run

Open `spotrack/spotrack.xcodeproj` in Xcode and Run. Or from the command line:

```sh
xcodebuild -project spotrack/spotrack.xcodeproj -scheme spotrack -configuration Debug build
open spotrack/build/Debug/spotrack.app   # path may differ; check DerivedData if not present
```

There are no unit tests, no linter config, and no Swift Package manifest at the repo root — dependencies are managed inside the Xcode project.

### Trackpad permission caveat

The game reads raw multi-touch data via the `OpenMultitouchSupport` SPM dependency (`https://github.com/krishkrosh/OpenMultitouchSupport`, pinned to `branch = main`). Two consequences:

- `ENABLE_APP_SANDBOX = NO` is set deliberately — sandboxed builds cannot reach the private MultitouchSupport API. Do not re-enable the sandbox without first finding a replacement.
- The first run on a machine may need accessibility/input-monitoring approval. If touches never register, that's the first thing to check, not a code bug.

## Architecture

Three Swift files do all the work; the shape is small enough that a single read of each is enough.

- `GameEngine.swift` — `@Observable @MainActor` model. Owns: characters array, current finger positions, score, timer, game state (`menu` / `playing` / `gameOver`). Spins up two things on `startGame()`:
  1. `OMSManager.shared.touchDataStream` async sequence → filtered to active touches → published as `fingers: [CGPoint]`.
  2. `Timer.scheduledTimer` at 60Hz calling `update()`, which advances physics, recomputes per-character `isLit`, and accumulates score.
- `ContentView.swift` — top-level view that switches between menu / `GameView` / game-over panel based on `engine.state`.
- `GameView.swift` — pure `Canvas` rendering. Uses `TimelineView(.animation)` for the walk-cycle phase only; all simulation state still comes from `GameEngine`. Draws background, additive-blended spotlight gradients, characters (legs/body/head), and name tags for lit characters.

### Coordinate system — read this before touching rendering or hit testing

Everything in `GameEngine` (character positions, finger positions, radii) is normalized **0..1 with y=0 at the bottom**. This matches what `OpenMultitouchSupport` emits, so touch points are stored as-is.

`GameView` flips to screen space at draw time with `(1 - y) * size.height`. If you move logic between engine and view, mind the flip — a missing `(1 - y)` is the most likely bug.

Hit testing in `GameEngine.update()` happens entirely in normalized space (`spotlightRadius + characterRadius`), so it stays correct regardless of window size.

### Scoring

Per tick, if `currentLit > 0`, score accumulates `dt * 10 * currentLit²` — quadratic in the number of simultaneously-lit characters, which is the entire point of the "combo" mechanic. Changing the exponent changes the game's feel more than any other constant.

### Tunable constants (all in `GameEngine`)

`groundLevel`, `gravity`, `characterRadius`, `spotlightRadius`, `gameDuration`, plus per-character `baseSpeed` / `jumpForce` / `jumpFrequency` / `turnFrequency` / `hue` / `name` in `makeCharacters()`. Adding or removing characters is just editing that array.
