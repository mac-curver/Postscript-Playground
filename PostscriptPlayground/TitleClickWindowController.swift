////
//  PostscriptPlayground
//  TitleClickWindow
//
//  Created by LegoEsprit on 16.10.26.
//  Copyright (c) 2025 LegoEsprit
//

import AppKit
/*
class TitleClickWindowController: NSWindowController {
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func windowDidLoad() {
            //super.append({
                // Überwacht Klicks auf das gesamte Fenster
                NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                    guard let window = self?.window, event.window == window else { return event }
                    
                    // Wandle den Klick-Punkt in das Koordinatensystem der ContentView um
                    let point = window.contentView?.convert(event.locationInWindow, from: nil)
                    
                    // Wenn der Klick außerhalb der ContentView, aber im Fenster liegt, war es die Titelleiste
                    if let point = point, window.contentView?.bounds.contains(point) == false {
                        print("Titelleiste wurde angeklickt!")
                    }
                    return event
                }
            //}())
        }


    
}
 */
