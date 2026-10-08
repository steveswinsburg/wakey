# Wakey

[![Build](https://github.com/steveswinsburg/wakey/actions/workflows/build.yml/badge.svg)](https://github.com/steveswinsburg/wakey/actions/workflows/build.yml)

A tiny macOS menu-bar utility that keeps your Mac awake, in the spirit of
the classic "Caffeine" app. Click the lightbulb to toggle it on/off, or
right-click (control-click) for timed options. 

## Installing

### Option 1: Download a prebuilt binary (recommended)

1. Go to the [Releases](../../releases) page.
2. Download the latest `Wakey-macOS.zip`.
3. Unzip it and drag `Wakey.app` into your `Applications` folder (or
   `~/Applications`).
4. Since the app is only ad-hoc signed (not notarised by Apple), the
   first time you open it macOS Gatekeeper will refuse to launch it
   normally. Either:
   - Right-click `Wakey.app` → **Open** → **Open** in the confirmation
     dialog, or
   - Run `xattr -cr /Applications/Wakey.app` in Terminal to clear the
     quarantine flag, then open it as normal.
5. Launch Wakey - a lightbulb icon will appear in your menu bar.

### Option 2: Build from source

Requirements: macOS with Xcode Command Line Tools installed (for `swiftc`
and `iconutil`).

```bash
git clone https://github.com/<your-username>/wakey.git
cd wakey
./build.sh      # compiles Wakey.app into build/Wakey.app
./install.sh    # copies it into ~/Applications
```

Then launch it from `~/Applications/Wakey.app`, or run:

```bash
open "$HOME/Applications/Wakey.app"
```

## Updating

Re-run `./build.sh && ./install.sh`, or download the latest release zip and repeat the install steps above.

## Uninstalling

```bash
rm -rf ~/Applications/Wakey.app
```

## CI & Releases

- Every push to `main` triggers the [Build workflow](.github/workflows/build.yml),
  which compiles Wakey.app on `macos-latest` and uploads it as a
  short-lived build artifact — useful for verifying the build stays green
  and for grabbing a quick test build.
- Pushing a tag like `v1.0.0` triggers the [Release workflow](.github/workflows/release.yml),
  which builds the app, zips it, and publishes it as a downloadable asset
  on a GitHub Release.

To cut a new release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or create a release in Github directly as the same action will run

---
Created by 🤓 with ❤️ for the 🍎 community.