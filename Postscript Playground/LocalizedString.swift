//
//  LocalizedString.swift
//  Postscript Playground
//
//  Created by LegoEsprit on 22.02.25.
//

import AppKit


/// Attempt to create universal localized Strings even for older system, but not completed
struct LocalizedString {
    
    
    /// Resulting localized String (should be improved)
    var string: String
    
    /// Currently only the localization available with macOS12 and above is supported
    /// - Parameter text: Text to be translated
    /// One issue is, that text applied here is not automatically added to Localizable.xcstrings
    init(_ text: String) {
        if #available(macOS 12.0, *) {
            string = String(localized: String.LocalizationValue(text))
        }
        else {
            string = text
        }
    }
    
    /// Currently only the localization available with macOS12 and above is supported
    /// - Parameter text: Text to be translated
    /// One issue is, that text applied here is not automatically added to Localizable.xcstrings
    init(_ text: StaticString, defaultValue: String = "", comment: StaticString = "") {
        if #available(macOS 12.0, *) {
            string = String(localized: text
                            , defaultValue: String.LocalizationValue(defaultValue)
                            , comment: comment
            )
        }
        else {
            string = "\(text)" //LocalizedStringResource(text)
        }
    }

    
}
