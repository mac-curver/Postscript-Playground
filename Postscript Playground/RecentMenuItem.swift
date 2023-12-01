//
//  RecentMenuItem.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 06.04.23.
//
/// Description:
/// Overrides NSMenuItem for the recent menu to store the ps and the pdf
/// file pathes.
///
/// Usage:
/// the selecvtor must be implemented like
/// @objc fileprivate func openRecentFile(sender: NSMenuItem) {
///     if let item: RecentMenuItem = sender as? RecentMenuItem {
///         psTextView.url = item.psUrl
///         psTextView.pdfUrl = item.pdfUrl
///         ...
///     }
/// }
///
/// # Persist access to files with security-scoped URL bookmarks
/// Create bookmark data from a URL using
/// bookmarkData(options:includingResourceValuesForKeys:relativeTo:),
/// including the withSecurityScope option. Foundation creates a URL bookmark with an explicit security scope that your app can store, and retrieve to subsequently access the resource at the URL, regardless of whether your app exits between accesses. If your app doesn’t need to write to the file on subsequent access, include the securityScopeAllowOnlyReadAccess option.
/// To access the file, follow these steps:
/// Resolve the URL using init(resolvingBookmarkData:options:relativeTo:bookmarkDataIsStale:), including withSecurityScope in the options.
/// If the Boolean value returned in bookmarkDataIsStale is true, then recreate the bookmark using bookmarkData(options:includingResourceValuesForKeys:relativeTo:) and update your app’s stored version of the bookmark.
/// Call startAccessingSecurityScopedResource() on the resolved URL.
/// Use the file at the resolved URL.
/// Call stopAccessingSecurityScopedResource() on the resolved URL.
///
///
/// 

import os.log
import Cocoa

/// Structure to remember the name and the bookmark for files that have been opened before
struct MenuItem: Codable {
    var pdfUrl: URL = URL(fileURLWithPath: "")                                  ///< remember the pdf path
    var secureData: Data = Data()                                               ///< remember the ps path as secure bookmark
}
  


/// Required to implement the recent functionality
extension NSMenu {
    
    /// Add item to recent menu
    /// - Parameters:
    ///   - pdfUrl: Url for the PDF file
	///   - psData:
    ///   - selector: Selector to be called
    func addRecentMenuItem(pdfUrl: URL, psData: Data, for selector: Selector?) {
        // I can't get it done automatically, what was that I assumed!
        
        // remove item title if it exists already
        do {
            var isStale = true
			var generatedPsUrl = pdfUrl.deletingPathExtension()
			generatedPsUrl.appendPathExtension("ps")
			
			if FileManager.default.fileExists(atPath: generatedPsUrl.path) {
				let menuItemUrl = try URL(
					resolvingBookmarkData: psData,
					options: [.withSecurityScope],
					relativeTo: nil,
					bookmarkDataIsStale: &isStale
				)
				if isStale {
					Logger.write("Bookmark is stale!", level: OSLogType.error, className: className)
					/// On return, if YES, the bookmark data is stale.
					/// Your app should create a new bookmark using the returned URL and use
					/// it in place of any stored copies of the existing bookmark.
					/// Fortunately this never happened?!
				}
				
				if let oldItem = self.item(withTitle: menuItemUrl.path) {
					self.removeItem(oldItem)
				}
				let item = RecentMenuItem(  ps: menuItemUrl
										  , pdf: pdfUrl
										  , psData: psData
										  , action: selector
				)
				self.insertItem(item, at:0)
			}
			else {
				Logger.write("\(generatedPsUrl.path) does not exist")
			}
        }
        catch {
            Logger.write("An issue occured", level: OSLogType.error, className: className)
        }

    }
    
    /// Stores the menu items with bookmarks to the preferences
    /// - Parameter preferences: Access to the preferences
    func storeItems(preferences: UserDefaults) {
        var key = 0
        preferences.set(self.items.count - 1, forKey: "RecentItemCount")
        let encoder = PropertyListEncoder()
        for item in self.items {
            if let recentMenuItem = item as? RecentMenuItem {
                do {
                    let data = try encoder.encode(recentMenuItem.menuItem)
                    preferences.set(data, forKey: "RecentItem\(key)")
                }
                catch {
                    // we just ignore the item
                }
            }
            key += 1
        }
        preferences.set("1.0.3", forKey: "Version")
    }
    
    /// Retrieves the menu items with bookmarks to the preferences and fills up the recent menu
    /// - Parameters:
    ///   - preferences: Access to the preferences file
    ///   - selector: Call back for the recent menu item
    func retrieveItems(preferences: UserDefaults, for selector: Selector?) {
        
        // (lldb) po NSHomeDirectory()
        // /Users/hj/Library/Containers/de.LegoEsprit.SimplePsViewer/Data/Library/Preferences
        
        Logger.write(preferences.string(forKey: "Version") ?? "Undefined"
                     , level: OSLogType.default, className: className
        )
        let count = preferences.integer(forKey: "RecentItemCount")
            
        let decoder = PropertyListDecoder()
		
		
        for key in 0..<count {
            if let itemData = preferences.data(forKey: "RecentItem\(key)") {
                do {
                    let item = try decoder.decode(MenuItem.self, from: itemData)
                    addRecentMenuItem(
						pdfUrl: item.pdfUrl
						, psData: item.secureData
						, for: selector
                    )
                }
                catch {
                    // nothing added in case item is wrong
                }
            }
        }
    }
}

/// Helps to implement recent menu item by storing the file name and the name of the pdf.
class RecentMenuItem: NSMenuItem {
    
    var menuItem: MenuItem = MenuItem()
    
    /// Never called but compiler requires it
    /// - Parameter coder: Propagated to super but not used
    required init(coder: NSCoder) {
        /// Not even called, but super.init also required by compiler ?!
        super.init(coder: coder)
    }
    
    /// overwritten init
    ///
    /// - parameter newEditView: The `PsEditView` that uses the menu.
    /// - parameter pdfView:     The `ContextPdfView` that uses the menu.
    /// - parameter selector:    The `Selector?` to be executed foir the menu item.

    init(ps: URL, pdf: URL, psData: Data, action selector: Selector?) {
        super.init(title: ps.path, action: selector, keyEquivalent: "")
        menuItem.pdfUrl = pdf
        menuItem.secureData = psData
    }
    

}
