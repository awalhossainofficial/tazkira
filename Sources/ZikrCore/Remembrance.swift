import Foundation

/// One piece of text to recite: a Zikr, a Dua or a Durood.
public struct Remembrance: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable {
        case zikr = "Zikr"
        case dua = "Dua"
        case durood = "Durood"
    }

    public let id: String
    public let kind: Kind
    public let arabic: String
    public let transliteration: String
    public let meaning: String
    public let source: String

    public init(id: String, kind: Kind, arabic: String, transliteration: String, meaning: String, source: String) {
        self.id = id
        self.kind = kind
        self.arabic = arabic
        self.transliteration = transliteration
        self.meaning = meaning
        self.source = source
    }
}
