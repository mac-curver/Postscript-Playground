//
//  ViewController.swift
//  SimplePsViewer
//
//  Changed by LegoEsprit 2024-12-27 New GIT version
//  Created by LegoEsprit on 30.05.23.
//
/// ```
/// Preferences can be cleared by:
/// rm ~/Library/Preferences/de.LegoEsprit.Postscript-Playground.plist
/// and sandboxed:
/// rm ~/Library/Containers/de.LegoEsprit.Postscript-Playground/Data/Library/Preferences/de.LegoEsprit.Postscript-Playground.plist
/// ```

import Cocoa
import UniformTypeIdentifiers
import Symbols
import os.log



extension Bundle {
	/// Application name shown under the application icon.
	var applicationName: String? {
		object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
			object(forInfoDictionaryKey: "CFBundleName") as? String
	}
}



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
    
    @IBOutlet weak var psToPdfConverterPathComboBox: NSComboBox!
	@IBOutlet weak var psToPdfParameterComboBox: NSComboBox!
    @IBOutlet weak var ghostscriptVersionTextField: NSTextField!
    @IBOutlet var psTextView: PsEditView!
	@IBOutlet weak var psScrollView: NSScrollView!
	@IBOutlet weak var pdfView: ContextPdfView!
    
    @IBOutlet weak var verticalSplitter: NSSplitView!
    @IBOutlet weak var attentionButton: NSButton!
    
    @IBOutlet weak var delegate: AppDelegate!
	
	@IBOutlet weak var openButton: NSButton!
	@IBOutlet weak var columnRowLabel: NSTextField!
	@IBOutlet weak var encodingComboBox: NSComboBox!
	@IBOutlet weak var helpButton: NSButton!
	@IBOutlet weak var automaticallyComboBox: NSComboButton!
	
	//@IBOutlet weak var syntaxSegmentedControl: NSSegmentedControl!
    
	    
	
	/// Placeholder for the current ps2pdf convert
    var psToPdfConverter: GhostscriptVersion = GhostscriptVersion()
	
	
	/// Used to call the console with the ps2pdf converter
    var shell = Shell()
    
    /// As side effect the combobox is being adapted
    var autoMode = Mode.RunManually {
        didSet {
            switch autoMode {
            case .RunManually:
                automaticallyComboBox.image = NSImage(imageLiteralResourceName: "play.fill")
                automaticallyComboBox.toolTip = LocalizedString("Click Play to convert").string
                break
            case .RunAutomatically:
                automaticallyComboBox.image = NSImage(imageLiteralResourceName: "play")
                automaticallyComboBox.toolTip = LocalizedString("Runs in automatic mode").string
                break
            case .StopAutomatically:
                automaticallyComboBox.image = NSImage(imageLiteralResourceName: "stop")
                automaticallyComboBox.toolTip = LocalizedString("Runs in automatic stop mode").string
                break
            }
        }
	}
	
	/*
	/// Non optional index of the segment syntax control
	var segmentedSyntax: Int {
		if nil != syntaxSegmentedControl {
			return syntaxSegmentedControl.indexOfSelectedItem
		}
		else {
			return -1
		}
	}
	 */
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //popupMenu = NSMenu.init(title: "Context")
    }
    
	
	/// Returns a version string
	/// - Returns: Combined version number as String
	/// ```
	/// Combines the Bundle version with the PSEditView version into a single
	/// String.
	/// ```
    func version() -> String {
        """
        Bundle: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) \
        (\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String))
        Editor: \(PsEditView.version)
        """
    }
	
	/*
	 public class let willStartLiveScrollNotification: NSNotification.Name
	 public class let didLiveScrollNotification: NSNotification.Name
	 public class let didEndLiveScrollNotification: NSNotification.Name
	 */
	 
	/*
	/// Register scroll event to ease syntax coloring
	func registerForNotifications() {
		NotificationCenter.default.addObserver(self
			, selector: #selector(handleScrollNotification)
			, name: NSScrollView.didLiveScrollNotification
			, object: psScrollView
		)
	}

	@objc func handleScrollNotification(_ notification: NSNotification) {
		// We use a timer here to avoid scrolling to occur slugish
		//psTextView.invalidateSyntaxTimer()
		Logger.write("", className: className)
	}
	 */
	
	fileprivate func setPsToPdfConverterCombobox(_ successPath: String) {
		
        if psToPdfConverterPathComboBox.numberOfItems > 1 && psToPdfConverter.path.isEmpty {
			/// Start delayed as otherwise main window hides setting window
			_ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
				self.settingsWindow.makeKeyAndOrderFront(self)
			}
		}
		else {
            psToPdfConverterPathComboBox.stringValue = psToPdfConverter.path
            psToPdfConverterPathComboBox.selectItem(withObjectValue: psToPdfConverter.path)
            psToPdfParameterComboBox.stringValue = psToPdfConverter.argument
            psToPdfParameterComboBox.selectItem(withObjectValue: psToPdfConverter.argument)

            psToPdfConverter.store()
            
            if let url = URL(string: successPath) {
                setGhostscriptVersion(url)
            }
		}
	}
	
	fileprivate func resetColorsIfNotInitialized() {
		let preferences = UserDefaults.standard
		let notEmptyPreferences = preferences.string(forKey: "Initialized") ?? ""
		if notEmptyPreferences.isEmpty {
			preferences.set("Initialized", forKey: "Initialized")
			SyntaxColors.resetAllColors()
		}
	}
	
	/// Called after IB has been loaded checks whether a ps2Pdf converter is available and is doing
	/// some initial settings.
	override func viewDidLoad() {
		Logger.login(version(), className: className)
		Logger.write("Test viewDidLoad", className: className)
        


        super.viewDidLoad()
        attentionButton.wantsLayer = true                                       // to allow opacity animation
        psTextView.awakeFromNib()
        addLocalMonitor(for: psTextView)

        
        var successPath = ""
        psToPdfConverter.retrieve(successPath, "")
        psToPdfConverterPathComboBox.stringValue = psToPdfConverter.path
        psToPdfParameterComboBox.stringValue = psToPdfConverter.argument
        
        if !checkFileIsExecutable(successPath) {
            for pathAndArgument in GhostscriptVersion.alternativeConverters {
                if checkFileIsExecutable(pathAndArgument.path) {
                    psToPdfConverterPathComboBox.insertItem(withObjectValue: pathAndArgument.path, at: 0)
                    psToPdfParameterComboBox.insertItem(withObjectValue: pathAndArgument.argument, at: 0)
                    if successPath.isEmpty {
                        successPath = pathAndArgument.path                      // return first found
                        psToPdfConverterPathComboBox.stringValue = pathAndArgument.path
                        psToPdfParameterComboBox.stringValue = pathAndArgument.argument
                    }
                }
            }
        }
		
        if successPath.isEmpty {
            let alert = NSAlert()
            
            alert.alertStyle = .critical
            alert.messageText = String(localized: "No ps to pdf converter could be found")
            alert.informativeText = String(localized:
				"InstallGhostScriptKey"
				, defaultValue: """
						Please install either the Xcode tools (only Ventura)
						or alternatively Ghostscript using
						Macports or Homebrew.
						The App should be closed now!
						"""
				, comment: "Multiline text"
            )
            alert.addButton(withTitle: String(localized: "Quit"))
            alert.addButton(withTitle: String(localized: "Enter ps converter path"))
            //alert.addButton(withTitle: "Xcode in App Store")
            //alert.addButton(withTitle: "GS for Mac Ports")
            //alert.addButton(withTitle: "GS for Homebrew")
            alert.showsHelp = true
            let helpAnchor = "Prerequisites"
            alert.helpAnchor = helpAnchor
            
            switch alert.runModal() {
			case NSApplication.ModalResponse.alertSecondButtonReturn:
				/// We need at least a single entry
				psToPdfConverterPathComboBox.addItem(withObjectValue: "")
				/// Start delayed as otherwise main window hides setting window
				_ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
					self.settingsWindow.makeKeyAndOrderFront(self)
				}

			/*
            case NSApplication.ModalResponse.alertSecondButtonReturn:
                if let url = URL(string: "https://apps.apple.com/de/app/xcode/id497799835?ls=1&mt=12") {
                    NSWorkspace.shared.open(url as URL)
                }
            case NSApplication.ModalResponse.alertThirdButtonReturn:
                if let url = URL(string: "https://ports.macports.org/port/ghostscript/") {
                    NSWorkspace.shared.open(url as URL)
                }
			 */
			case NSApplication.ModalResponse.alertFirstButtonReturn:
				exit(-1)
            default:
                //if let url = URL(string: "https://formulae.brew.sh/formula/ghostscript#default") {
                //    NSWorkspace.shared.open(url as URL)
                //}
                exit(-1)
            }
        }
        
		resetColorsIfNotInitialized()
        SyntaxColors.storeUndoColors()
        
        attentionButton.isHidden = true
        
		for encoding in allPossibleEncodings {
			encodingComboBox.addItem(withObjectValue: encoding.description)
		}
        
        // The following is used only when syntax coloring takes lot of time
		//registerForNotifications()
		
        Logger.logout("", className: className)

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
		delegate = appDelegate
        psTextView.viewController = appDelegate.viewController                  /// copy the view controller down the hierarchy
		self.fileNew(NSMenuItem())
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
	
	
	/// Hides bottom controls according to their priority
	/// - Parameter availableWidth: The width of the visibleRect of the owner
	/// ```
	///	Impossible to use constraints as then collapsing the editor is not possible anymore!
	/// ```
	func resizePsEditView(availableWidth: Double) {
		let factor = 1.2 // instead of the exact spacing
		let allControls:[NSView] = [
			                 encodingComboBox			// low priority
						   , helpButton
						   , columnRowLabel
						   , openButton
						   , automaticallyComboBox 		// high priority
						   ]
	
		for (index, control) in allControls.enumerated() {
			control.isHidden = availableWidth < allControls[index...].reduce(
										0, { sum, element in
											sum + element.frame.width
										} ) * factor
		}

	}
	
	
	/// Modifies the combobox to display the encoding of the file
	/// - Parameter item: Text encoding as String
	func setEncoding(item: String) {
		encodingComboBox.selectItem(withObjectValue: item)
	}
	
	func runOpenConverterPanel(_ inFile: inout URL
							  , with selected: String = ""
	)->NSApplication.ModalResponse {
		Logger.login("", className: className)
		let openPanel = NSOpenPanel()
			
		let openMessage = String(localized: "Please select a ps to pdf converter")
        openPanel.resolvesAliases         = true
		openPanel.message                 = openMessage
		openPanel.showsResizeIndicator    = true
		openPanel.showsHiddenFiles        = true                                // required to browse /bin etc.
		openPanel.canChooseFiles          = true
		openPanel.canChooseDirectories    = false
		openPanel.canCreateDirectories    = false
		openPanel.allowsMultipleSelection = false
		openPanel.allowedContentTypes     = [UTType.unixExecutable]
		openPanel.directoryURL            = inFile.deletingLastPathComponent()
		openPanel.nameFieldStringValue    = inFile.lastPathComponent
		
		Logger.write("\(openPanel.nameFieldLabel ?? "None"), \(openPanel.nameFieldStringValue)", className: className)

		let response = openPanel.runModal();
		inFile = openPanel.url ?? URL(filePath: "")
		Logger.logout("", className: className)
		return response
	}


    
	

	/// File: Save - Menu actions
	/// - Parameter sender: Menu item not used
    @IBAction func savePsFile(_ sender: NSMenuItem) {
        _ = psTextView.saveFileToPsUrl()
    }
    
	/// File: SaveAs - Menu actions
	/// - Parameter sender: Menu item not used
    @IBAction func savePsFileAs(_ sender: NSMenuItem) {
        _ = psTextView.savePsFileAs()
		_ = delegate.addRecentItem(url: psTextView.psFileUrl.url)
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
    

    
    /// open recent file
    /// - Parameter sender: The recent menu item selected
    ///
    /// Retrieves the Postscript and PDF file names an opens the Postscript file and converts it
	func openRecentFile(sender: NSMenuItem) {
        Logger.login("\(sender.title)", className: className)

        if let item: RecentMenuItem = sender as? RecentMenuItem {
    
            if let psUrl = psTextView.openSecurityScopedResource(bookmark: item.menuItem.secureData) {
                setPdfPath(urlForPrefix: item.menuItem.pdfUrl)
                convertPsToPdf()
                // Release the file-system resource when you are done.
                psUrl.stopAccessingSecurityScopedResource()

                if shell.stderr.starts(with: "Operation not permitted:") {
                    if let url = psTextView.openFileWithOpenDialog(selected: psUrl.absoluteString) {
                        openFileUrl(url)
                        convertPsToPdf()
                    }
                }
            }
			if !window.isVisible {
				window.orderFront(self)
			}

        }
        Logger.logout("\(sender.title)", className: className)
    }
	
	/// Opens the sample file from the bundle according to the selected menu item
	/// - Parameter sender: Yields the selected file name
    func openSampleFile(sender: NSMenuItem) {
        let fileName: NSString = NSString(string: sender.title)
        if let path = Bundle.main.path(
			forResource: fileName.deletingPathExtension
			, ofType: "ps"
		) {
            Logger.write(path, className: className)
			let url = URL(filePath: path)
			openFileUrl(url, addToRecent: false)
			convertPsToPdf()
        }
    }
	    
    
    /// Opens the Postscript file from URL
    /// - Parameter resultUrl: URL of the Postscript file
    /// - Parameter addToRecent: If true(default) adds the item to the bookmarked list of recent
    /// Opens and converts the Postscript file.
    /// Copies the base name to the PDF view as name proposal.
    func openFileUrl(_ resultUrl: URL, addToRecent: Bool = true) {
        Logger.login("\(resultUrl)", className: className)
        do {
            let resolved = try URL(resolvingAliasFileAt: resultUrl, options: [])
            psTextView.psFileUrl = FileUrl(url: resolved, knownToFileManager: true)
        }
        catch {
            Logger.write("Can't resolve alias from \(resultUrl.path)")
        }

        if psTextView.openFileUrlAsPs(url: resultUrl) {
            setPdfPath(urlForPrefix: resultUrl)
            if addToRecent {
				_ = delegate.addRecentItem(url: resultUrl)
            }
        }
        else {
            window.title = "unknown"
        }
		if !window.isVisible {
			window.orderFront(self)
		}
        Logger.logout("", className: className)
    }
    
    fileprivate func setGhostscriptVersion(_ url: URL) {
        let pathOnly = url.deletingLastPathComponent().relativePath
        ghostscriptVersionTextField.stringValue = GhostscriptVersion.get(from: pathOnly) ?? "- - -"
    }

    
    /// Calls the file open dialog to open a Postscript file
    /// - Parameter sender: Ignored
    @IBAction func openFileWithOpenDialog(_ sender: Any) {
        if let url = psTextView.openFileWithOpenDialog(selected: "") {
            openFileUrl(url)
            convertPsToPdf()
        }
    }
	
	/// Takes an array of URLs and opens the first one as .ps file
	/// - Parameter urls: Array of URLs delivered by the system API
    func openAndConvert(_ urls: [URL]) {
		Logger.login("", className: className)
		if let url = urls.first {
			Logger.write("Open file \(url.absoluteString)", className: className)
            openFileUrl(url)
            startDelayedConversion()
        }
        if urls.count > 1 {
            tooManyFilesAlert()	// Currently only a single file is supported
        }
		Logger.logout("", className: className)
    }
    
    /// Shows an alert stating that the app can only open a single file at a time
    func tooManyFilesAlert() {
        let alert = NSAlert()
        
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Only a single file can be opened at a time")
        alert.informativeText = String(
			localized: "OnlySingleFileKey"
			, defaultValue: """
                This app allows to edit a single .ps at a time. Only
                the first selected file is being opened for editing.
                """
		)
        _ = alert.runModal()
    }

	
	/// Checks for changes in the current file and opens the "New" file
	/// - Parameter sender: Menu item not used
    @IBAction func fileNew(_ sender: NSMenuItem) {
        window.title = "Postscript Playground"
        setPdfPath(urlForPrefix: URL(filePath: "Untitled.pdf"))
		pdfView.clearPdf()
        psTextView.newFile()
		if !window.isVisible {
			window.orderFront(self)
		}
    }
    
    /// Opens an alert to display the Postscript error
    /// - Parameter sender: Ignored
    @IBAction func openErrorButtonDisplay(_ sender: NSButton) {
        let alert = NSAlert()
        
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Postscript file couldn't be converted")

		alert.informativeText = shell.stdout.abbreviate(limitCount: 250, prefix: 200)
                                + "\n"
		                        + shell.stderr.abbreviate(limitCount: 250)
        alert.runModal()
    }
    
    /// Help button action
    /// - Parameter sender: Ignored
    @IBAction func helpWithBrowser(_ sender: Any) {
        Logger.login("", className: className)
        //let availableLocalizations = Bundle.main.localizations
        var language = Locale.current.language.languageCode
        switch language {
        case "en":
            language = "Base"
        default:
            break
        }
        if let language = language
           , let myFileUrl = Bundle.main.url(
                forResource:"Postscript PlaygroundHelp"
                , withExtension: "html"
                , subdirectory: "HelpFolder/\(language).lproj"
            ) {
                NSWorkspace.shared.open(myFileUrl)
            }
        Logger.logout("", className: className)
    }
    
    /*
    @IBAction func showHelp(_ sender: Any?) {
        HelpWindow.create(starting: "Postscript PlaygroundHelp")
    }
    */
    
    @IBAction func helpForConverterPath(_ sender: Any) {
        //HelpWindow.create(starting: "HelpContent/Prerequisites")
    }
    
    /// Help action
    /// - Parameter sender: Ignored
    @IBAction func helpAction(_ sender: Any) {
        Logger.login("", className: className)
        /// Could not find any description on how to build a help file bumdle
        if  let bookName = Bundle.main.object(
                                forInfoDictionaryKey: "CFBundleHelpBookName"
                            ) as? String {
            NSHelpManager.shared.openHelpAnchor("Postscript PlaygroundHelp", inBook: bookName)
        }
        Logger.logout("", className: className)
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
    
	
	/// Set the pathes for the PDF view
	/// - Parameter urlForPrefix: Path from open, recent or new
    func setPdfPath(urlForPrefix: URL) {
		Logger.login("\(urlForPrefix)", className: className)
        pdfView.setPathes(urlForPrefix: urlForPrefix)
		Logger.logout("", className: className)
    }
    
	
	/// Setter for the column and row label at the bottom of the window
	/// - Parameter line: Text with the line and column
    func setColumnRow(line: String) {
        columnRowLabel.stringValue = line
    }

    
	
	/// As conversion requires some time we use a timer to execute the PDF conversion delayed
    func startDelayedConversion() {
        Logger.login("", className: className)
        _ = Timer.scheduledTimer(timeInterval: 2.5
                                     , target: self
                                     , selector: #selector(fireTimer)
                                     , userInfo: nil
                                     , repeats: false
        )
        Logger.logout("", className: className)
    }
    
    
    /// fireTimer was restarted for autosave and syntax highlighting.
    /// Recolors according to syntax and in case of autosave mode converts to pdf like a
    /// playground.
    @objc func fireTimer() {
        convertPsToPdf()
            
        Logger.write("The delayed conversion timer was fired", className: className)
    }

    
    
    /// Here the real magic happens. This method calls the ps2Pdf converter command line tool.
    func convertPsToPdf() {
        Logger.login("", className: className)
        autoStarting()

        window.title = psTextView.psFileUrl.url.lastPathComponent
		
        let argumentArray = [  psTextView.psFileUrl.url.path_fallback
                               , psToPdfConverter.argument
                               , pdfView.tempFileUrl.path_fallback
		                    ].filter { !$0.isEmpty }
	
		
        shell = Shell(URL(filePath: psToPdfConverter.path)
                      , arguments: argumentArray
        )


        if shell.stderr.isEmpty {
            attentionButton.isHidden = true
            pdfView.openTempFileUrlAsPdf();
        }
        else {
            Logger.write(shell.stdout, className: className)
            Logger.write(shell.stderr, className: className)
            attentionButton.isHidden = false
            //let imageView = NSImageView(image: attentionButton.image!)
            //imageView.addSymbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
            //attentionButton.symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
        }
        
        autoFinished()
        Logger.logout("", className: className)
    }
    
	
	/// Calls check to save changes and sets saved to true.
	/// Must be called when window was closed
	func closeWindow() {
		psTextView.checkToSaveChanges()
		psTextView.saved = true
	}



    
    /// Checks if app exists
    /// - Parameter filePath: Path of the app
    /// - Returns: true in case a file with filePath is executable
    func checkFileIsExecutable(_ filePath: String)->Bool {
		let extended = NSString(string: filePath).expandingTildeInPath
        return FileManager.default.isExecutableFile(atPath: extended)
    }
    
  
    /// Adds blinking animation to the attention button
    func addAnimationToAttentionButton() {
        let animation = CAKeyframeAnimation.init(keyPath: "opacity")
        animation.values = [0.0, 0.5, 1.0, 0.5, 0.0]
        animation.duration = 0.7
        animation.calculationMode = CAAnimationCalculationMode.cubic
        animation.repeatCount = .greatestFiniteMagnitude

        attentionButton.layer?.add(animation, forKey: nil)
    }
    
	
	/*
	/// Used to show and hide the syntaxSegmentedControl.
	/// - Parameter event: Event to retrieve the mouse position
	/// ```
	/// Shows the syntaxSegmentedControl by setting its alpha to 1.0 and
	/// hides the control using a fading animation.
	/// ```
	override func mouseMoved(with event: NSEvent) {
		if syntaxSegmentedControl.frame.insetBy(dx: -20, dy: -20).contains(event.locationInWindow) {
			syntaxSegmentedControl.animator().alphaValue = 1
		}
		else {
			// fade out animation
			NSAnimationContext.runAnimationGroup( {
				context in
				context.duration = 2.5
				syntaxSegmentedControl.animator().alphaValue = 0
			})
		}
	}
	 */
	
   

    /// Resets colors to factory settings
    /// - Parameter sender: Not used
    @IBAction func setToDefaultColors(_ sender: Any) {
        SyntaxColors.resetAllColors()
    }
    
    func selectPs2PdfConverter() -> URL{
        var converterUrl = URL(filePath: psToPdfConverter.path)
        let start = "/"
        let response = runOpenConverterPanel(&converterUrl, with: start)
        switch response {
            case NSApplication.ModalResponse.OK:
                psToPdfConverterPathComboBox.insertItem(withObjectValue: converterUrl.path(), at: 0)
                psToPdfConverterPathComboBox.selectItem(at: 0)
            default:
                break
        }
        psToPdfConverterPathComboBox.stringValue = converterUrl.relativePath
        return converterUrl
    }

    
    @IBAction func browsePsToPdfConverter(_ sender: NSComboBox) {
        var converterUrl: URL
        
        switch sender.indexOfSelectedItem {
            case sender.numberOfItems - 1:
                converterUrl = selectPs2PdfConverter()
            default:
                converterUrl = URL(filePath: sender.stringValue)
        }
        
        setGhostscriptVersion(converterUrl)
        
        for converter in GhostscriptVersion.alternativeConverters {
            if converter.path == sender.stringValue {
                // set "-o" or "" correctly if it is known!
                psToPdfParameterComboBox.stringValue = converter.argument
            }
        }
        sender.stringValue = converterUrl.relativePath
    }

	
	/// Allows selection of an alternative ps converter in case any other was found
    /// - Parameter sender: Ignored
    @IBAction func changeSettings(_ sender: NSButton) {
        psToPdfConverter.path = psToPdfConverterPathComboBox.stringValue
		let argument = psToPdfParameterComboBox.stringValue
        psToPdfConverter.argument = argument

        psToPdfConverter.store()
        SyntaxColors.storeUndoColors()
        settingsWindow.close()
		NSColorPanel.shared.close()

        psTextView.assignSyntaxColors()
    }
	
	/// Respond to cancel action for the settings dialog
	/// - Parameter sender: Sender button not used
    @IBAction func cancelSettings(_ sender: NSButton) {
        SyntaxColors.retrieveUndoColors()
        settingsWindow.close()
    }
    
}


extension ViewController: NSWindowDelegate {
		
	/// Responds to window delegate to check if file contains non saved changes
	/// - Parameter sender: Window not used
	/// - Returns: Always true
	@MainActor
    func windowShouldClose(_ sender: NSWindow) -> Bool {
		Logger.login("", className: className)
		closeWindow()
		Logger.logout("", className: className)
		return true
	}
    

}

/// add "Show in Finder" context menu
extension ViewController {
    
    /// Add an event listener to catch right clicks in window title to display context menu
    func addLocalMonitor(for view: PsEditView) {
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let window = self?.window
                , event.window == window else {
                return event
            }
            
            let localPoint = window.contentView?.convert(event.locationInWindow, from: nil)
            
            if let point = localPoint, window.contentView?.bounds.contains(point) == false {
                
                let menu = NSMenu()
                var item: NSMenuItem
                let isKnown = view.psFileUrl.knownToFileManager
                if isKnown {
                    item = NSMenuItem(title: "Show in Finder", action: #selector(self!.showInFinder(_:)), keyEquivalent: "")
                }
                else {
                    item = NSMenuItem(title: "File not yet stored", action: nil, keyEquivalent: "")
                }
                
                item.target = self
                menu.addItem(item)

                menu.popUp(positioning: item, at: point, in: window.contentView)
            }
            return event
        }

    }
    
    @objc func showInFinder(_ sender: NSMenuItem) {
        Logger.write(psTextView.psFileUrl.url.absoluteString)
        NSWorkspace.shared.activateFileViewerSelecting([psTextView.psFileUrl.url])
    }
    
    
    
    
}


