//
//  UserDefaultColorExtension.swift
//  Postscript Playground
//
//  Created by LegoEsprit on 30.01.24.
//

import Cocoa

extension UserDefaults {
	
	func set(color aColor: NSColor, forKey aKey: String) {
		do {
			let theData: NSData = try NSKeyedArchiver.archivedData(
				withRootObject: aColor, requiringSecureCoding: false
			) as NSData
			set(theData, forKey:aKey)
		}
		catch {
			
		}
	}
	
	func color(forKey aKey: String) -> NSColor {
		var theColor: NSColor? = nil
		if let theData = data(forKey: aKey) {
			do {
				theColor = try NSKeyedUnarchiver.unarchivedObject(
					ofClass: NSColor.self, from: theData
				)
			}
			catch {
				
			}
		}
		return theColor ?? NSColor.red
	}
	
}

