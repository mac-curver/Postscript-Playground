////
//  PostscriptPlayground
//  MenuExtension
//
//  Created by LegoEsprit on 25.10.26.
//  Copyright (c) 2025 LegoEsprit
//

import Cocoa

extension NSMenu {
    
    /// Convenience for addItem with explicit setting of the target
    /// - Parameters:
    ///   - title: Item title
    ///   - action: Menu item action as Selector
    ///   - target: Target of the selector
    ///   - symbol: MenuItem symbol from SFSymbols
    ///   - key: Key equivalent or nothing
    ///  Adds the menu item with title to the given menu. Setting the target explicitly is
    ///  required for example for the "printView" selector
    func addItem(_ title: String
                 , action: Selector?
                 , with target: AnyObject?
                 , symbol: NSImage? = nil
                 , key: String = "")
    {
        let addedItem = NSMenuItem(
            title: title
            , action: action
            , keyEquivalent: key
        )
        addedItem.target = target
        addedItem.image = symbol
        addItem(addedItem)
    }

}
