//
//  Deprecations.swift
//  Postscript Playground
//
//  Created by legoesprit on 10.02.24.
//
//	Hopefully this allows to run the app on older systems!

import Cocoa
import os.log
import Foundation

extension URL {
	var myPath: String {
		get {
			if #available(macOS 13.0, *) {
				return path(percentEncoded: false)
				//return relativePath
			}
			else {
				return path
			}
		}
	}
}


extension Process {
	
	func launchOrRun() {
		if #available(macOS 10.13, *) {
			do {
				try self.run()
			}
			catch {
				Logger.write("Unix tool was not executed!")
			}
		}
		else {
			self.launch()
		}
	}

}
