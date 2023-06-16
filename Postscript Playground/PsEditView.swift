//
//  PsEditView.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 30.03.23.
//
//  Attention: In IB class section the "Inherit module from target" must be checked!
//

import os.log
import Cocoa
import UniformTypeIdentifiers
import Carbon.HIToolbox


/// Extension to the `String` protocol to retrieve the character at index
extension StringProtocol {
    /// subscript the `String`
    ///
    /// - parameter offset:                 The index of the character we want to get from the `String`.
    /// - returns:                           `Character` at the offset position in the `String`.
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

/// Extension to the `Double` type to print exactly 6 fractional digits
extension Double {
    static let twoFractionDigits: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 6
        formatter.maximumFractionDigits = 6
        return formatter
    }()
    var formatted: String {
        return Double.twoFractionDigits.string(for: self) ?? ""
    }
}


/// PsEditView overwritten NSTextView used to convert .ps file into .pdf
class PsEditView: NSTextView, SaveAsProtocol, NSTextViewDelegate {
    
    struct FileUrl {
        var url:URL
        var knownToFileManager: Bool
    }
    
    /// version number of PsEditView
    static let version = "2.2.0"

    
    /// Only .ps files are allowed
    let expectedExt = ["ps"]
    let postScriptUUType = UTType("com.adobe.postscript")!
    var viewController: ViewController? = nil
    
    /// Timer used for automatic conversion and delayed syntax highlighting
    var timer: Timer = Timer()
    
    
    var psFileUrl: FileUrl
    let homeDir = FileManager.default.urls(
        for: FileManager.SearchPathDirectory.documentDirectory
        , in: FileManager.SearchPathDomainMask.userDomainMask
    ).first!

    /// true whenever changes were applied
    var saved = true
    /// AutoSaving when in live mode
    var autoSave = false


    /// init to initialize the required fields  `String` to `OutputStream`
    ///
    /// - parameter coder:                  Propagated to super.
    ///
    /// Calls its super class init sets the background and registers for drop

    required init?(coder: NSCoder) {
        psFileUrl = FileUrl(
              url: homeDir.appendingPathComponent(
                              "Untitled.ps"
                            , conformingTo: postScriptUUType
                 )
            , knownToFileManager: false
        )
        Logger.login("init? \(psFileUrl) ")
        super.init(coder: coder)


        registerForDraggedTypes(
            [  NSPasteboard.PasteboardType.URL
             , NSPasteboard.PasteboardType.fileURL
            ]
        )
        delegate = self
        initializeSyntaxColors()
        Logger.logout("init?")
    }
    
    /// awakeFromNib to initialize to a monospaced font
    override func awakeFromNib() {
        Logger.login("", className: className)
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        viewController = appDelegate?.viewController
        font = NSFont(name: "Monaco", size: 11)
        //isRulerVisible = true
        Logger.logout("", className: className)
    }
    
    /// setPathes calculates the pdf and ps pathes from a root `URL`
    /// - parameter urlForPrefix:           The  root `URL` for the pdf or ps.
    func setPathes(urlForPrefix: URL, known: Bool) {
        Logger.login("", className: className)
        let pathPrefix = urlForPrefix.deletingPathExtension()
        psFileUrl = FileUrl(url: pathPrefix.appendingPathExtension("ps")
                            , knownToFileManager: known
        )
        Logger.logout("\(psFileUrl)", className: className)
    }
    
    @IBAction func showRuler(_ sender: NSMenuItem) {
        isRulerVisible = sender.state == .on
    }
    
