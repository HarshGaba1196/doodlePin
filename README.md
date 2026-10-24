# DoodlePin

Little doodle pets that live on your Mac desktop. They walk, hop, roll and float around, chase balls, eat treats, dance to your music, and nudge you before meetings.

## Features

- **11 doodles:** Blob, Cat, Dog, Bunny, Bear, Penguin, Frog, Ghost, Cloud, Alien, Robot
- **Dress-up:** 9 hats (party hat, top hat, crown, beanie, wizard hat, cap, bow, flower, halo) and 3 kinds of glasses
- **Movement:** walkers stroll along the bottom of the screen, frogs and bunnies hop, the robot rolls, ghosts and clouds float anywhere. Grab a pet and throw it to send it flying.
- **Several pets:** up to 8 at once. They say hi when they bump into each other.
- **Games:**
  - *Fetch:* throw a ball from the menu bar. Pets chase it, catch it, and toss it back to your cursor. Drag the ball to throw it again, click it to kick it, double-click to put it away.
  - *Feeding:* treats fall from above, and each species has a favourite. Pets slowly get hungry and will tell you.
- **Reactions:**
  - Music: headphones and dancing while Apple Music or Spotify is playing
  - Battery: cheers when you plug in, sweats when the battery is low
  - Calendar: a heads-up 10 minutes before a meeting and again when it starts (opt-in)
- **Little extras:** eyes follow your cursor, blinking, naps when you're away, jokes and facts, stretch and water reminders
- **Menu bar menu** and a **Settings window** (Pets, Behavior, Reactions, General with launch at login)

## Project layout

```
DoodlePin.xcodeproj         Xcode project (needs Xcode 16 or later)
DoodlePin.entitlements      App Sandbox + calendar access
DoodlePin/
  App/                      Entry point, menu bar icon, menus
  Model/                    Doodle types, hats, pet data, settings, dialogue
  Doodles/                  All the drawing code (characters, hats, glasses)
  Pets/                     Pet windows, movement, physics, the pet manager
  Toys/                     Ball and treats
  Reactions/                Music, battery and calendar watchers
  Settings/                 Settings window
  Assets.xcassets/          App icon
  PrivacyInfo.xcprivacy     Privacy manifest (required by the App Store)
Tools/IconMaker/            Renders the app icon from the doodle code
scripts/make-icon.sh        Regenerates the icon PNGs
build.sh                    Quick build without Xcode → build/DoodlePin.app
```

## Running

**Without Xcode** (quick testing):

```bash
./build.sh && open build/DoodlePin.app
```

**With Xcode:** open `DoodlePin.xcodeproj` and press ⌘R.

## Releasing outside the App Store (zip + website)

```bash
./scripts/package.sh
```

This builds a universal app (Apple Silicon + Intel) and writes:
- `dist/DoodlePin.zip`: the app, `install.sh` and a READ ME
- `docs/install.sh`: the same installer, for the one-line web install

The website lives in `docs/` (`index.html`, `privacy-policy.html`, `install.sh`, `assets/`). It is published from its own repo:

| What | Where |
|---|---|
| App source and releases | https://github.com/HarshGaba1196/doodlePin |
| Website (GitHub Pages) | https://github.com/HarshGaba1196/doodle-site → https://harshgaba1196.github.io/doodle-site/ |
| Zip download | https://github.com/HarshGaba1196/doodlePin/releases/latest/download/DoodlePin.zip |
| One-line install | `curl -fsSL https://harshgaba1196.github.io/doodle-site/install.sh \| bash` |

To release a new version: bump `MARKETING_VERSION` in the Xcode project, run `./scripts/package.sh`, create a release on the doodlePin repo with `dist/DoodlePin.zip` attached (keep the file name), then copy `docs/` into the doodle-site repo and push.

The installer clears macOS's "downloaded from the internet" flag, because the app isn't notarized. Once you have a paid Apple Developer account, sign the app with your Developer ID and notarize it. Users can then open it with a plain double-click.

## Selling on the Mac App Store

1. Install **Xcode** from the Mac App Store.
2. Join the **Apple Developer Program** ($99/year) at developer.apple.com.
3. In Xcode, select the DoodlePin target → **Signing & Capabilities** → choose your **Team**. If you want a different bundle ID, change it from `com.harshgaba.DoodlePin`.
4. In **App Store Connect** (appstoreconnect.apple.com), create a new macOS app with the same bundle ID.
5. In Xcode, choose **Product → Archive**, then **Distribute App → App Store Connect**.
6. In App Store Connect, add:
   - screenshots
   - a description
   - a price
   - a privacy policy URL (DoodlePin collects no data)
   - the privacy answer "Data Not Collected"

   Then submit for review.

**Review notes worth including:** the app lives in the menu bar (no Dock icon). Settings open from the menu bar icon. Calendar access is optional and only used for on-device meeting reminders.

## Changing the icon

The icon is drawn from code in `Tools/IconMaker/main.swift`. After you edit it, regenerate the PNGs:

```bash
./scripts/make-icon.sh
```
