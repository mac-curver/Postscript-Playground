//
//  AppDelegate.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 25.03.23.
//
// Minimum Deployment version set to 13.0 as otherwise Combobox is not available
// Sandboxing not possible as on client systems the ps to pdf converters
// can't be called. Yields always ->"Invalid launch path" !
//
/*
sudo log stream --predicate 'subsystem == "de.LegoEsprit.Postscript-Playground"' | awk 'NR>2 {print substr($0,12,15) " T:" substr($0,index($0,"00 ")+3, 8)  substr($0, index($0,"]")+1) }'
*/
// Some missing constraints warnings are accepted as otherwise I could not
// collapse the psEditView by hiding the controls in the status line.
// The NSUnarchiver warning could be removed by using the ColorTransformer
// class, but using the NSSecureUnarchiver makes the preference unreadable
// for humans.

import os.log
import Cocoa


@main
/// AppDelegate as responder to os events.
/// ```
/// Main interface to IB
/// ```
/// > Warning: Not yet completely localized
class AppDelegate: NSObject, NSApplicationDelegate {
	
	/// The main view controller for the edit, pdf display and setting the preferences.
    @IBOutlet weak var viewController: ViewController!
	
	/// Opens a menu with some sample files to try the PostScript conversion.
	@IBOutlet weak var exampleMenu: NSMenu!										//< Moved to here to allow menu access even if window was closed
	/// Allows to acces the most recent .ps files used.
	@IBOutlet weak var recentMenu: NSMenu!										//<
	
	/// Used to copy the file names, when opening from Finder.
	var urlsToOpenAfterLaunch:[URL] = []
	/// Doortrap to wait opening the file until xib was loaded and displayed.
	var finishedLaunching = false
	
	/// Remove all items from recent menu except the last.
	/// - Parameter sender: Menuitem sending the event, but not used
	///
	/// Unfortunately I failed to used the build in recent menu behaviour. Therefore I
	/// mimic it here manually.
	@IBAction func clearRecentMenu(_ sender: NSMenuItem) {
		let clearItem = recentMenu.items.last
		recentMenu.removeAllItems()
		recentMenu.addItem(clearItem!)
	}
	

    

