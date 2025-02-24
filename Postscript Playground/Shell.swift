//
//  Shell.swift
//  SimplePsViewer
//
//  Changed by LegoEsprit 2024-12-27 New GIT version
//  Created by LegoEsprit on 06.04.23.
//  Don't forget to set Target Membership for the file
//

import os.log
import Foundation
import AppKit

/*
class InputPipe: Pipe {
    
    override var fileHandleForReading: FileHandle { get { return NSData("test")} }

}
*/

/// Used to launch a shell script
class Shell {
    
    
    var stdout: String = ""                                                         ///< Content of the output Pipe
    var stderr: String = ""                                                        ///< Content of the error Pipe
    
    /// init to initialize the `String`s taking standard output and standard
    /// error from the pipe
    
    /// Initializes the variables
    init() {
    }


    /// init the shell and launch it as a task
    ///
    /// - parameter launchUrl: The `URL` for the executable file.
    /// - parameter arguments:	An array of [`String`] used as parameters for the executable file.

    init(_ launchUrl: URL, arguments: [String])  {
        let task = Process()
		task.executableURL = launchUrl
        task.arguments = arguments
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
		do {
			try task.run()
			let data = pipe.fileHandleForReading.readDataToEndOfFile()
			let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
			stdout = String(data: data, encoding: String.Encoding.utf8) ?? ""
			stderr  = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
		}
		catch {
			Logger.write(error.localizedDescription)
			Logger.write("Unix tool was not executed!")
			let alertMessage = NSAlert()
			alertMessage.alertStyle = .critical
			alertMessage.messageText = "Unix tool was not executed!"
			alertMessage.informativeText = error.localizedDescription
			alertMessage.runModal()
		}
        
			
		

        
    }
    
    /*
     func inputShell(_ launchPath: String, arguments: [String]) -> (stdout: String, stderr: String) {
         let task = Process()
         task.launchPath = launchPath
         task.arguments = arguments

         let inputPipe = Pipe()
         let pipe = Pipe()
         let errorPipe = Pipe()
         
         task.standardInput = inputPipe
         task.standardOutput = pipe
         task.standardError = errorPipe
         task.launch()

         let data = pipe.fileHandleForReading.readDataToEndOfFile()
         let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
         let outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
         let errorString  = String(data: errorData, encoding: String.Encoding.utf8) ?? ""

         return (outputString, errorString)
     }

     */
   
}


