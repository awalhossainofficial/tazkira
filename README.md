<div align="center">

<img src="docs/assets/hero.svg" alt="A black Pill grows from the top of a Mac screen and shows a zikr, a dua and a durood in turn" width="100%">

# tazkira

**A quiet reminder to remember Allah, right at the top of your Mac.**

macOS 14+ · Free and open source · No tracking

</div>

<br>

Every few minutes a small black Pill grows from the top of your screen and shows one short zikr, dua or durood: the Arabic, the same words in English letters, and a short meaning. It stays for 8 seconds, waits while your mouse is over it, and closes when you click it.

The app is called **Zikr**. It lives in your menu bar, under a small moon.

## What it does

- **Reminders on your schedule.** Every 5, 10, 15 or 30 minutes, or any number of minutes from 1 to 180.
- **Only while you're at the Mac.** The countdown stops while the Mac sleeps or the screen is locked, so you never come back to a pile of missed reminders.
- **Fifteen authentic Remembrances.** Nine zikr, five duas and one durood, each with its hadith or Quran reference. They come in a shuffled round, so none repeats until you've seen them all.
- **Choose what you see.** Switch any Remembrance on or off in Settings.
- **Pause when you need quiet.** Pause for an hour or until 6 am tomorrow, or show one now from the menu.
- **Opens at login** and remembers your settings.

No accounts, no network access. Everything stays on your Mac.

## Four styles

Works on Macs with or without a notch. Pick one in Settings.

<img src="docs/assets/styles.svg" alt="The four Pill Styles: Island, Wings, Peek and Drop Card" width="100%">

## Install

Needs **macOS 14 (Sonoma) or later**. Works on Apple-chip and Intel Macs.

Open **Terminal** and paste this line. It downloads Zikr into your Applications folder and opens it:

```bash
curl -fsSL https://github.com/awalhossainofficial/tazkira/releases/latest/download/Zikr.zip -o /tmp/Zikr.zip && ditto -x -k /tmp/Zikr.zip /Applications && open /Applications/Zikr.app
```

A small moon appears in the menu bar. To update later, quit Zikr from its menu and run the same line again.

#### Downloaded it from the browser instead?

Zikr isn't signed with a paid Apple developer account, so macOS says it "can't be opened" or "can't check it for malware". Move `Zikr.app` into Applications, then run this once in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/Zikr.app
```

Now it opens normally. You can also click **Open Anyway** in **System Settings → Privacy & Security** after the first warning.

### Build it yourself

If you'd rather build from the code, it takes about a minute.

1. Install Apple's Command Line Tools if you haven't already. You don't need the full Xcode.

   ```bash
   xcode-select --install
   ```

2. Clone the repository and build the app.

   ```bash
   git clone https://github.com/awalhossainofficial/tazkira.git
   cd tazkira
   ./scripts/build-app.sh
   ```

3. Move `build/Zikr.app` into your Applications folder and open it.

## The Remembrances

Every Remembrance and its source lives in [`Sources/ZikrCore/BuiltInList.swift`](Sources/ZikrCore/BuiltInList.swift). The references point to Sahih al-Bukhari, Sahih Muslim, Sunan Abi Dawud, Jami at-Tirmidhi and the Quran.

If you spot a mistake in the Arabic, the English letters, the meaning or a reference, please [open an issue](https://github.com/awalhossainofficial/tazkira/issues). Getting these right matters more than anything else in the app.

## Working on it

```bash
./scripts/test.sh        # run the tests
./scripts/build-app.sh   # build build/Zikr.app
./scripts/package-release.sh   # build build/Zikr.zip and its release notes
```

[`docs/working-on-zikr.md`](docs/working-on-zikr.md) explains how the code is organised, and [`GLOSSARY.md`](GLOSSARY.md) defines the words used across it, such as Remembrance, Pill and Round.

Issues and pull requests are welcome. For anything bigger than a small fix, please open an issue first so we can talk it through.

## License

The code is under the [MIT License](LICENSE). The Arabic is set in [Amiri](https://github.com/aliftype/amiri), bundled under the SIL Open Font License ([`Resources/Fonts/Amiri-OFL.txt`](Resources/Fonts/Amiri-OFL.txt)).
