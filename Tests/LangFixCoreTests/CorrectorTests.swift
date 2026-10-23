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

func typeAll(_ text: String, in language: Language, _ corrector: inout Corrector, rules: Rules = Rules()) -> [Correction] {
    text.unicodeScalars.compactMap { corrector.type($0, in: language, rules: rules) }
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
    #expect(corrector.backspace() == Undo(
        correction: Correction(deleteCount: 3, insert: "l;y", switchTo: .english),
        learned: IgnoredWord(text: "l;y", language: .english)))
    #expect(typeAll("l", in: .english, &corrector).isEmpty)
}

@Test func learnedWordIsNeverCorrectedAgain() {
    var corrector = Corrector(lexicon: lexicon)
    _ = typeAll("l;y", in: .english, &corrector)
    let undo = corrector.backspace()!
    corrector.boundary()
    let rules = Rules(ignored: [undo.learned])
    #expect(typeAll("l;ylfu", in: .english, &corrector, rules: rules).isEmpty)
}

@Test func ignoredWordOnlyAppliesToItsLanguage() {
    var corrector = Corrector(lexicon: lexicon)
    let rules = Rules(ignored: [IgnoredWord(text: "l;y", language: .thai)])
    #expect(typeAll("l;y", in: .english, &corrector, rules: rules).count == 1)
}

@Test func backspaceAfterTypingOnPastCorrectionIsAPlainBackspace() {
    var corrector = Corrector(lexicon: lexicon)
    _ = typeAll("l;y", in: .english, &corrector)
    #expect(typeAll("ส", in: .thai, &corrector).isEmpty)
    #expect(corrector.backspace() == nil)
}

@Test func lowerMinimumLengthCorrectsSooner() {
    var corrector = Corrector(lexicon: WordSet(english: [], thai: ["นะ"]))
    #expect(typeAll("ot", in: .english, &corrector).isEmpty)
    corrector.boundary()
    #expect(typeAll("ot", in: .english, &corrector, rules: Rules(minimumLength: 2))
        == [Correction(deleteCount: 1, insert: "นะ", switchTo: .thai)])
}

@Test func higherMinimumLengthWaitsLonger() {
    var corrector = Corrector(lexicon: lexicon)
    #expect(typeAll("l;y", in: .english, &corrector, rules: Rules(minimumLength: 4)).isEmpty)
    #expect(typeAll("l", in: .english, &corrector, rules: Rules(minimumLength: 4)).count == 1)
}

@Test func selectionTypedOnEnglishLayoutConvertsToThai() {
    #expect(Keyboard.convert("mflv[")! == ("ทดสอบ", .thai))
}

@Test func selectionTypedOnThaiLayoutConvertsToEnglish() {
    #expect(Keyboard.convert("้ำสสน")! == ("hello", .english))
}

@Test func selectionKeepsSpacesAndLineBreaks() {
    #expect(Keyboard.convert("w,j mflv[\nfu")! == ("ไม่ ทดสอบ\nดี", .thai))
}

@Test func selectionWithoutLettersIsNotConverted() {
    #expect(Keyboard.convert("  \n") == nil)
}
