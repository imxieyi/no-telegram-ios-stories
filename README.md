No Telegram iOS Stories
===

Script to build Telegram iOS without Stories in chat list, then upload to TestFlight for auto update on device.

**Paid Apple dev account required!**

## Why

- It's stupidly easy to open Stories camera by accident in chat list, especially while using Telegram with left hand only.
- I don't trust any 3rd-party Telegram clients.

## Caveat

- Push notifications are very broken due to an entitlement that requires Apple's explicit approval (TelegramMessenger/Telegram-iOS#690)

## Instructions

### Setup Telegram iOS build

Follow [README in Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS) until before `Advanced Compilation Guide`. After Xcode opens automatically, check that the `Telegram` target has signing certificate populated. Then close Xcode and follow `Advanced Compilation Guide -> Xcode` section.

If you still want broken push notifications, create APNS certificates and upload them [here](https://my.telegram.org/auth?to=apps). Then add `Push notifications` capability to `Telegram` target.

### Required files

- `codesigning` directory which you copied from `build-system/fake-codesigning`. Generate and download provisioning profiles from Apple Developer website and put them in `codesigning/profiles`. You will need at least `App Groups` entitlement for all extensions. Use the Xcode generated one for the main app. WatchOS ones can be ignored.
- `release_config.json` which you copied and edited from `build-system/appstore-configuration.json`.
- `env.sh` which you copied from `env.example.sh` and filled in with the correct values.

### Optional files

- `DefaultAppIcon.xcassets` to replace the app icon. Use the [official icon asset](https://github.com/TelegramMessenger/Telegram-iOS/tree/master/Telegram/Telegram-iOS/DefaultAppIcon.xcassets) as reference.
- `0002-Change-app-name.patch` to change app display name. Create this patch by replacing `CFBundleDisplayName` values in [BUILD](https://github.com/TelegramMessenger/Telegram-iOS/blob/master/Telegram/BUILD).

### Setup TestFlight

You already know how to do this if you own a paid Apple dev account.

### Initial build

If everything is set up correctly, running `./build.sh` should automatically build a new version and release it on TestFlight.

### Scheduled build

Use `crontab` to run `build.sh` should be good enough. Just keep in mind that TestFlight builds expire after 90 days. The script will only build when Telegram version number changes.
