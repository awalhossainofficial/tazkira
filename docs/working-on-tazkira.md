# Working on Tazkira

How the app is built, and how to work on it the way a Mac developer would.

## What it is made of

- **Swift**, Apple's own language for Mac and iPhone apps.
- **SwiftUI** draws the Pill and the Settings window.
- **AppKit** (Apple's older Mac toolkit) runs the menu-bar icon, the floating window that sits over the notch, and sleep/lock events.
- **No outside libraries.** Only Apple's own frameworks, plus the bundled Amiri font.

Why native Swift rather than Electron or a web app: Tazkira runs all day in the background, so it must be light. A native menu-bar app uses a few tens of MB of memory; an Electron app starts at several hundred. Only native code can place a window exactly around the notch, show over full-screen apps and on every Space, and react to sleep and lock.

## How the code is laid out

One Swift package (`Package.swift`) with three parts:

- **TazkiraCore**: the rules, with no screen code. The Scheduler (Interval, Round, Pause, sleep and lock), the Built-in List and the saved settings. Everything here is tested.
- **Tazkira**: the app itself. The menu, the Pill and its four Pill Styles, the Settings window. Checked by eye, using the real-Mac checklist.
- **TazkiraCoreTests**: the tests for TazkiraCore.

The rule that keeps this clean: anything that is a decision (when to show, what to show, what to save) goes in TazkiraCore, where a test can reach it. The app layer only draws and listens.

## Day-to-day commands

```bash
./scripts/test.sh          # run the tests
./scripts/build-app.sh     # build build/Tazkira.app
open build/Tazkira.app        # run it
```

## Making a release

1. Raise the version (`CFBundleShortVersionString`) in `scripts/build-app.sh`, then commit and push.
2. Write a few lines on what's new in a file, for example `whats-new.md`.
3. Run `./scripts/package-release.sh --publish whats-new.md`.

The script builds Tazkira.zip for Apple-chip and Intel Macs and creates the GitHub release, tagged with the version. It adds the install guide from `docs/release-install.md` under your notes, so every release explains how to get past the macOS warning. Without `--publish` it only builds the zip and notes in `build/`, so you can check them first.

## Xcode

Most Mac developers write code in **Xcode**, Apple's free editor from the Mac App Store. This project doesn't need it, because it is a plain Swift package and the command-line tools build it. But Xcode is worth installing once you start changing the code yourself:

- **Open the project:** open `Package.swift` in Xcode. No conversion is needed.
- **SwiftUI previews:** see a Pill Style change live as you type, without building the whole app.
- **Debugger:** pause the app at a line and look at what's going on.
- **Instruments:** measure memory and battery use.
- **Signing and notarising:** needed before you give the app to anyone else, so macOS trusts it. This build is signed only for this Mac.

The command-line scripts keep working alongside Xcode.

## Habits worth keeping

- **Small commits on `main`**, one change each, with a plain-English message.
- **Spec, then tickets, then code.** Features start as a spec and tickets under `.scratch/<feature>/`, a local folder that is not pushed to GitHub.
- **Few tests, in the right places.** Test the rules in TazkiraCore: timing, saving, Rounds, Pauses. Check the look on the real Mac.
- **Glossary words in the code.** Use the names in `GLOSSARY.md` (Remembrance, Reminder, Pill, Pill Style, Preview, Interval, Round, Pause) for types and functions.
- **Short comments that explain why**, never what the code already says.

## One repo, one package

A monorepo only pays off when several apps or services share code. Tazkira is one app, so one package with a rules part and an app part is the right size. If an iPhone app or a widget comes later, it becomes another part of the same package and reuses TazkiraCore. That is a small monorepo already, with nothing new to set up.
