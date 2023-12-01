//
//  ViewController.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 30.05.23.
//

import Cocoa
import os.log

/// Newly added view controller
/// Displays a split view with a PS file editor on the left and a pdf output on the right
///
class ViewController: NSViewController {

    /// Live editing modes
    enum Mode: Int {
        case RunManually = 0
        case RunAutomatically
        case StopAutomatically
    }

    @IBOutlet var window: NSWindow!
    @IBOutlet weak var settingsWindow: NSWindow!
    @IBOutlet weak var recent2Menu: NSMenu!
    @IBOutlet weak var exampleMenu: NSMenu!
    
    @IBOutlet weak var psToPdfConverterPathComboBox: NSComboBox!
    @IBOutlet var psTextView: PsEditView!
    @IBOutlet weak var columnRowLabel: NSTextField!
    @IBOutlet weak var pdfView: ContextPdfView!
    
    @IBOutlet weak var verticalSplitter: NSSplitView!
    @IBOutlet weak var attentionButton: NSButton!
    
    @IBOutlet weak var automaticallyComboBox: NSComboButton!
    @IBOutlet weak var delegate: AppDelegate!
	
	@IBOutlet weak var encodingComboBox: NSComboBox!
	
	let alternateConverters = [  ["/usr/bin/pstopdf", "-o"]
                               , ["/usr/local/bin/ps2pdf", ""]
                               , ["/usr/local/opt/ps2pdf", ""]
                              ]
	

        
    var psToPdfConverterPath = ""
    var outputArgument = ""

    var shell = Shell()
    
    /// As side effect the combobox is being adapted
    var autoMode = Mode.RunManually {
        didSet {
            switch autoMode {
            case .RunManually:
                automaticallyComboBox.image = NSImage(imageLiteralResourceName: "play.fill")
                automaticallyComboBox.toolTip = "Click Play to convert"
                break
            case .RunAutomatically:
                automaticallyComboBox.image = NSImage(imageLiteralResourceName: "play")
                automaticallyComboBox.toolTip = "Runs in automatic mode"
                break
            case .StopAutomatically:
                automaticallyComboBox.image = NSImage(imageLiteralResourceName: "stop")
                automaticallyComboBox.toolTip = "Runs in automatic stop mode"
                break
            }
        }
    }
    
    
    func version() -> String {

        /*
        /// Start in background
        DispatchQueue.global(qos: .userInitiated).async {
           
            let start = ProcessInfo.processInfo.systemUptime
            let test = self.ackermann(m: 2, n: 2)
            Logger.write("\(ProcessInfo.processInfo.systemUptime-start) s")
            print("This is run on a background queue: \(test)")

            /// Get back to foreground
            DispatchQueue.main.async {
            }
        }
         */
		return """
			Bundle: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) \
			(\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String))
			Editor: \(PsEditView.version)
			"""

    }
    
    
    
    override func viewDidLoad() {
        Logger.login(version(), level: OSLogType.default, className: className)
        
        super.viewDidLoad()
        
        var successPath = ""
        let preferences = NSUserDefaultsController().defaults

        psToPdfConverterPathComboBox.removeAllItems()
        for pathAndArgument in alternateConverters {
            let path = pathAndArgument[0]
            if checkFileExists(path) {
                if (successPath.isEmpty) {
                    successPath = path
                }
                psToPdfConverterPathComboBox.addItem(withObjectValue: path)
            }
        }
        
        if successPath.isEmpty {
            let alert = NSAlert()
            
            alert.alertStyle = .critical
            alert.messageText = "No ps to pdf converter could be found"
            alert.informativeText = """
                                    Please install either the Xcode tools or
                                    alternatively Ghostscript using Macports
                                    or Homebrew.
                                    The App will close now!
                                    """
            //alert.addButton(withTitle: "Quit PsViewer")
            //alert.addButton(withTitle: "Xcode in App Store")
            //alert.addButton(withTitle: "GS for Mac Ports")
            //alert.addButton(withTitle: "GS for Homebrew")
            alert.showsHelp = true
            let helpAnchor = "Prerequisites"
            alert.helpAnchor = helpAnchor
            
            switch alert.runModal() {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                exit(-1)
            case NSApplication.ModalResponse.alertSecondButtonReturn:
                if let url = URL(string: "https://apps.apple.com/de/app/xcode/id497799835?ls=1&mt=12") {
                    NSWorkspace.shared.open(url as URL)
                }
            case NSApplication.ModalResponse.alertThirdButtonReturn:
                if let url = URL(string: "https://ports.macports.org/port/ghostscript/") {
                    NSWorkspace.shared.open(url as URL)
                }
            default:
                //if let url = URL(string: "https://formulae.brew.sh/formula/ghostscript#default") {
                //    NSWorkspace.shared.open(url as URL)
                //}
                break;
            }
            
            exit(-1)
        }
        
		psToPdfConverterPath = preferences.string(forKey: "PsToPdfConverter") ?? ""
        

        if psToPdfConverterPathComboBox.numberOfItems > 1 && psToPdfConverterPath.isEmpty {
            psToPdfConverterPathComboBox.selectItem(at: 0)
            psToPdfConverterPathComboBox.stringValue = successPath//psToPdfConverterPathComboBox.objectValueOfSelectedItem as! String
    
            /// Start delayed as otherwise main window hides setting window
            _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
                self.settingsWindow.makeKeyAndOrderFront(self)
            }
        }
        else {
            psToPdfConverterPathComboBox.stringValue = psToPdfConverterPath
            preferences.set(psToPdfConverterPath, forKey: "PsToPdfConverter")
            outputArgument = preferences.string(forKey: "PsToPdfConverterArg") ?? ""
        }

