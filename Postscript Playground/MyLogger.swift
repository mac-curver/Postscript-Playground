//
//  MyLogger.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 06.05.23.
//
//                        , file: URL = URL(string: #file) -> MyLogger !!!
/*
> Examples on how to retrieve the log info from "Console" log files:
 
sudo log stream --predicate 'subsystem == <Bundle Identifier>'
sudo log stream --predicate 'subsystem == <Bundle Identifier>' | awk '{print $0}'
sudo log show --predicate 'subsystem == <Bundle Identifier>' --last 1h
sudo log show --predicate 'subsystem == <Bundle Identifier>' --last 1h | awk 'NR>2 {print substr($0,12,15) " T:" substr($0,index($0,"00 ")+3, 8)  substr($0, index($0,"]")+1) }'
sudo log stream --predicate 'subsystem == <Bundle Identifier>' | awk 'NR>2 {print substr($0,12,15) " T:" substr($0,index($0,"00 ")+3, 8)  substr($0, index($0,"]")+1) }'
*/

import os.log
import Foundation


/// How to use
///
///         Logger.login("In-Message"[, className: className])                  // Increases indent
///         ...
///         Logger.logout("Out-Message"[, className: className])                // Decreases indent
///
///         Logger.write("Write-Message"[, className: className])               // write message
///  usage of [, className: className] is optional, but recommended to extract
///  the class (I could not identify a method to retrieve the class name by
///  other means).
///
///  Comments:
///  =========
///  Contrary to Apple's intend I am using "privacy: .public", as otherwise
///  you will only get useless log files filled with <private> like:
///
/// ╭╴ ViewController.saveAndConvert(_:), <private>
/// | <private>PsEditView.saveFileToPsUrl(), <private>
/// | <private>PsEditView.saveFileToPsUrl(), <private>
/// | <private>PsEditView.saveFileToPsUrl(), <private>
/// | ╭╴ PsEditView|saveFileTo(path:), <private>
/// | ╰╴ PsEditView|saveFileTo(path:), <private>
/// | ╭╴ ViewController.convertPsToPdf(), <private>
/// | | <private>Shell.init(_:arguments:), <private>
/// | ╰╴ ViewController.convertPsToPdf(), <private>
/// ╰╴ ViewController.saveAndConvert(_:), <private>
///
/// . It is even not possible to control the privacy setting via a parameter. Therefore please
///  don't use this Logger for security senitive information. (See  "OSLogPrivacy.public")
///
///
///#if DEBUG
///Logger.write("I'm running in DEBUG mode")
///#else
///Logger.write("I'm not running in DEBUG mode")
///#endif

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    static var fill: String = ""                                                // This should be thread save as we change it only on main thread
    
    static let main = Logger(subsystem: subsystem, category: "")
    static let debugLevel = OSLogType.debug                                     // This will not be added to Console log unless configuration has been changed
    /*
     debug: OSLogType
     info: OSLogType
     default: OSLogType -> notice
     error: OSLogType
     fault: OSLogType
     */
    
    /// Generates a name from either classname or file name
    /// - Parameters:
    ///   - className: className or empty string
    ///   - file: filename of the sender
    /// - Returns: if classname is given return "<class>." otherwise "<filename>|"
    static func name(className: String
                    , file: String
    ) -> String {
        if className.isEmpty {
            // extracting the filename part only. Unfortunately we can't use
            // URL(filepath: file) here as it will allways return "MyLogger"
            return "\(file.split(separator: "/").last!.split(separator: ".").first!)|"
        }
        else {
            // as the app name is redundant we only use the last part
            return "\(className.split(separator: ".").last!)."
        }
    }
    
    /// Writes log message to console file
    /// - Parameters:
    ///   - className: The retrieved class name
    ///   - file: Alternatively the file name
    ///   - thread: Either "T" for dispatched thread, blank or plus/minus indent
    ///   - function: Name of the calling function
    ///   - message: The debug message
    fileprivate static func privateLog(level: OSLogType = debugLevel
                                       , className: String
                                       , file: String
                                       , thread: String
                                       , function: StaticString
                                       , _ message: String
    ) {
        let name = name(className: className, file: file)
        
        #if DEBUG
        let myLevel = OSLogType.default
        #else
        let myLevel = level
        #endif

        Logger.main.log(level: myLevel,
                        //  v--- must be all at same column!
                        """
                        \(fill, privacy: .public)\
                        \(thread)\(name, privacy: .public)\
                        \(function, privacy: .public),\
                         \(message, privacy: .public)
                        """
                        //  ^--- must be all at same column!
        )
        
    }

    
    /// Writes message to log file keeping the level
    /// - Parameters:
    ///   - message: Message to be written to console
    ///   - level: Optional level default to 'notice'
    ///   - className: Optional classname if given this name is added in front of function
    ///   - file: Optional filename used for the name if no filename is given - defaults to #file
    ///   - function: Optional method name - defaults to #function
    ///   - line: Optional line number - defaults to #line
    static func write(_ message: String
                      , level: OSLogType = debugLevel
                      , className: String = ""
                      , file: String = #file
                      , function: StaticString = #function
                      //, line: UInt = #line
                ) {
        
        let thread = Thread.isMainThread ? " " : "T"
        privateLog(level: level
                   , className: className
                   , file: file
                   , thread: thread
                   , function: function
                   , message
        )
    }
    
    
    /// Increases the log level indent
    /// - Parameters:
    ///   see write
    static func login(_ message: String
                      , level: OSLogType = debugLevel
                      , className: String = ""
                      , file: String = #file
                      , function: StaticString = #function
                      //, line: UInt = #line
                ) {
        let thread = Thread.isMainThread ? "╭╴" : "T"
        privateLog(level: level
                   , className: className
                   , file: file
                   , thread: thread
                   , function: function
                   , message
        )
        if Thread.isMainThread {
            fill += "│ "
        }
    }
    
    /// Decreases the log level indent
    /// - Parameters:
    ///   see write
    static func logout(_ message: String
                       , level: OSLogType = debugLevel
                       , className: String = ""
                       , file: String = #file
                       , function: StaticString = #function
                       //, line: UInt = #line
                ) {
        if Thread.isMainThread {
            if fill.count >= 2 {
                fill.removeLast(2)
            }
        }
        let thread = Thread.isMainThread ? "╰╴" : "T"
        privateLog(level: level
                   , className: className
                   , file: file
                   , thread: thread
                   , function: function
                   , message
        )
    }
    
}
