//
//  ContextPdfView.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 29.04.23.
//
import os.log
import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Overwritten pdf view for loading and saving pdf files
class ContextPdfView: PDFView, SaveAsProtocol {
    
    // , NSMenuItemValidation
    //func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    
    /// empty pdf path
    var pdfUrl: URL = URL(filePath:"Untitled", directoryHint: .inferFromPath)
    
    /// temp file to store the pdf - Only directly writable path in Sandbox
    let tempFileUrl = FileManager.default.urls(
         for: .applicationSupportDirectory
        , in: .userDomainMask
    ).first?.appendingPathComponent("temp.pdf")

    
    /// Copies the name and sets pdf as extension to propose a correct name for the pdf
    /// - Parameter urlForPrefix: URL of the corresponding Postscript file
    func setPathes(urlForPrefix: URL) {
        Logger.login("", className: className)
        let pathPrefix = urlForPrefix.deletingPathExtension()
        pdfUrl = pathPrefix.appendingPathExtension("pdf")
        Logger.logout("", className: className)
    }
    
    /// Used to add context "Save as..." menu to the pdf files contexts
    /// - Parameter event: Not used
    /// - Returns: NSMenuItem for the added "Save as..." item
    override func menu(for event: NSEvent) -> NSMenu? {
        let contextMenu = super.menu(for: event)
        contextMenu?.addItem(withTitle: "Save PDF as ..."
                             , action: #selector(savePdfAsPrivate)
                             , keyEquivalent: ""
                     )
        
        return contextMenu
    }
	
	/// Used to re-open the temp file as PDF document
	func clearPdf() {
		document = PDFDocument()
	}

    
    
    /// Used to re-open the temp file as PDF document
    func openTempFileUrlAsPdf() {
        if let outFile = tempFileUrl {
            document = PDFDocument(url: outFile)
        }
    }
    
    
    /// Save pdf document by using PDFDocument write method
    fileprivate func savePdf() {
        if let outDoc = document {
            if !outDoc.write(to: pdfUrl) {
                let alert = NSAlert()
                
                alert.alertStyle = .warning
                alert.messageText = String(localized: "Postscript file couldn't be saved")
                //alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }

    }
    
    
    /// Opens the save dialog via ''runSavePanel''
    @objc func savePdfAsPrivate() {
        Logger.login(pdfUrl.absoluteString, className: className)
        var pdfFile = pdfUrl
        let response = runSavePanel(
            &pdfFile
			, title: String(localized: "Store the .pdf file?")
            , fileType: UTType("com.adobe.pdf")!
        )
        switch response {
        case NSApplication.ModalResponse.OK:
            // Copy back the copy!
            pdfUrl = pdfFile
            savePdf()
        default:
            break
        }
        Logger.logout("", className: className)
    }
    
    /// Save from menu item
    /// - Parameter sender: Sender not used
    @IBAction func savePdfAs(_ sender: NSMenuItem) {
        savePdfAsPrivate()
    }
	
	/*
	func drawPDFfromURL(url: URL) -> NSImage? {
		guard let document = CGPDFDocument(url as CFURL) else { return nil }
		guard let page = document.page(at: 1) else { return nil }

		let pageRect = page.getBoxRect(.mediaBox)
		let renderer = NSGraphicsContext()
		let img = renderer.image { ctx in
			NSColor.white.set()
			ctx.fill(pageRect)

			ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
			ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

			ctx.cgContext.drawPDFPage(page)
		}

		return img
	}
	 */

}

