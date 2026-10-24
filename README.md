# LangFix

**English** · [ไทย](README.th.md)

Fixes text typed on the wrong keyboard layout, Thai ↔ English, as you type on your Mac.

Forgot to switch layouts and typed `l;ylfu`? LangFix turns it into `สวัสดี` and switches the layout for you. No deleting, no retyping.

**[⬇︎ Download LangFix](https://github.com/l3aipat/langfix/releases/latest/download/LangFix.dmg)** · Free · macOS 13 or later

## Features

- Fixes a word from its third letter. Short words such as "นะ" are fixed when you press Space.
- Fixed something you meant? Press Delete right away. Your original text comes back, and LangFix leaves that word alone from then on.
- To convert text you already typed, select it and press Option+Shift+Space.
- Remembers the last layout you used in each app and switches to it when you come back.
- Shows a small ก or A badge next to the cursor when the layout changes.
- Can be turned off for specific apps, and you can add words it should never touch, such as 555.

## Install

Your Mac needs both a Thai keyboard and an English one (ABC or U.S.). Add them in System Settings > Keyboard > Input Sources.

1. [Download LangFix.dmg](https://github.com/l3aipat/langfix/releases/latest/download/LangFix.dmg) and open it.
2. Drag LangFix into the Applications folder.
3. Open LangFix from Applications.
4. If you see "LangFix" Not Opened, click Done.
   Go to System Settings > Privacy & Security, scroll to the bottom, click **Open Anyway** and enter your password.
   Open LangFix again and click Open Anyway.
5. Grant Accessibility access. Click the ก/a icon in the menu bar,
   choose "Turn on LangFix in Accessibility settings…" and switch LangFix on.
6. When the icon changes from ก/a ⚠︎ to ก/a, LangFix is ready.

### Why macOS warns you

LangFix is a free project without a paid Apple Developer ID ($99 a year), so macOS doesn't recognise the developer and shows a warning. It doesn't mean the app is harmful. All the source code is in this repository.

### Why LangFix needs Accessibility access

To tell that you typed on the wrong layout, LangFix has to see the keys you press, and to fix it, it has to delete the word and type the right one. macOS only allows that through Accessibility access.

LangFix doesn't store or send anything you type. All correction happens on your Mac. The only network access is checking GitHub for new versions, and it checks automatically only if you allow it when the app asks.

## Updating

Choose "Check for Updates…" from the ก/a menu and click Install. You don't need to grant Accessibility again.

Coming from 0.1.8 or earlier? Update by hand once. Download the new version from the [same link](https://github.com/l3aipat/langfix/releases/latest/download/LangFix.dmg) and drag it over the old one in Applications. Then select LangFix in the Accessibility list, click −, and click + to add LangFix back.

See what changed in each version on the [Releases](https://github.com/l3aipat/langfix/releases) page.

## Feedback

LangFix is free and will stay free. What helps most is hearing how it works for you.

Open an [issue](https://github.com/l3aipat/langfix/issues), in English or Thai. For a problem, include your macOS version, the app you were typing in, and the word that was fixed wrongly or not fixed.

## License

LangFix is free software under the [GPL-3.0](LICENSE). You may use, change and share it. If you share a changed version, you must release its source under the GPL-3.0 too.

The app includes [Sparkle](https://sparkle-project.org) (MIT). Its license text is at `LangFix.app/Contents/Resources/Sparkle-LICENSE.txt`.

## Building

```sh
swift build                 # build
./scripts/test.sh           # unit tests
./scripts/make-dmg.sh       # build/LangFix-<version>.dmg
./scripts/release.sh        # stage LangFix.dmg and appcast.xml for a GitHub release
```
