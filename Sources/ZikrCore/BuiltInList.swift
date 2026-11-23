import Foundation

/// The Remembrances that ship with the app.
public enum BuiltInList {
    public static let all: [Remembrance] = [
        Remembrance(id: "subhanallah-wa-bihamdihi", kind: .zikr,
                    arabic: "سُبْحَانَ اللهِ وَبِحَمْدِهِ",
                    meaning: "Glory be to Allah, and praise be to Him.",
                    source: "Bukhari 6405"),
        Remembrance(id: "alhamdulillah", kind: .zikr,
                    arabic: "الْحَمْدُ لِلّٰهِ",
                    meaning: "All praise is for Allah.",
                    source: "Muslim 223"),
    ]
}
