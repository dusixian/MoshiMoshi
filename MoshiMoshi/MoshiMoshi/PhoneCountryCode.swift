//
//  PhoneCountryCode.swift
//  MoshiMoshi
//
//  Store phone in DB as "(+1)6503348430". Parse to get country code and national number.
//

import Foundation

enum PhoneCountryCode {

    /// Stored format: "(+1)6503348430". Parse to get code and national number.
    static func parse(full: String) -> (code: String, national: String) {
        let trimmed = full.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("(+"),
              let closeParen = trimmed.firstIndex(of: ")") else {
            return ("+1", trimmed)
        }
        let code = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 1) ..< closeParen])
        let national = String(trimmed[trimmed.index(after: closeParen)...]).filter { $0.isNumber }
        return (code, national)
    }

    /// Build stored string: "(+1)6503348430"
    static func fullPhone(countryCode: String, national: String) -> String {
        let n = national.filter { $0.isNumber }
        if n.isEmpty { return "" }
        let code = countryCode.trimmingCharacters(in: .whitespaces)
        let normalized = code.hasPrefix("+") ? code : "+" + code.filter { $0.isNumber }
        if normalized.isEmpty { return n }
        return "(\(normalized))\(n)"
    }
}
