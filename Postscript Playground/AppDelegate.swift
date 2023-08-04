//
//  AppDelegate.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 25.03.23.
//
// Minimum Deployment version set to 13.0 as otherwise Combobox is not available
// Sandboxing not possible as on client systems the ps..pdf converters
// can't be called. Yields ->"Invalid launch path" always!
//
/*
sudo log stream --predicate 'subsystem == "de.LegoEsprit.Postscript-Playground"' | awk 'NR>2 {print substr($0,12,15) " T:" substr($0,index($0,"00 ")+3, 8)  substr($0, index($0,"]")+1) }'
*/

import os.log
import Cocoa




@main
/// AppDelegate as responder to os events
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    @IBOutlet weak var viewController: ViewController!
        
    
    /// Called when opening the app by file click
    /// - Parameters:
    ///   - application: Ignored
    ///   - urls: Only last url is being taken
    func application(_ application: NSApplication, open urls: [URL]) {
        Logger.login("app started \(application.debugDescription)", level: OSLogType.default, className: className)

        viewController.openAndConvert(urls)
        
        Logger.logout("", level: OSLogType.default, className: className)
    }
    
    func application(_ application: NSApplication, openFile: String) -> Bool {
        Logger.login("app started \(application.debugDescription)", level: OSLogType.default, className: className)
        
        Logger.logout("app started \(application.debugDescription)", level: OSLogType.default, className: className)

        return true
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Never called ?
        return true
    }

        
    func applicationDidFinishLaunching(_ aNotification: Notification) {
#if DEBUG
        /// Testing Console message levels
        Logger.write("Testing: Info", level: OSLogType.info, className: className)
        Logger.write("Testing: Debug", level: OSLogType.debug, className: className)
        Logger.write("Testing: Default", level: OSLogType.`default`, className: className)
        Logger.write("Testing: Error", level: OSLogType.error, className: className)
        Logger.write("Testing: Fault", level: OSLogType.fault, className: className)
#endif
        viewController.didFinishLaunching(appDelegate: self)
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        viewController.checkForChanges()

        Logger.write("====================", level: OSLogType.info, className: className)
    }
    
    
    /// It just one window and file
    /// - Parameter sender: Ignored
    /// - Returns: Allways YES
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    

}

