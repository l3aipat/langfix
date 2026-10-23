import Carbon
@testable import LangFixCore

func systemCharacter(sourceID: String, keyCode: UInt16, shift: Bool) -> String? {
    let filter = [kTISPropertyInputSourceID as String: sourceID] as CFDictionary
    guard let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource],
          let source = sources.first,
          let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return nil }
    let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
    return data.withUnsafeBytes { bytes -> String? in
        let layout = bytes.bindMemory(to: UCKeyboardLayout.self).baseAddress!
        var dead: UInt32 = 0
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let modifiers: UInt32 = shift ? UInt32(shiftKey >> 8) : 0
        let status = UCKeyTranslate(layout, keyCode, UInt16(kUCKeyActionDown), modifiers,
                                    UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                    &dead, chars.count, &length, &chars)
        return status == noErr ? String(utf16CodeUnits: chars, count: length) : nil
    }
}

let sources: [(Language, String)] = [(.english, "com.apple.keylayout.ABC"), (.thai, "com.apple.keylayout.Thai")]
var mismatches = 0
for (language, sourceID) in sources {
    for (offset, shift) in [(0, false), (Keyboard.keyCodes.count, true)] {
        for (i, keyCode) in Keyboard.keyCodes.enumerated() {
            let expected = String(Keyboard.character(at: KeyPosition(index: offset + i), in: language))
            let actual = systemCharacter(sourceID: sourceID, keyCode: keyCode, shift: shift)
            if actual != expected {
                mismatches += 1
                print("\(sourceID) key \(keyCode) shift=\(shift): table \(expected) system \(actual ?? "nil")")
            }
        }
    }
}
print(mismatches == 0 ? "layout table matches system layouts (\(Keyboard.keyCount) keys x 2 layouts)" : "\(mismatches) mismatches")
exit(mismatches == 0 ? 0 : 1)
