//
//  Deprecations.swift
//  Postscript Playground
//
//  Changed by LegoEsprit 2024-12-27 New GIT version
//  Created by legoesprit on 10.02.24.
//
//	Hopefully this allows to run the app on older systems!

import Cocoa
import os.log
import Foundation

extension URL {
	/// Calls non deprecated path() if available
	var path_fallback: String {
		get {
			if #available(macOS 13.0, *) {
				return path(percentEncoded: false)
			}
			else {
				return path
			}
		}
	}
    
    static func create_fallback(path: String) -> URL {
        if #available(macOS 13.0, *) {
            return URL(filePath: path)
        }
        else {
            return URL(fileURLWithPath: path)
        }
    }
}


extension Process {
	
	/// Calls non deprecated run() if available
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

extension NSTextView {
	/// Calls scrollToEndOfDocument() if available, otherwise just scrolls
	/// - Parameter sender: Propagated to original method
	func scrollToEndOfDocumentALt(_ sender: Any?) {
		if #available(macOS 10.14, *) {
			scrollToEndOfDocument(sender)										//
		} else {
			scroll(NSPoint(x: 0, y: frame.height))								// after MAC OS 10.10
		}
	}
}

