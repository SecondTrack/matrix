# Matrix

**A small native Matrix chat client for iOS 6.**

There is no Matrix app for iOS 6 and Element's web client is far too heavy for old Safari. This is a minimal client that talks to the Matrix Client-Server API directly.

## What it can do

- Sign in on matrix.org or your own homeserver – or create an account, if the server allows simple registration (servers that need a captcha or email are pointed to app.element.io).
- Rooms and direct messages, live via long-polling `/sync`.
- Send and receive text messages.

## Not yet

- **No end-to-end encryption:** encrypted messages show as "encrypted". Use unencrypted rooms for now.
- Images, files and voice messages show as placeholders.
- **Certificates are not verified yet** and the access token is stored in the app's preferences – fine for testing, not for anything sensitive. Both are on the list.

## Runs on

iOS 6.1.6 · jailbroken iPod touch 4

## Install

Easiest via the **[Reboot App Store](https://github.com/SecondTrack/reboot)** right on the iPod. By hand: `.deb` from the [latest release](https://github.com/SecondTrack/matrix/releases/latest), `dpkg -i`, then `uicache`.

Build it yourself with [Theos](https://theos.dev): `make package` (iOS 6.0+, armv7).

## License

GPL-3.0 – see [LICENSE](LICENSE). mbedTLS under `vendor/` keeps its own license.
Not affiliated with Apple. iPod is a trademark of Apple Inc.