        SyntaxColors.storeUndoColors()
        
        attentionButton.isHidden = true
        
        recent2Menu.retrieveItems(
                                      preferences: preferences
                                    , for: #selector(openRecentFile)
                                 )
		for encoding in allPossibleEncodings {
			encodingComboBox.addItem(withObjectValue: encoding.description)
		}
        
        /// Build sample menu
        let pathes = Bundle.main.paths(forResourcesOfType: "ps", inDirectory: ".")
        for path in pathes {
            let fileNameComponents = path.split(separator: "/")
            let fileName = String(fileNameComponents.last ?? "")
            if !fileName.isEmpty {
                exampleMenu.addItem(withTitle: fileName, action: #selector(openSampleFile), keyEquivalent: "")
            }
            
        }

        
        self.fileNew(NSMenuItem())
            
        Logger.logout("", level: OSLogType.default, className: className)

    }
    
    /*
    override func viewDidAppear() {
        super.viewDidAppear()
        // Still too early ?!
        addAnimationToAttentionButton()
    }
    */
    
    /// We need this as otherwise the animation does not start
    func didFinishLaunching(appDelegate: AppDelegate) {
		Logger.login("", className: className)
        psTextView.viewController = appDelegate.viewController                  /// copy the view controller down the hierachy
        addAnimationToAttentionButton()
		Logger.logout("", className: className)
    }
    
    
    /// Called to indicate long time operation. Looks as if it has no effect
    fileprivate func autoStarting() {
        switch autoMode {
        case .RunAutomatically:
            autoMode = .StopAutomatically
        default:
            break
        }
    }
    
    /// Stop long time operation
    fileprivate func autoFinished() {
        switch autoMode {
        case .StopAutomatically:
            autoMode = .RunAutomatically
            break
        default:
            break
        }
    }
	
	func setEncoding(item: String) {
		encodingComboBox.selectItem(withObjectValue: item)
	}

    
    /// File: Save - Menu actions
    @IBAction func savePsFile(_ sender: NSMenuItem) {
        _ = psTextView.saveFileToPsUrl()
    }
    
    /// File: SaveAs - Menu actions
    @IBAction func savePsFileAs(_ sender: NSMenuItem) {
        _ = psTextView.savePsFileAs()
        addRecentItem(url: psTextView.psFileUrl.url)
    }
    
    /// File: Revert - Menu actions
    @IBAction func revertPsFileTo(_ sender: NSMenuItem) {
        Logger.login("", className: className)
        if (psTextView.revert()) {
            convertPsToPdf()
        }
        Logger.logout("", className: className)

    }



    
    /// Called when convert button is pressed
    /// - Parameter sender: Ignored
    @IBAction func saveAndConvert(_ sender: Any) {
        Logger.login("", className: className)
        autoStarting()
        if psTextView.saveFileToPsUrl() {
            convertPsToPdf()
        }
        Logger.logout("", className: className)
    }
    
    
    
    /// Remove all items from recent menu except the last
    /// - Parameter sender: Menuitem sending the event, but not used
    ///
    /// Unfortunately I failed to used the build in recent menu behaviour. Therefore I
    /// mimic it here manually.
    @IBAction func clearRecentMenu(_ sender: NSMenuItem) {
        let clearItem = recent2Menu.items.last
        recent2Menu.removeAllItems()
        recent2Menu.addItem(clearItem!)
    }
    
    
    
