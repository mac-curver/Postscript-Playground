////
//  PostscriptPlayground
//  GhostscriptVerion
//
//  Created by LegoEsprit on 13.10.26.
//  Copyright (c) 2025 LegoEsprit
//

import Foundation

class GhostscriptVersion {
    
    static let defaultPath = "/usr/local/opt/ps2pdf"
    static let defaultArgument = ""

    var path: String
    var argument: String
    
    let pathKey = "PsToPdfConverter"
    let argumentKey = "PsToPdfConverterArg"

    
    convenience init() {
        self.init(Self.defaultPath, Self.defaultArgument)
    }
    
    init(_ path: String, _ argument: String) {
        self.path = path
        self.argument = argument
    }
    
    /// Array with full path to the tool and parameter for the output argument if required
    /// resolvesAliases
    static let alternativeConverters: [GhostscriptVersion] = [
        GhostscriptVersion(defaultPath, defaultArgument)
        , GhostscriptVersion("/usr/bin/pstopdf", "-o")
        , GhostscriptVersion("/opt/local/bin/ps2pdf", "")
        , GhostscriptVersion("/usr/local/bin/ps2pdf", "")
        , GhostscriptVersion("/opt/homebrew/bin/ps2pdf", "")
        , GhostscriptVersion("/usr/local/opt/ghostscript/bin/ps2pdf", "")
        , GhostscriptVersion("/~/Applications/pstopdf", "-o")
    ]

    
    /// get Version of ghostscript
    /// - Parameter path: Choosen path of the ghostscript / ps2pdf converter
    /// - Returns: Version number
    static func get(from path: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        // Use the default macOS shell
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // "-l" runs as a login shell so it loads your .zshrc/.zprofile PATH mappings.
        // "-c" executes the specific string command that follows.
        process.arguments = ["-l", "-c", "\(path)/gs --version"]
        process.standardOutput = pipe
        process.standardError = Pipe() // Silence any stderr logs
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Trim whitespace, newlines, and carriage returns
                let version = output.trimmingCharacters(in: .whitespacesAndNewlines)
                return version.isEmpty ? nil : version
            }
        } catch {
            print("Failed to run the process: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Retrieve from preferences
    /// - Parameters:
    ///   - successPath: Default value for the path
    ///   - successArgument: Default argument, (not correctly supported yet!)
    func retrieve(_ successPath: String, _ successArgument: String) {
        let preferences = UserDefaults.standard
        self.path = preferences.string(forKey: pathKey) ?? successPath
        self.argument = preferences.string(forKey: argumentKey) ?? successArgument
    }
    
    /// Store path and argument to preferences
    func store() {
        if !path.isEmpty {
            let preferences = UserDefaults.standard
            preferences.set(path, forKey: pathKey)
            preferences.set(argument, forKey: argumentKey)
        }
    }
 
}


