//
//  Shell.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 06.04.23.
//  Don't forget to set Target Membership for the file
//

import os.log
import Foundation

/*
class InputPipe: Pipe {
    
    override var fileHandleForReading: FileHandle { get { return NSData("test")} }

}
*/

/// Used to launch a shell script
class Shell {
    
    
    var stdout: String                                                          ///< Content of the output Pipe
    var stderr: String                                                          ///< Content of the error Pipe
    
    /// init to initialize the `String`s taking standard output and standard
    /// error from the pipe
    
    /// Initializes the variables
    init() {
        stdout = ""
        stderr = ""
    }


    /// init the shell and launch it as a task
    ///
    /// - parameter launchPath: The `String` path for the executable file.
    /// - parameter arguments:	An array of [`String`] used as parameters for the executable file.

    init(_ launchPath: String, arguments: [String])  {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
		Logger.write("\(launchPath)", className: " Shell")
		Logger.write("(\(arguments))", className: " Shell")

        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        stdout = String(data: data, encoding: String.Encoding.utf8) ?? ""
        stderr  = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
        
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