    /// open recent file
    /// - Parameter sender: The recent menu item selected
    ///
    /// Retrieves the Postscript and PDF file names an opens the Postscript file and converts it
    @objc fileprivate func openRecentFile(sender: NSMenuItem) {
        Logger.login("\(sender.title)", className: className)
        checkForChanges()
        if let item: RecentMenuItem = sender as? RecentMenuItem {
    
            if let psUrl = psTextView.openSecurityScopedResource(bookmark: item.menuItem.secureData) {
                setPdfPath(urlForPrefix: item.menuItem.pdfUrl)
                convertPsToPdf()
                // Release the file-system resource when you are done.
                psUrl.stopAccessingSecurityScopedResource()

                if shell.stderr.starts(with: "Operation not permitted:") {
                    if psTextView.openFileWithOpenDialog(selected: psUrl.absoluteString) {
                        openFileUrl(psTextView.psFileUrl.url)
                        convertPsToPdf()
                    }
                }
            }
        }
        Logger.logout("\(sender.title)", className: className)
    }
    
    @objc func openSampleFile(sender: NSMenuItem) {
        checkForChanges()
        let fileName: NSString = NSString(string: sender.title)
        if let path = Bundle.main.path(forResource: fileName.deletingPathExtension, ofType: "ps") {
            Logger.write(path, className: className)
            openFileUrl(URL(filePath: path), addToRecent: false)
            convertPsToPdf()
        }
    }
	
	@objc func changeEncoding(sender: NSMenuItem) {
		Logger.write("")
	}
    
    fileprivate func addRecentItem(url resultUrl: URL) {
        do {
            let bookmarkData = try resultUrl.bookmarkData(
                options:[.withSecurityScope]
            )
            recent2Menu.addRecentMenuItem(
                pdfUrl: pdfView.pdfUrl
                , psData: bookmarkData
                , for: #selector(openRecentFile)
            )
        }
        catch {
            Logger.write("Bookmarking failed: \(error)", level: OSLogType.default, className: className)
        }
    }
    
    /// Opens the Postscript file from URL
    /// - Parameter resultUrl: URL of the Postscript file
    ///
    /// Opens and converts the Postscript file.
    /// Copies the base name to the PDF view as name proposal.
    func openFileUrl(_ resultUrl: URL, addToRecent: Bool = true) {
        Logger.login("\(resultUrl)", className: className)
        if psTextView.openFileUrlAsPs(url: resultUrl) {
            setPdfPath(urlForPrefix: resultUrl)
            if addToRecent {
                addRecentItem(url: resultUrl)
            }
        }
        else {
            window.title = "unknown"
        }
        Logger.logout("", className: className)
    }
    

    
    /// Calls the file open dialog to open a Postscript file
    /// - Parameter sender: Ignored
    @IBAction func openFileWithOpenDialog(_ sender: Any) {
        if psTextView.openFileWithOpenDialog(selected: "") {
            openFileUrl(psTextView.psFileUrl.url)
            convertPsToPdf()
        }
    }
    
    func openAndConvert(_ urls: [URL]) {
		Logger.login("Open file \(urls[0].absoluteString)", className: className)
		if let url = urls.first {
            openFileUrl(url)
            startDelayedConversion()
        }
        if urls.count > 1 {
            tooManyFilesAlert()
        }
		Logger.logout("", className: className)
    }
    
    /// Shows an alert stating that the app can only open a single file at a time
    func tooManyFilesAlert() {
        let alert = NSAlert()
        
        alert.alertStyle = .warning
        alert.messageText = "Only a single file can be opened at at time"
        alert.informativeText = """
                This app allows to edit a single .ps at a time. Only
                the last selected file is being opened for editing.
            """
        _ = alert.runModal()
    }

    
    @IBAction func fileNew(_ sender: NSMenuItem) {
        checkForChanges()
        window.title = "Postscript Playground"
        setPdfPath(urlForPrefix: URL(filePath: "Untitled.pdf"))
        psTextView.newFile()
    }
    
    /// Opens an alert to display the Postscript error
    /// - Parameter sender: Ignored
    @IBAction func openErrorButtonDisplay(_ sender: NSButton) {
        let alert = NSAlert()
        
        alert.alertStyle = .warning
        alert.messageText = "Poscript file couldn't be converted"
        alert.informativeText = shell.stdout
                                + "\n"
                                + shell.stderr
        alert.runModal()
    }
    
    /// Help button action
    /// - Parameter sender: Ignored
    @IBAction func helpButtonAction(_ sender: Any) {
        if let myFileUrl = Bundle.main.url(forResource:"Postscript PlaygroundHelp", withExtension: "html") {
            NSWorkspace.shared.open(myFileUrl)
        }
    }
    
