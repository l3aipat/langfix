import Testing
@testable import LangFixCore

struct WordSet: Lexicon {
    let english: [String]
    let thai: [String]

    func isPrefix(_ text: String, in language: Language) -> Bool {
        (language == .english ? english : thai).contains { $0.hasPrefix(text) }
    }
}

let lexicon = WordSet(english: ["hello", "help", "the"], thai: ["สวัสดี", "แมว", "ทำ"])

func typeAll(_ text: String, in language: Language, _ corrector: inout Corrector) -> [Correction] {
    text.unicodeScalars.compactMap { corrector.type($0, in: language) }
}

func onThaiLayout(_ english: String) -> String {
    Keyboard.text(english.unicodeScalars.map { Keyboard.position(of: $0, in: .english)! }, in: .thai)
}

@Test func englishTypedOnThaiLayoutIsConverted() {
    var corrector = Corrector(lexicon: lexicon)
    let typed = onThaiLayout("hello")
    #expect(typed == "้ำสสน")
    #expect(typeAll(typed, in: .thai, &corrector) == [Correction(deleteCount: 2, insert: "hel", switchTo: .english)])
}

@Test func thaiTypedOnEnglishLayoutIsConverted() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("l;ylfu", in: .english, &corrector) == [Correction(deleteCount: 2, insert: "สวั", switchTo: .thai)])
}

@Test func thaiCombiningMarksCountAsOneKeyEach() {
    var corrector = Corrector(lexicon: WordSet(english: ["the"], thai: []))
    let typed = onThaiLayout("the")
    #expect(typed.count < typed.unicodeScalars.count, "fixture must contain a combining mark")
    #expect(typeAll(typed, in: .thai, &corrector) == [Correction(deleteCount: 2, insert: "the", switchTo: .english)])
}

@Test func correctWordIsLeftAlone() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("hello", in: .english, &corrector).isEmpty)
}

@Test func garbageInBothLayoutsIsLeftAlone() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("qqqzzz", in: .english, &corrector).isEmpty)
}

@Test func settledWordIsNotCorrectedAgainBeforeBoundary() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("xyz", in: .english, &corrector).isEmpty)
    #expect(typeAll("l;y", in: .english, &corrector).isEmpty)
    corrector.boundary()
    #expect(typeAll("l;y", in: .english, &corrector).count == 1)
}

@Test func backspaceRemovesKeyFromWord() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("lx", in: .english, &corrector).isEmpty)
    _ = corrector.backspace()
    #expect(typeAll(";y", in: .english, &corrector).count == 1)
}

@Test func backspacePastWordStartStopsWatching() {
    var corrector = Corrector(lexicon: lexicon)
    _ = corrector.backspace()
    #expect(typeAll("l;y", in: .english, &corrector).isEmpty)
}

@Test func unmappedCharacterStopsWatching() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("él;y", in: .english, &corrector).isEmpty)
}

@Test func backspaceRightAfterCorrectionRestoresWhatWasTyped() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("l;y", in: .english, &corrector).count == 1)
    #expect(corrector.backspace() == Correction(deleteCount: 3, insert: "l;y", switchTo: .english))
    #expect(typeAll("l", in: .english, &corrector).isEmpty)
}

@Test func undoneWordIsNeverCorrectedAgain() {
    var corrector = Corrector(lexicon: lexicon)
    _ = typeAll("l;y", in: .english, &corrector)
    _ = corrector.backspace()
    corrector.boundary()
    #expect(typeAll("l;ylfu", in: .english, &corrector).isEmpty)
    #expect(corrector.ignored == [IgnoredWord(text: "l;y", language: .english)])
}

@Test func ignoredWordOnlyAppliesToItsLanguage() {
    var corrector = Corrector(lexicon: lexicon, ignored: [IgnoredWord(text: "l;y", language: .thai)])
    #expect(typeAll("l;y", in: .english, &corrector).count == 1)
}

@Test func backspaceAfterTypingOnPastCorrectionIsAPlainBackspace() {
    var corrector = Corrector(lexicon: lexicon)
    _ = typeAll("l;y", in: .english, &corrector)
    #expect(typeAll("ส", in: .thai, &corrector).isEmpty)
    #expect(corrector.backspace() == nil)
    #expect(corrector.ignored.isEmpty)
}

@Test func forgettingIgnoredWordsRestoresCorrection() {
    var corrector = Corrector(lexicon: lexicon, ignored: [IgnoredWord(text: "l;y", language: .english)])
    corrector.forgetIgnored()
    #expect(typeAll("l;y", in: .english, &corrector).count == 1)
}
