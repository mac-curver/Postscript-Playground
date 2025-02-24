//
//  NSWindowExtension.swift
//  Postscript Playground
//
//  Created by LegoEsprit on 23.02.25.
//

import AppKit


/// Can be used to load multiple nib files!
extension NSWindow {
    
    /// Load HelpWindow from nib
    /// - Parameter name: Name of the xib without .xib extension or ""
    /// - Returns: Instance to a HelpWindow loaded from resource
    /// If name is empty it is assumed, that the xib file carries the same name as the class itself
    static func loadFromNib(with name: String = "") -> Self? {
        var topLevelArray: NSArray?
        
        let bundle = Bundle.main
        if name.isEmpty {
            bundle.loadNibNamed(String(describing: Self.self), owner: nil
                                , topLevelObjects: &topLevelArray
            )
        }
        else {
            bundle.loadNibNamed(name, owner: nil
                                , topLevelObjects: &topLevelArray
            )
        }
        guard let results = topLevelArray else { return nil }
        let result = Array<Any>(results).filter { $0 is Self }
        
        return result.last as? Self
    }
    
}