    /// Help action
    /// - Parameter sender: Ignored
    @IBAction func helpAction(_ sender: Any) {
        /// Could not find any description on how to build a help file bumdle
        if  let bookName = Bundle.main.object(
                                forInfoDictionaryKey: "CFBundleHelpBookName"
                            ) as? String {
            NSHelpManager.shared.openHelpAnchor("Intro", inBook: bookName)
        }
    }
    
    
    /// Play or Stop button pressed on combobox
    /// - Parameter sender: Ignored
    ///
    /// Saves an converts
    @IBAction func comboBoxPressed(_ sender: Any) {
        switch autoMode {
        case .RunManually:
            saveAndConvert((Any).self)
        case .RunAutomatically:
            autoMode = .StopAutomatically
        default:
            break
        }
    }
    
    /// Sets to manual mode from combobox
    /// - Parameter sender: Ignored
    @IBAction func runManually(_ sender: Any) {
        autoMode = Mode.RunManually
        psTextView.autoSave = false
    }
    
    /// Set to automatic mode from combobox
    /// - Parameter sender: Ignored
    @IBAction func runAutomatically(_ sender: Any) {
        psTextView.autoSave = true
        autoMode = Mode.RunAutomatically
        saveAndConvert((Any).self)
    }
    
    
    func setPdfPath(urlForPrefix: URL) {
        pdfView.setPathes(urlForPrefix: urlForPrefix)
    }
    
    
    func setColumnRow(line: String) {
        columnRowLabel.stringValue = line
    }

    
    
    func startDelayedConversion() {
        Logger.login("", className: className)
        _ = Timer.scheduledTimer(timeInterval: 1.0
                                     , target: self
                                     , selector: #selector(fireTimer)
                                     , userInfo: nil
                                     , repeats: false
        )
        Logger.logout("", className: className)
    }
    
    
    /// fireTimer was restarted for autosave and syntax highligthing.
    /// Recolors according to syntax and in case of aiutosave mode converts to pdf like a
    /// playground.
    @objc func fireTimer() {
        convertPsToPdf()
            
        Logger.write("The delayed conversion timer was fired", className: className)
    }

    
    
    /// Here the real magic happens. This method calls the ps2Pdf converter command line tool
    func convertPsToPdf() {
        Logger.login("", className: className)
        autoStarting()

        window.title = psTextView.psFileUrl.url.lastPathComponent
        
        let argumentArray = [  psTextView.psFileUrl.url.path
                             , outputArgument
                             , pdfView.tempFileUrl!.path
                            ]
        shell = Shell(psToPdfConverterPath
                      , arguments: argumentArray
        )

        
        if shell.stderr.isEmpty {
            attentionButton.isHidden = true
            pdfView.openTempFileUrlAsPdf();
        }
        else {
            Logger.write(shell.stderr, className: className)
            attentionButton.isHidden = false
        }
        
        autoFinished()
        Logger.logout("", className: className)
    }
    
    
    


    
    /// Checks if PDF exists already
    /// - Parameter filePath: Path of the pdf file
    /// - Returns: true in case a file with filePath does exist
    func checkFileExists(_ filePath: String)->Bool {
        return FileManager.default.fileExists(
                  atPath: NSString(string: filePath).expandingTildeInPath
               )
    }
    
    
    /// Adds blinking animation to the attention button
    func addAnimationToAttentionButton() {
        let animation = CAKeyframeAnimation.init(keyPath: "opacity")
        animation.values = [0, 1]
        animation.duration = 0.5
        animation.calculationMode = CAAnimationCalculationMode.discrete
        animation.repeatCount = .greatestFiniteMagnitude

        attentionButton.layer?.add(animation, forKey: nil)
    }
    
    @IBAction func setToDefaultColors(_ sender: Any) {
        psTextView.resetAllColors()
    }
    
    /// Allows selection of an alternative convert in case any other was found
    /// - Parameter sender: Ignored
    @IBAction func changeSettings(_ sender: NSButton) {
        for pathAndArgument in alternateConverters {
            let path = pathAndArgument[0]
            if (psToPdfConverterPathComboBox.stringValue == path) {
                psToPdfConverterPath = path
                outputArgument = pathAndArgument[1]
            }
        }

        if !psToPdfConverterPath.isEmpty {
            sender.stringValue = psToPdfConverterPath
            let preferences = NSUserDefaultsController().defaults
            preferences.set(psToPdfConverterPath, forKey: "PsToPdfConverter")
            preferences.set(outputArgument, forKey: "PsToPdfConverterArg")
        }
        SyntaxColors.storeUndoColors()
        settingsWindow.close()
        psTextView.assignSyntaxColors()
    }
    
    @IBAction func cancelSettings(_ sender: NSButton) {
        SyntaxColors.retrieveUndoColors()
        settingsWindow.close()
    }
    
    func checkForChanges() {
        // Insert code here to tear down your application
        psTextView.checkToSaveChanges()
        addRecentItem(url: psTextView.psFileUrl.url)
        let preferences = NSUserDefaultsController().defaults
        
        recent2Menu.storeItems(preferences: preferences)
    }

    
}
