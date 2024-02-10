//
//  SaveAsProtocol.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 29.04.23.
//

import Cocoa
import UniformTypeIdentifiers


/// Protocol to make save panel available for Postscript and PDF files
protocol SaveAsProtocol {
    
    /// Run save panel opens save dialog to store documents
    /// - Parameters:
    ///   - outFile: files as URL to be stored
    ///   - title: title for the file save dialog
    ///   - fileType: allowed filestypes
    /// - Returns: ModalResponse
    func runSavePanel(_ outFile: inout URL
                        , title: String
                        , fileType: UTType
        )->NSApplication.ModalResponse

}

/// Protocol extension to implement the method
extension SaveAsProtocol {
    /// Run save panel opens save dialog to store documents
    /// - Parameters:
    ///   - outFile: files as URL to be stored
    ///   - title: title for the file save dialog
    ///   - fileType: allowed filestypes
    /// - Returns: Result of running the modal save dialog as ModalResponse
    ///
    /// The extension is required to implement the code
    func runSavePanel(_ outFile: inout URL
                        , title: String
                        , fileType: UTType
        )->NSApplication.ModalResponse {
        
        let savePanel = NSSavePanel()
                
        savePanel.title                   = title
        savePanel.showsResizeIndicator    = true
        savePanel.showsHiddenFiles        = false
        savePanel.canCreateDirectories    = true
        //savePanel.allowedFileTypes        = [fileType]
        savePanel.allowedContentTypes     = [fileType]
        savePanel.nameFieldStringValue    = outFile.lastPathComponent
        
        let response = savePanel.runModal();
        outFile = savePanel.url ?? URL(string: "")!
        
        return response
    }
}
