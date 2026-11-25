**Easiest install:** open Terminal and paste this line. It puts Zikr in Applications and opens it, with no warning:

```bash
curl -fsSL https://github.com/awalhossainofficial/tazkira/releases/latest/download/Zikr.zip -o /tmp/Zikr.zip && ditto -x -k /tmp/Zikr.zip /Applications && open /Applications/Zikr.app
```

**Downloaded Zikr.zip below instead?** Unzip it and move Zikr.app into Applications. macOS will block it, because it isn't signed with a paid Apple developer account. Run this once in Terminal, then open it normally:

```bash
xattr -dr com.apple.quarantine /Applications/Zikr.app
```

Needs macOS 14 or later. Works on Apple-chip and Intel Macs.