    /// Overwritten prepareForDragOperation for drop operation
    /// - parameter sender:             The `NSDraggingInfo` from the sender.
    /// - returns:                      `true` if we accept the drop otherwise `false`.
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return checkExtension(sender) == .copy
    }

    /// checkExtension returns the .copy if file extension is .ps
    ///
    /// - parameter dragInfo:           The drag infor from the system.
    /// - returns:                      .copy if the file exstension is .ps
    fileprivate func checkExtension(_ dragInfo: NSDraggingInfo) -> NSDragOperation {
        guard let board = dragInfo.draggingPasteboard.propertyList(
            forType: NSPasteboard.PasteboardType(
                rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String
        else {
            return NSDragOperation()
        }

        let suffix = URL(fileURLWithPath: path).pathExtension

        if expectedExt.contains(suffix) {
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    /// draggingEntered returns the .copy if file extension is .ps
    /// - parameter dragInfo:               The drag info from the system.
    /// - returns:                          See checkExtension
    ///
    /// Running in the main thread. Unfortunately checking the extension
    /// here does not work completely, therefore we need to overwrite
    /// also draggingUpdated!
    @MainActor
    override func draggingEntered(_ dragInfo: NSDraggingInfo) -> NSDragOperation {
        return checkExtension(dragInfo)
    }

    /// draggingUpdated returns the .copy if file extension is .ps
    /// - parameter dragInfo:               The drag info from the system.
    /// - returns:                          See checkExtension
    ///
    /// Contiously called during drag operation in the main thread.
    @MainActor
    override func draggingUpdated(_ dragInfo: NSDraggingInfo) -> NSDragOperation {
        return checkExtension(dragInfo)
    }


    /// performDragOperation performs the drag operation
    /// Contiously called during drag operation in the main thread.
    /// - Parameter dragInfo:               The drag info from the system.
    /// - Returns: true if drag finished successfully
    @MainActor
    override func performDragOperation(_ dragInfo: NSDraggingInfo) -> Bool {
        Logger.login("", className: className)
        guard
            let pasteboard =
                dragInfo.draggingPasteboard.propertyList(
                        forType: NSPasteboard.PasteboardType(
                            rawValue: "NSFilenamesPboardType"
                        )
                ) as? NSArray,
            let path = pasteboard.lastObject as? String
        else {
            Logger.logout("", className: className)
            return false
        }
        viewController?.openFileUrl(URL(filePath: path))
        if pasteboard.count > 1 {
            viewController?.tooManyFilesAlert()
        }
        viewController?.convertPsToPdf()
        Logger.logout("", className: className)
        return true
    }
    
    /// Find row and column for selection start
    /// Checks indexStarts for the index of the start larger than the selected position and
    /// calculates the distance between the previous line start.
    fileprivate func setColumnAndRow() {
        let (line, column) = lineNumber()
        viewController?.setColumnRow(line: "L: \((line+1).formatted()) C:\((column+1).formatted())")
    }


    /// mouseDown used to caluculate the text position in the ps file
    ///
    /// - parameter event:            The system ´NSEvent´.
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        setColumnAndRow()
    }

    
    /// keyDown used to restart the timer for autosave and syntax highligthing
    /// - parameter event:            The system ´NSEvent´.
    ///
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        setColumnAndRow()
    }
    
    /// Text did change notification from OS
    /// - Parameter notification: Not used
    ///
    /// Indicates, that the file contents should be changed and starts a 2 s timer.
    func textDidChange(_ notification: Notification) {
        saved = false
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2
                                     , target: self
                                     , selector: #selector(fireTimer)
                                     , userInfo: nil
                                     , repeats: false
        )
    }
    
    
    /// fireTimer was restarted for autosave and syntax highligthing.
    /// Recolors according to syntax and in case of aiutosave mode converts to pdf like a
    /// playground.
    @objc func fireTimer() {
        Logger.login("", className: className)
        if (autoSave) {
            if saveFileToPsUrl() {
                viewController?.convertPsToPdf()
                Logger().log("Timer was fired")
            }
        }
        assignSyntaxColors()
        Logger.logout("", className: className)
    }
    
    /// Not tested Works, but is wrong!
    func selectLineNumber(lineNumberToJumpTo: Int) {
        let layoutManager = layoutManager!
        var numberOfLines = 1
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var lineRange: NSRange = NSRange()
        var indexOfGlyph = 0
        
        while indexOfGlyph < numberOfGlyphs {
            layoutManager.lineFragmentRect(
                                             forGlyphAt: indexOfGlyph
                                           , effectiveRange: &lineRange
                                           , withoutAdditionalLayout: false
                          )
            // check if we've found our line number
            if numberOfLines == lineNumberToJumpTo {
                
                selectedRange = lineRange
                scrollRangeToVisible(lineRange)
                
                break
            }
            indexOfGlyph = NSMaxRange(lineRange)
            numberOfLines += 1
        }
    }
    
    
    /// Uses lineRange from Swift
    /// - Returns: An array of String:index
    /// Fastest and probably best implementation for Swift. Can't be used in Objective-C. Little bit
    /// more complicated to use as for example NSTextView.selectedRange returns an NSRange
    /// and therefore must be converted to Range<String.Index>.
    func indexStartsByLineRange() -> [String.Index] {
        /*
         // Convert Range<String.Index> to NSRange:
         let range   = s[s.startIndex..<s.endIndex]
         let nsRange = NSRange(range, in: s)
         
         // Convert NSRange to Range<String.Index>:
         let nsRange = NSMakeRange(0, 4)
         let range   = Range(nsRange, in: s)
         */
        Logger.login("")
        let start = ProcessInfo.processInfo.systemUptime;
        var indexStarts:[String.Index] = []

        var index = string.startIndex
        indexStarts.append(index)
        while index != string.endIndex {
            let range = string.lineRange(for: index..<index)
            index = range.upperBound
            indexStarts.append(index)
        }
        Logger.logout("Using String.Index:\(ProcessInfo.processInfo.systemUptime-start) s")
        return indexStarts
    }
    
    /// lineNumber calculates the cursor position line/offset
    /// - Returns: doublet with line number, horizontal offset
    func lineNumber() -> (Int, Int) {
        //let start = ProcessInfo.processInfo.systemUptime;
        let selectionRange: NSRange = selectedRange()
        let regex = try! NSRegularExpression(pattern: "\n", options: [])
        let lineNumber = regex.numberOfMatches(in: string, options: [], range: NSMakeRange(0, selectionRange.location)) + 1
        var column = 0
        if let stringIndexSelection = Range(selectionRange, in: string) {
            let lineRange = string.lineRange(for: stringIndexSelection)
            column = string.distance(from: lineRange.lowerBound, to: stringIndexSelection.upperBound)
        }
        //Logger.write("Using RegEx     :\(ProcessInfo.processInfo.systemUptime-start) s")
        return (lineNumber, column)
    }
    

    
    /// Displays file open panel
    /// - Parameter inFile: Url of Postscript file to be read INOUT
    /// - Returns: Result of the dialog - particularily the case when the user cancels must be detected
    func runOpenPanel(_ inFile: inout URL, with selected:String = "")->NSApplication.ModalResponse {
        Logger.login("", className: className)
        let openPanel = NSOpenPanel()
            
        let file = selected.isEmpty ? "a .ps" : "the \(selected)"
        let openMessage = "Please choose \(file) to be converted to pdf"
        openPanel.message                 = openMessage
        openPanel.showsResizeIndicator    = true
        openPanel.showsHiddenFiles        = false
        openPanel.canChooseFiles          = true
        openPanel.canChooseDirectories    = false
        openPanel.canCreateDirectories    = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes     = [postScriptUUType]
        openPanel.directoryURL            = inFile.deletingLastPathComponent()
        openPanel.nameFieldStringValue    = inFile.lastPathComponent
        
        Logger.write("\(openPanel.nameFieldLabel ?? "None"), \(openPanel.nameFieldStringValue)", className: className)

        
        let response = openPanel.runModal();
        inFile = openPanel.url ?? URL(fileURLWithPath: "")
        Logger.logout("", className: className)
        return response
    }
    
    func newFile() {
        let myFileUrl = Bundle.main.url(forResource:"New", withExtension: "ps")
        do {
            string = try String(contentsOf: myFileUrl ?? URL(fileURLWithPath: ""), encoding: .utf8)
        }
        catch {
            string = """
                %!PS
                
                /Times-Bold findfont 36 scalefont setfont
                72 684 moveto (Hello World!) show
                4 setlinewidth
                0 -4 rmoveto
                72 680 lineto stroke
                showpage
                """
        }
        setPathes(urlForPrefix: URL(filePath: "Untitled.ps"), known: false)
        fireTimer()

    }
    
    /// Displays file open dialog
    /// - Parameter selected: Name of the file proposed as default
    /// - Returns: True if not canceled
    func openFileWithOpenDialog(selected: String)-> Bool {
    
        var resultUrl:URL = psFileUrl.url

        let response = runOpenPanel(&resultUrl, with: selected)
        switch response {
        case NSApplication.ModalResponse.OK:
            psFileUrl.url = resultUrl
            psFileUrl.knownToFileManager = true
            break
        default:
            break
        }
        return response == NSApplication.ModalResponse.OK

    }

    
    
    /// Copies contents of the file to self.string to display it.
    /// - Returns: true if new file was opened successfully
    fileprivate func openFilePrivate() -> Bool {
        Logger.login("", className: className)
        saved = true
        do {
            string = try String(contentsOf: psFileUrl.url, encoding: .utf8)
            
            assignSyntaxColors()
            Logger.logout("\(string.count)", className: className)
            return true
        }
        catch {
            //os_log("Here we should add an error message")
            Logger.logout("", className: className)
            return false
        }
    }
    
    /// Displays an alert to offer to save the changes in case document has been changed
    func checkToSaveChanges() {
        if !saved {
            let alert = NSAlert()
            
            alert.alertStyle = .warning
            alert.messageText = "Changes to Poscript file were not saved"
            alert.informativeText =
                        """
                        The current file contains changes, that
                        were not yet stored onto the disk!
                        """
            alert.addButton(withTitle: "Save the changes")
            alert.addButton(withTitle: "Ignore and don't save")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                Logger().log("Save changes")

                _ = saveFileToPsUrl()
            default:
                break
            }
        }
    }
    
    func revert() -> Bool {
        return openFilePrivate()
    }
    
    /// openFileUrlAsPs load file and apply syntax coloring
    /// - Returns: true if loading did succeed
    func openFileUrlAsPs(url: URL) -> Bool {
        Logger.login("", className: className)
        checkToSaveChanges()
        setPathes(urlForPrefix: url, known: true)
        let success = openFilePrivate()
        if success {
            Logger.write("will be converted", className: className)
        }
        Logger.logout("", className: className)
        return success
    }
    
    func openSecurityScopedResource(bookmark: Data) -> URL? {
        Logger.login("", className: className)
        checkToSaveChanges()
        // Resolve the decoded bookmark data into a security-scoped URL.
        var isStale:Bool = true
        var bookmarkedUrl: URL? = nil
        do {
            
            bookmarkedUrl = try URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            // Indicate that you want to access the file-system resource.
            if nil != bookmarkedUrl?.startAccessingSecurityScopedResource() {
                setPathes(urlForPrefix: bookmarkedUrl!, known: true)
                let success = openFilePrivate()
                if success {
                    Logger.write("will be converted", className: className)
                }
            }
            
        }
        catch {
            Logger.write("Reading bookmark failed: \(error)", className: className)

        }
        Logger.logout("", className: className)
        return bookmarkedUrl
    }
    
    func saveFileTo(path: String) -> Bool {
        
        Logger.login("\(path)")
        var success = false
        do {
            try string.write(toFile: path
                             , atomically: true
                             , encoding: .utf8
            )
            success = true
        } catch {
            let alert = NSAlert()
            
            alert.alertStyle = .warning
            alert.messageText = "Poscript file couldn't be saved"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        Logger.logout("\(success)")
        return success
    }
    
    /// saveFileToPsUrl load file and apply syntax coloring
    func saveFileToPsUrl() -> Bool {
        Logger.write("\(psFileUrl)", className: className)
        if psFileUrl.knownToFileManager {
            saved = saveFileTo(path: psFileUrl.url.path)
            return true
        }
        else {
            Logger.write("Save file as", className: className)
            return NSApplication.ModalResponse.OK == savePsFileAs()
        }
    }
    
    /// Open save dialog to store the Postscript file
    /// - Returns: In case of Ok we should also convert to PDF
    func savePsFileAs()->NSApplication.ModalResponse {
        // We need a copy here to avoid run-time error: Thread 1: Simultaneous
        // accesses to 0x..., but modification requires exclusive access
        var psFile = psFileUrl.url
        let response = runSavePanel(
            &psFile
            , title: "Write to \(expectedExt.first ?? ".ps") (Postscript) file"
            , fileType: postScriptUUType
        )
        switch response {
            case NSApplication.ModalResponse.OK:
                // Copy back the copy!
                psFileUrl = FileUrl(url: psFile, knownToFileManager: true)
                _ = saveFileToPsUrl()
            default:
                break
        }
        return response
    }

}
