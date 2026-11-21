# Release guide

## Before the first release

1. **Application ID.** It is `com.wonderly.wonderly` on Android
   (`android/app/build.gradle.kts`) and `com.wonderly.wonderly` on iOS (Xcode,
   Runner target). Change both to a domain you own *before* publishing; the ID
   cannot change afterwards.
2. **App icon and launch screen.** The Flutter defaults are still in place.
   Replace `android/app/src/main/res/mipmap-*` and
   `ios/Runner/Assets.xcassets/AppIcon.appiconset`, and the iOS launch screen.
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

Google Play Families Policy and the Apple Kids Category have the same
spirit. Wonderly is built to meet it; verify each item for the build you ship.

- [ ] No `INTERNET` permission in the merged Android manifest
      (`flutter build appbundle` then inspect `AndroidManifest.xml` in the bundle).
- [ ] No analytics, advertising or crash-reporting SDKs that collect personal
      data (the dependency list in `pubspec.yaml` has none).
- [ ] No links out of the app and no purchases or prompts aimed at children.
- [ ] Parent gate protects the grown-ups zone (it does) and any future
      link, purchase or contact form.
- [ ] Privacy policy published and linked in the store listing. Core points:
      data stays on the device, none is collected or shared, deleting the app
      erases it.
- [ ] Target audience and content rating answered as children, grades 1 to 5.
- [ ] Declare "no data collected" in Play Data Safety and App Privacy.

## Release checklist

- [ ] CI green on `main`.
- [ ] Version bumped in `pubspec.yaml` (`version: x.y.z+build`) and
      `CHANGELOG.md` updated.
- [ ] Manual pass on a small and a large phone, with text size S and L.
- [ ] Parent gate, daily limit and bedtime mode verified on a real device.
- [ ] Read aloud verified on a device with an English voice installed.
- [ ] Tag the release: `git tag -a vX.Y.Z -m "Wonderly X.Y.Z" && git push --tags`.
