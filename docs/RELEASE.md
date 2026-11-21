# Release guide

## Before the first release

1. **Application ID.** It is `com.wonderly.wonderly` on Android
   (`android/app/build.gradle.kts`) and on iOS (Xcode, Runner target). Change both to a domain you own *before* publishing; the ID
   cannot change afterwards.
2. **App icon and launch screen.** Generated from the owl artwork
   (`flutter test tool/render_icon_test.dart`, then
   `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`).
   Replace `assets/icon/*.png` with final brand art if you have it.
3. **Store listing assets.** Screenshots (use the design mapping for order),
   description, privacy policy URL (see below).
4. **Content review.** A person other than the author verifies every question
   (see [CONTENT](CONTENT.md)).

## Android signing

Release builds read `android/key.properties`, which is git-ignored:

```properties
storePassword=<from your password manager>
keyPassword=<from your password manager>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Create the keystore once and back it up securely:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Never commit the keystore or `key.properties`. Without `key.properties` the
release build falls back to the debug key and **must not be uploaded**.

Build:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Keep `build/symbols` (outside version control) to symbolicate crash reports.
R8 shrinking is enabled; if a release build misbehaves, add narrow rules to
`android/app/proguard-rules.pro`.

## iOS

Set the team, bundle ID and signing in Xcode, then:

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

## Kids-category policy checklist

Google Play Families Policy and the Apple Kids Category share the same spirit.
Wonderly is built to meet it; verify each item for the build you ship.

- [ ] The only network use is the model download. `INTERNET` is declared for
      that purpose and nothing else (check the merged manifest of the bundle).
- [ ] The download starts only after a grown-up passes the parent gate, and
      warns before using mobile data.
- [ ] No analytics, advertising or crash-reporting SDKs collect personal data
      (see `pubspec.yaml`). `url_launcher` and `video_player` arrive
      transitively through `genui`; the app's A2UI catalog has no link, image
      or video component, so they are never reachable.
- [ ] No links out of the app and no purchases or prompts aimed at children.
- [ ] Privacy policy published and linked in the store listing. Core points:
      data stays on the device, none is collected or shared, the only download
      is the on-device model file, deleting the app erases everything.
- [ ] Target audience and content rating answered as children, grades 1 to 5.
- [ ] Play Data Safety and Apple App Privacy: "no data collected".
- [ ] Declare that AI-written content is checked automatically; keep the
      second-pass and safety rules in `docs/CONTENT.md` current.

## Device checklist (before every release)

- [ ] Fresh install on a 4 GB and a 6 GB Android phone: wake Smart Buddy,
      download the Balanced model on Wi-Fi, watch the Home chip show quiz writing
      progress, then play a freshly written set.
- [ ] Interrupt the download (airplane mode), resume, then cancel and remove.
- [ ] Kill the app mid-generation; relaunch; nothing written is lost.
- [ ] Open a quiz while generation runs: writing pauses and resumes.
- [ ] Low battery pauses writing; charging resumes it.
- [ ] Remove the model: the app keeps working with safety-net content.
- [ ] Two learners: stars, streaks and badges stay separate.
- [ ] Daily limit and bedtime mode end a session; the parent gate locks out
      after three misses.
- [ ] Sound, music and read-aloud on and off; music pauses in the background.
- [ ] Largest text size on a small phone.
- [ ] iOS: add the `Increased Memory Limit` and `Extended Virtual Addressing`
      capabilities for the Runner target if the large model fails to load.

## Release checklist

- [ ] CI green on `main`.
- [ ] Version bumped in `pubspec.yaml` (`version: x.y.z+build`) and
      `CHANGELOG.md` updated.
- [ ] Manual pass on a small and a large phone, with text size S and L.
- [ ] Parent gate, daily limit and bedtime mode verified on a real device.
- [ ] Read aloud verified on a device with an English voice installed.
- [ ] Tag the release: `git tag -a vX.Y.Z -m "Wonderly X.Y.Z" && git push --tags`.
