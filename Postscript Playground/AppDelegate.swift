//
//  AppDelegate.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 25.03.23.
//
// Minimum Deployment version set to 13.0 as otherwise Combobox is not available
// Sandboxing not possible as on client systems the ps..pdf can't be called->"Invalid launch path"
//

// sudo log stream --predicate 'subsystem == "de.LegoEsprit.Postscript-Playground"' | awk 'NR>2 {print substr($0,12,15) " T:" substr($0,index($0,"00 ")+3, 8)  substr($0, index($0,"]")+1) }'

import os.log
import Cocoa




@main
/// AppDelegate as responder to os events
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var viewController: ViewController!
        
    
    /// Called when opening the app by file click
    /// - Parameters:
    ///   - application: Ignored
    ///   - urls: Only last url is being taken
    func application(_ application: NSApplication, open urls: [URL]) {
        Logger.login("app started \(application.debugDescription)", className: className)

        viewController.openAndConvert(urls)
        
        Logger.logout("", className: className)
    }
    
    func application(_ application: NSApplication, openFile: String) -> Bool {
        Logger.login("app started \(application.debugDescription)", className: className)
        
        Logger.logout("app started \(application.debugDescription)", className: className)

        return true
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }

        
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        viewController.didFinishLaunching()
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        viewController.checkForChanges()

        Logger.write("====================", className: className)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    /// It just one window and file
    /// - Parameter sender: Ignored
    /// - Returns: Allways YES
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    

}

