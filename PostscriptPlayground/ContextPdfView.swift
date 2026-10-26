//
//  ContextPdfView.swift
//  SimplePsViewer
//
//  Changed by LegoEsprit 2026-10-24 Zoom and offset stay constant
//  Changed by LegoEsprit 2024-12-27 New GIT version
//  Created by LegoEsprit on 29.04.23.
//
import os.log
import Cocoa
import PDFKit
import UniformTypeIdentifiers

extension FileManager {
	/*
	 // Not required anymore
	 
	/// Url for the path into the application writable directory
	static var supportDataPath: URL {
		get {
			let writablePath = FileManager.default.urls(
				for: .applicationSupportDirectory
				, in: .userDomainMask
			).first!

			return writablePath.appendingPathComponent(
				Bundle.main.bundleIdentifier ?? "de.LegoEsprit.temp"
				, isDirectory: true
			)
		}
	}
	
	/// Url for the temporary pdf
	static var tempPdfFileUrl: URL {
		get {
			return createTempURL(name: "temp.pdf")
		}
	}
	*/
	
	/// Creates a tempfile from the name
	/// - Parameter name: Name of the temp file including extension
	/// - Returns: URL to the temp file
	/// ```
	/// If a folder for the application does not exist a new folder is
	/// being created.
	/// ```
	static func createTempURL(name: String) -> URL {
		// Again fails under Sonoma
		/*
		if !FileManager.default.fileExists(atPath: supportDataPath.path) {
			do {
				try FileManager.default.createDirectory(
					atPath: supportDataPath.path
					, withIntermediateDirectories: true
					, attributes: nil
				)
			}
			catch {
				Logger.write("Can't create writeable directory", className: " Static")
				let writablePath = FileManager.default.urls(
					for: .applicationSupportDirectory
					, in: .userDomainMask
				).first!

				return writablePath.appendingPathComponent(
					name
					, isDirectory: false
				)
			}
		}
		return supportDataPath.appendingPathComponent(
			name
			, isDirectory: false
		)
		 */
        let tempDir = FileManager.default.temporaryDirectory.path_fallback
		let tempFileUrl = URL(fileURLWithPath: tempDir + name)
		if !FileManager.default.fileExists(atPath: tempDir) {
			do {
				try FileManager.default.createDirectory(
					atPath: tempDir
					, withIntermediateDirectories: true
					, attributes: nil
				)
			}
			catch {
				Logger.write("Can't create writeable directory", className: " Static")

				return tempFileUrl
			}

		}

		return tempFileUrl

	}

}

/*
extension URL {
	init(fileName: String) {
		if #available(macOS 13.0, *) {
			self.init(filePath:"Untitled", directoryHint: .inferFromPath)
		}
		else {
			//?
		}
	}
}
 */

extension NSView {
    var scrollView: NSScrollView? {
        if let scrollView = self as? NSScrollView { return scrollView }
        for subview in subviews {
            if let found = subview.scrollView { return found }
        }
        return nil
    }
}

/// Overwritten pdf view for loading and saving pdf files
class ContextPdfView: PDFView, SaveAsProtocol {
    
    // , NSMenuItemValidation
    //func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    
	/// empty pdf path
    var pdfUrl: URL = URL.create_fallback(path: "Untitled")
    
    var currentScale = 1.0
    var currentOrigin = NSPoint()
    
	/// temp file to store the pdf - Only directly writable path in Sandbox
	private var _tempFileUrl: URL? = nil
	var tempFileUrl: URL {
		if nil == _tempFileUrl {
			_tempFileUrl = FileManager.createTempURL(name: "temp.pdf")
		}
		return _tempFileUrl!
	}
    

    
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
        guard let contextMenu = super.menu(for: event) else { return nil }

        //let saveAsItem = NSMenuItem(
        //    title: "Save PDF as ..."
        //    , action: #selector(savePdfAsPrivate)
        //    , keyEquivalent: ""
        //)
        //saveAsItem.target = self
        contextMenu.addItem("Save PDF as ..."
                            , action: #selector(savePdfAsPrivate)
                            , with: self
                            , symbol: NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: nil)
        )

        
        //let printViewItem = NSMenuItem(
        //    title: "Print ..."
        //    , action: #selector(printView(_:))
        //    , keyEquivalent: ""
        //)
        //printViewItem.target = self
        //contextMenu.addItem(printViewItem)
        contextMenu.addItem("Print ..."
                            , action: #selector(printView(_:))
                            , with: self
                            , symbol: NSImage(systemSymbolName: "printer", accessibilityDescription: nil)
        )
        
        return contextMenu
    }
	
	/// Used to re-open the temp file as PDF document
	func clearPdf() {
		document = PDFDocument()
	}
    


    
    
    /// Used to re-open the temp file as PDF document
    /// Using store- and retrieveFrame the scale and origin are kept the same
    func openTempFileUrlAsPdf() {
        storeFrame()
        let outFile = tempFileUrl
		document = PDFDocument(url: outFile)
        retrieveFrame()
    }
    
    
    /// Save pdf document by using PDFDocument write method
    fileprivate func savePdf() {
        if let outDoc = document {
            if !outDoc.write(to: pdfUrl) {
                let alert = NSAlert()
                
                alert.alertStyle = .warning
                alert.messageText = LocalizedString("Postscript file couldn't be saved").string
                //alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }

    }
    
    
    /// Opens the save dialog via ''runSavePanel''
    @objc func savePdfAsPrivate() {
        Logger.login(pdfUrl.path_fallback, className: className)
        var pdfFile = pdfUrl
        let response = runSavePanel(
            &pdfFile
            , title: LocalizedString("Store the .pdf file?").string
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
    
    /*
    @objc func printPdf() {
        Logger.login(pdfUrl.path_fallback, className: className)
        var pdfFile = pdfUrl
        
        Logger.logout("", className: className)
    }
     */
    
    
    /// Save from menu item
    /// - Parameter sender: Sender not used
    @IBAction func savePdfAs(_ sender: NSMenuItem) {
        savePdfAsPrivate()
    }
    
    
    func storeFrame() {
        guard let scrollView = scrollView else {
            return
        }
        currentScale = scaleFactor
        currentOrigin = scrollView.contentView.bounds.origin
    }
    
    func retrieveFrame() {
        guard let scrollView = scrollView else {
            return
        }
        scaleFactor = currentScale
        documentView?.scroll(currentOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
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

