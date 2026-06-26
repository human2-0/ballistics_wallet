# iOS release flow

## Local build

Build a signed App Store IPA with an automatically increasing build number:

```sh
./scripts/ios_release.sh build
```

The IPA is written to `build/ios/ipa/`. Open Apple Transporter and drop the IPA
there, or configure API-key authentication for a one-command build and upload.

## Local build and upload

Create an App Store Connect API key and keep its private key at:

```text
~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
```

Set the non-secret key identifiers in your shell profile:

```sh
export APP_STORE_CONNECT_API_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_API_ISSUER_ID="YOUR_ISSUER_ID"
```

Then build and upload:

```sh
./scripts/ios_release.sh release
```

To upload an IPA that was already built:

```sh
./scripts/ios_release.sh upload
```

Set `IOS_BUILD_NAME` or `IOS_BUILD_NUMBER` to override either value. Set
`IOS_VALIDATE_BEFORE_UPLOAD=1` to run a separate validation before uploading.

## Xcode Cloud

The repository includes `ios/ci_scripts/ci_post_clone.sh`, which installs the
Flutter version pinned in `.flutter-version`, fetches Flutter packages, and runs
`pod install`. It also includes `ios/ci_scripts/ci_pre_xcodebuild.sh`, which
copies Xcode Cloud's `CI_BUILD_NUMBER` into Flutter's generated iOS build
settings before the archive step. Keep both scripts executable in Git.

In the Xcode Cloud workflow:

1. Use the shared `Runner` scheme and the Archive action.
2. Set the workflow's next build number above the latest uploaded build number
   for the current app version. This is only needed when the cloud counter is
   behind App Store Connect/TestFlight.
3. Add a TestFlight distribution post-action.
4. Trigger release archives manually or from a release branch/tag rather than
   on every commit.
