**Easiest install:** open Terminal and paste this line. It puts Tazkira in Applications and opens it, with no warning:

```bash
curl -fsSL https://github.com/awalhossainofficial/tazkira/releases/latest/download/Tazkira.zip -o /tmp/Tazkira.zip && ditto -x -k /tmp/Tazkira.zip /Applications && open /Applications/Tazkira.app
```

**Downloaded Tazkira.zip below instead?** Unzip it and move Tazkira.app into Applications. macOS will block it, because it isn't signed with a paid Apple developer account. Run this once in Terminal, then open it normally:

```bash
xattr -dr com.apple.quarantine /Applications/Tazkira.app
```

Needs macOS 14 or later. Works on Apple-chip and Intel Macs.
