//
//  MyLogger.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 06.05.23.
//
//                        , file: URL = URL(string: #file) -> MyLogger !!!
/*
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
///         Logger.login("In-Message"[, className: className])                  // Increases ident
///         ...
///         Logger.logout("Out-Message"[, className: className])                // Decreases ident
///
///         Logger.write("Write-Message"[, className: className])               // write message
///  usage of [, className: className] is optional, but recommended to extract
///  the class.
///
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    static var fill: String = ""
    
    static let main = Logger(subsystem: subsystem, category: "")
    static let defaultLevel = OSLogType.default
    /*
     debug: OSLogType
     info: OSLogType
     default: OSLogType -> notice
     error: OSLogType
     fault: OSLogType
     
     OSLogPrivacy.public
     */
    
    /// Generates a name from eith classname or file name
    /// - Parameters:
    ///   - className: className or empty string
    ///   - file: filename of the sender
    /// - Returns: if classname is given return "<class>." otherwise "<filename>|"
    static func name(className: String
                    , file: String
    ) -> String {
        if className.isEmpty {
            // extracting the filename part only. Unfortunately we can't use
            // URL(filepath: file) here as it will allways returns "MyLogger"
            return "\(file.split(separator: "/").last!.split(separator: ".").first!)|"
        }
        else {
            // as the app name is redundant we only use the last part
            return "\(className.split(separator: ".").last!)."
        }
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
                      , level: OSLogType = defaultLevel
                      , className: String = ""
                      , file: String = #file
                      , function: StaticString = #function
                      //, line: UInt = #line
                ) {
        
        let thread = Thread.isMainThread ? " " : "T"
        
        let name = name(className: className, file: file)
        Logger.main.log(level: defaultLevel,
                    //  v--- must be all same column!
                        """
                        \(fill, privacy: .public)\
                        \(thread)\(name, privacy: .public)\
                        \(function, privacy: .public),\
                         \(message, privacy: .public)
                        """)
                    //  ^--- must be all same column!
    }
    
    /// Increases the log level indent
    /// - Parameters:
    ///   see write
    static func login(_ message: String
                      , level: OSLogType = defaultLevel
                      , className: String = ""
                      , file: String = #file
                      , function: StaticString = #function
                      //, line: UInt = #line
                ) {
        let name = name(className: className, file: file)
        if Thread.isMainThread {
            // \(String(format: "%4d", line), privacy: .public)\
            Logger.main.log(level: defaultLevel,
                        """
                        \(fill, privacy: .public)\
                        ╭╴ \(name, privacy: .public)\
                        \(function, privacy: .public),\
                         \(message, privacy: .public)
                        """)
            fill += "│ "
        }
        else {
            Logger.main.log(level: defaultLevel,
                        """
                        \(fill, privacy: .public)\
                        T\(name, privacy: .public)\
                        \(function, privacy: .public),\
                         \(message, privacy: .public)
                        """)
        }
    }
    
    /// Decreases the log level indent
    /// - Parameters:
    ///   see write
    static func logout(_ message: String
                       , level: OSLogType = defaultLevel
                       , className: String = ""
                       , file: String = #file
                       , function: StaticString = #function
                       //, line: UInt = #line
                ) {
        if fill.count >= 2 {
            fill.removeLast(2)
        }
        let name = name(className: className, file: file)
        if Thread.isMainThread {
            
            Logger.main.log(level: defaultLevel,
                        """
                        \(fill, privacy: .public)\
                        ╰╴ \(name, privacy: .public)\
                        \(function, privacy: .public),\
                         \(message, privacy: .public)
                        """)
        }
        else {
            Logger.main.log(level: defaultLevel,
                        """
                        \(fill, privacy: .public)\
                        T\(name, privacy: .public)\
                        \(function, privacy: .public),\
                         \(message, privacy: .public)
                        """)
        }
    }
    
}