    /// Called when opening the app by file click
    /// - Parameters:
    ///   - application: Ignored
    ///   - urls: Only first url is being taken
	///   ```
	///   At the first run this routine is being called before the xib
	///   is being loaded. Therefore we memorize the given urls and we
	///   open the file after the xib has been loaded. When this was done
	///   for the first time we directly open the file as otherwise it
	///   might happen, that we mix up the files!
	///   ```
    func application(_ application: NSApplication, open urls: [URL]) {
		
        Logger.login("""
					app started1 \(application.debugDescription) \
					with: \(urls)
					"""
					 , level: OSLogType.default
					 , className: className
		)
		if finishedLaunching {
			urlsToOpenAfterLaunch = []
			if !urls.isEmpty {
				viewController.openAndConvert(urls)
			}
		}
		else {
			urlsToOpenAfterLaunch = urls										/// Delay opening until launched
		}

        Logger.logout("app started1", level: OSLogType.default, className: className)
    }

	
	/// Responder when opening a file not really used?!
	/// - Parameters:
	///   - application: Filled in by the system
	///   - openFile: The file to be opened
	/// - Returns: true allways
    func application(_ application: NSApplication, openFile: String) -> Bool {
        Logger.login("app started2 \(application.debugDescription) with: \(openFile)", level: OSLogType.default, className: className)
        
        Logger.logout("app started2 \(application.debugDescription)", level: OSLogType.default, className: className)
        return true
    }
	

	
	/// Called when clicking on app icon in Finder bar and no window is open!
	/// - Parameter sender: Filled in by the system
	/// - Returns: true allways
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        return true
    }

	
	/// Called after IB was loaded.
	/// We do some initial settings and tests here.
	/// - Parameter aNotification: Currently not in use
    func applicationDidFinishLaunching(_ aNotification: Notification) {
		Logger.login("Version: \(viewController.version())", className: className)
#if DEBUG
        /// Testing Console message levels
        Logger.write("Testing: Info", level: OSLogType.info, className: className)
        Logger.write("Testing: Debug", level: OSLogType.debug, className: className)
        Logger.write("Testing: Default", level: OSLogType.`default`, className: className)
        Logger.write("Testing: Error", level: OSLogType.error, className: className)
        Logger.write("Testing: Fault", level: OSLogType.fault, className: className)
		
		Logger.write("Testing: Info", level: OSLogType.info, className: String(describing: type(of: self)))
		Logger.write("Testing: Debug", level: OSLogType.debug, className: String(describing: type(of: self)))
		Logger.write("Testing: Default", level: OSLogType.`default`, className: String(describing: type(of: self)))
		Logger.write("Testing: Error", level: OSLogType.error, className: String(describing: type(of: self)))
		Logger.write("Testing: Fault", level: OSLogType.fault, className: String(describing: type(of: self)))

#endif

		ColorValueTransformer.register()
		buildSampleMenu()

		let preferences = UserDefaults.standard //NSUserDefaultsController().defaults

		recentMenu.retrieveItems(
									  preferences: preferences
									, for: #selector(openRecentFile)
								 )

        viewController.didFinishLaunching(appDelegate: self)
		
		//_ = SyntaxTest()
		finishedLaunching = true

		Logger.logout("", className: className)
    }
	
	/// Allways called when app becomes active.
	/// - Parameter aNotification: Currently not in use
	func applicationWillBecomeActive(_ aNotification: Notification) {
		Logger.login("Version: \(viewController.version())"
					 , className: className
		)
		/// Opening is executed only the very first time!
		if !urlsToOpenAfterLaunch.isEmpty {
			viewController.openAndConvert(urlsToOpenAfterLaunch)
			urlsToOpenAfterLaunch = []
		}
		Logger.logout("", className: className)
	}


	
	/// Called just before application terminates.
	/// Used to check if latest changes require to be saved and to print the profile result.
	/// - Parameter aNotification: Currently not used
    func applicationWillTerminate(_ aNotification: Notification) {
		viewController.closeWindow()
		
		recentMenu.storeItems(preferences: UserDefaults.standard)

		profile.print()
        Logger.write("====================", level: OSLogType.info
					 , className: className
		)
    }
    
    
    /// If just one window and file.
    /// - Parameter sender: Ignored
    /// - Returns: Allways NO // YES
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
	
	/// Open a sample file from the menu.
	/// - Parameter sender: Menu item used to retrieve the name of the example file.
	@objc func openSampleFile(sender: NSMenuItem) {
		viewController.openSampleFile(sender: sender)
	}
	
	/// Open recent file from recent menu.
	/// - Parameter sender: Menu item to retrieve the recent file.
	@objc func openRecentFile(sender: NSMenuItem) {
		viewController.openRecentFile(sender: sender)
	}
	
	
	/// Add url from file to recent menu.
	/// This is a bit tricky due to sandbox and UAC limitations.
	/// - Parameter resultUrl: Url of the file to be stored
	/// - Returns: true normally, but false when bookmarking (UAC) fails.
	func addRecentItem(url resultUrl: URL) -> Bool {
		var result = false
		do {
			let bookmarkData = try resultUrl.bookmarkData(
				options:[.withSecurityScope]
			)
			recentMenu.addRecentMenuItem(
				pdfUrl: viewController.pdfView.pdfUrl
				, psData: bookmarkData
				, for: #selector(openRecentFile)
			)
			result = true
		}
		catch {
			Logger.write("Bookmarking failed: \(error)"
						 , level: OSLogType.default
						 , className: className
			)
		}
		return result
	}

	
	/// Build example file menu from the .ps files inside the bundle.
	fileprivate func buildSampleMenu() {
		/// Build sample menu
		let pathes = Bundle.main.paths(forResourcesOfType: "ps"
									   , inDirectory: "."
		             )
		for path in pathes {
			let fileNameComponents = path.split(separator: "/")
			let fileName = String(fileNameComponents.last ?? "")
			if !fileName.isEmpty {
				let item = exampleMenu.addItem(withTitle: fileName
											, action: #selector(openSampleFile)
											, keyEquivalent: ""
				            )
				Logger.write(item.title, className: className)
			}
			
		}
		//exampleMenu.autoenablesItems = false
	}

    

}

