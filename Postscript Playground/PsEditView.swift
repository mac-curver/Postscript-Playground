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
//import Carbon.HIToolbox

/// Here all useful encodings are listed - I got some ps files from PC with different encoding
public let allPossibleEncodings: [String.Encoding] = [
	    .utf8
	  , .isoLatin1
	  //, .ascii
	  //, .isoLatin1
	  //, .macOSRoman
	  //, .nonLossyASCII
	  //, .isoLatin2
	  //, .unicode
	  //, .windowsCP1251
	  //, .windowsCP1252
	  //, .windowsCP1253
	  //, .windowsCP1254
	  //, .windowsCP1250
	  //, .iso2022JP
	  //, .nextstep
	  //, .japaneseEUC
	  //, .shiftJIS
	  //, .utf16
	  //, .utf16BigEndian
	  //, .utf16LittleEndian
	  //, .utf32
	  //, .utf32BigEndian
	  //, .utf32LittleEndian
	  //, .symbol
]



/// Extension to the `String` protocol to retrieve the character at index
extension StringProtocol {
    /// subscript the `String`
    ///
    /// - parameter offset:    	The index of the character we want to get from the `String`.
    /// - returns:            	Character` at the offset position in the `String`.
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

/// Extension to the `Double` type to print exactly 6 fractional digits
extension Double {
	
	/// Numberformatter to print double with specific number of digits
	/// - Parameters:
	///   - digits: Number of fractional digits - Defaults to 6
	///   - minDigits: Minimum number of fractional digits. If not given the number of fractional
	///   digits is fixed to digits. - Defaults to nil!
	/// - Returns: Output of double number with a specified number of factional digits
	/// as NumberFotmatter
	static func fractionalDigits(digits: Int = 6, minDigits: Int? = nil) -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		if let minDigits = minDigits {
			formatter.minimumFractionDigits = minDigits
		}
		else {
			formatter.minimumFractionDigits = digits
		}
		formatter.maximumFractionDigits = digits
		return formatter
	}
	
	/// Returns a number formatter for exactly 6 fractional digits
    static let sixFractionalDigits: NumberFormatter = {
		return fractionalDigits(digits: 6)
	}()
	
	/// Outputs the double number with exactly 6 fractional digits
    var formatted: String {
        return Double.sixFractionalDigits.string(for: self) ?? "-.------"
    }
}



/// PsEditView overwritten NSTextView used to convert .ps file into .pdf
class PsEditView: NSTextView /* see protocol extensions below*/ {
		
	/// FileUrl to store the url and whether the file has already been open with a file dialog
    struct FileUrl {
        var url:URL
        var knownToFileManager: Bool
    }
    
    /// version number of PsEditView
    static let version = "2.2.0"
    var viewController: ViewController!
	
	//let commandQueue = DispatchQueue.global(qos: .utility)
	//var backGroundIsRunning = false
	

    
    /// Only .ps files are allowed
	let expectedExt = ["ps"]
	/// The postscript unified type identifier is required for storage
    let postScriptUTType = UTType("com.adobe.postscript")!
    
    /// Timer used for automatic conversion and delayed syntax highlighting
	var timer: Timer = Timer()
	//var syntaxTimer: Timer = Timer()
	
	/// Url for the .ps text file
	var psFileUrl: FileUrl
	/// Default path to store the .ps text file from save dialog
    let homeDir = FileManager.default.urls(
        for: FileManager.SearchPathDirectory.documentDirectory
        , in: FileManager.SearchPathDomainMask.userDomainMask
    ).first!

    /// true whenever changes were applied
    var saved = true
    /// Auto saving when in live mode
    var autoSave = false


    /// init to initialize the required fields  `String` to `OutputStream`
    ///
    /// - parameter coder:                  Propagated to super.
    ///
    /// ```
	/// Calls its super class init sets the background and registers for drop
	/// ```
    required init?(coder: NSCoder) {
        psFileUrl = FileUrl(
              url: homeDir.appendingPathComponent(
                              "Untitled.ps"
                            , conformingTo: postScriptUTType
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
        //initializeSyntaxColors()
        Logger.logout("init?")
    }
	
	/// releadWithEncoding Can be used to re-read the file with different encoding
	/// - Parameter sender: ComboBox with all file encodings
	@IBAction func releadWithEncoding(_ sender: NSComboBox) {
		//let array = ViewController.all
		let encoding = allPossibleEncodings[sender.indexOfSelectedItem]
		_ = openFileWithEncoding(encoding, showAlert: true)
	}
	
	/// Respond to chages of the syntax segmented control
	/// - Parameter sender: Segemented control for 3 syntax algos
	/// ```
	/// This very likely will be removed later, when the most effective
	/// version has been identified!
	/// ```
	@IBAction func syntaxCodeChanged(_ sender: NSSegmentedControl) {
		textStorage?.removeAttribute(.foregroundColor, range: NSMakeRange(0, string.count-1))
		assignSyntaxColors(syntax: viewController.segmentedSyntax)
	}
	
	/// awakeFromNib initializes a monospaced font for the .ps text editor
    override func awakeFromNib() {
        Logger.login("", className: className)
        font = NSFont(name: "Monaco", size: 11)
        //isRulerVisible = true
        Logger.logout("", className: className)
    }
	
    
	/// setPathes calculates the pdf and ps pathes from a root `URL`
	/// - parameter urlForPrefix:           The  root `URL` for the pdf or ps.
	/// - parameter known: 	True if already opened with a open or save dialog to allow to
	/// 					cope with Apple security
    func setPathes(urlForPrefix: URL, known: Bool) {
        Logger.login("\(urlForPrefix)", level: OSLogType.default, className: className)
        let pathPrefix = urlForPrefix.deletingPathExtension()
        psFileUrl = FileUrl(url: pathPrefix.appendingPathExtension("ps")
                            , knownToFileManager: known
        )
        Logger.logout("\(psFileUrl)", level: OSLogType.default, className: className)
    }
	
	/// showRuler Displays or removes ruler according to menu item state
	/// - Parameter sender: The menu item with checkmark
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

		//let suffix = URL(fileURLWithPath: path).pathExtension
		let suffix = URL(string: path)!.pathExtension

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
    /// ```
	/// Running in the main thread. Unfortunately checking the extension
    /// here does not work completely, therefore we need to overwrite
    /// also draggingUpdated!
	/// ```
    @MainActor
    override func draggingEntered(_ dragInfo: NSDraggingInfo) -> NSDragOperation {
        return checkExtension(dragInfo)
    }

    /// draggingUpdated returns the .copy if file extension is .ps
    /// - parameter dragInfo:               The drag info from the system.
    /// - returns:                          See checkExtension
    /// ```
    /// Continously called during drag operation in the main thread.
	/// ```
    @MainActor
    override func draggingUpdated(_ dragInfo: NSDraggingInfo) -> NSDragOperation {
        return checkExtension(dragInfo)
    }


    /// performDragOperation performs the drag operation
    /// Continously called during drag operation in the main thread.
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
		if let url = URL(string: path) {
			viewController?.openFileUrl(url)
			if pasteboard.count > 1 {
				viewController?.tooManyFilesAlert()
			}
			viewController?.convertPsToPdf()
		}
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
	
	
	/// Called when editor widow was resized
	/// - Parameter oldSize: Not used
	override func resize(withOldSuperviewSize oldSize: NSSize) {
		viewController?.resizePsEditView(availableWidth: self.visibleRect.width)
	}
	


    /// mouseDown used to caluculate the text position in the ps file
    ///
    /// - parameter event: The system ´NSEvent´.
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        setColumnAndRow()
    }

    
    /// keyDown used to restart the timer for autosave and syntax highligthing
    /// - parameter event: The system ´NSEvent´.
    ///
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        setColumnAndRow()
    }
    
    /// Text did change notification from OS
    /// - Parameter notification: Not used
    /// ```
    /// Indicates, that the file contents should be changed and starts a
	/// 2 s timer.
	/// ```
    func textDidChange(_ notification: Notification) {
        saved = false
		if let swiftRange = Range(selectedRange(), in: string) {
			let swiftLineRange = string.lineRange(for: swiftRange)
			let nsLineRange = NSRange(swiftLineRange, in: string)
			let lineString = String(string[swiftLineRange])
			removeAttributesInLine(nsLineRange)
			assignSyntaxColorToLine(lineString
									, nsStartDistance: nsLineRange.location
									, syntax: viewController.segmentedSyntax
			)
		}
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2
                                     , target: self
                                     , selector: #selector(textDidChangeTimerFired)
                                     , userInfo: nil
                                     , repeats: false
        )
    }
	
    
    
    /// timerFired was restarted for autosave.
    /// In case of autosave mode converts ps to pdf (likewise a playground).
    @objc func textDidChangeTimerFired() {
        Logger.login("", className: className)
        if autoSave {
            if saveFileToPsUrl() {
                viewController?.convertPsToPdf()
				Logger.write("File was saved and converted as Timer was fired")
            }
        }
		Logger.logout("", className: className)
    }
	
	static var syntaxTimerRunning = false
	
    
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
        //let start = ProcessInfo.processInfo.systemUptime;
        var indexStarts:[String.Index] = []

        var index = string.startIndex
        indexStarts.append(index)
        while index != string.endIndex {
            let range = string.lineRange(for: index..<index)
            index = range.upperBound
            indexStarts.append(index)
        }
        //Logger.write("Using String.Index:\(ProcessInfo.processInfo.systemUptime-start) s")
        return indexStarts
    }
    
    /// lineNumber calculates the cursor position line/offset
    /// - Returns: doublet with line number, horizontal offset
    func lineNumber() -> (Int, Int) {
        //let start = ProcessInfo.processInfo.systemUptime;
        let selectionRange: NSRange = selectedRange()
        let regex = try! NSRegularExpression(pattern: "\n", options: [])
        let lineNumber = regex.numberOfMatches(in: string, options: [], range: NSMakeRange(0, selectionRange.location))
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
            
        let openMessage = String(localized: "Please choose a .ps file to be converted to pdf")
        openPanel.message                 = openMessage
        openPanel.showsResizeIndicator    = true
        openPanel.showsHiddenFiles        = false
        openPanel.canChooseFiles          = true
        openPanel.canChooseDirectories    = false
        openPanel.canCreateDirectories    = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes     = [postScriptUTType]
        openPanel.directoryURL            = inFile.deletingLastPathComponent()
        openPanel.nameFieldStringValue    = inFile.lastPathComponent
        
        Logger.write("\(openPanel.nameFieldLabel ?? "None"), \(openPanel.nameFieldStringValue)", className: className)

        let response = openPanel.runModal();
        inFile = openPanel.url ?? URL(string: "")!
        Logger.logout("", className: className)
        return response
    }
    
    /// Creates a very simple .ps file
    ///
    /// In case the bundle access fails a hard coded file is being used!
    func newFile() {
		checkToSaveChanges()
        let fileUrl = Bundle.main.url(forResource:"New", withExtension: "ps")
		textStorage?.setAttributedString(NSAttributedString(string: ""))		/// Clear any pending attributes.
        do {
			string = try String(contentsOf: fileUrl ?? URL(string: "")!
								, encoding: .utf8
						 )
        }
        catch {
			string = """
					%!PS
					
					/test 7 8 9.0 add add def
					/Times-Bold findfont 36 scalefont setfont
					72 684 moveto (Hello World!) show
					4 setlinewidth
					0 -4 rmoveto
					72 680 lineto stroke
					showpage
					"""
        }
		
		setPathes(urlForPrefix: URL(string: "Untitled.ps")!, known: false)
		assignSyntaxColors(syntax: viewController.segmentedSyntax)
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
        default:
            break
        }
        return response == NSApplication.ModalResponse.OK

    }

    
	/// Copies contents of the file to self.string to display it.
	/// - Parameter fileEncoding: character encoding used to try decoding
	/// - Parameter showAlert: if YES shows alert
	/// - Returns: true if new file was opened successfully
	fileprivate func openFileWithEncoding(_ fileEncoding: String.Encoding
										  , showAlert: Bool) -> Bool
	{
		Logger.login("", className: className)
		var opened = false

		do {
			textStorage?.setAttributedString(NSAttributedString(string: ""))
			string = try String(contentsOf: psFileUrl.url
								, encoding: fileEncoding
			             )
			Logger.write("3", className: className)
			assignSyntaxColors(syntax: viewController.segmentedSyntax)
			Logger.write("4", className: className)
			opened = true
		}
		catch {
			if showAlert {
				Logger.write("Open file failed with "
							 + "\(error.localizedDescription)"
							 , level: OSLogType.error, className: className
				)
				let alert = NSAlert()
				
				alert.alertStyle = .critical
				alert.messageText = String(localized:
											"""
											Postscript \
											\(psFileUrl.url.absoluteString) \
											could not be loaded
											"""
									)
				alert.informativeText = "\(error.localizedDescription)"
				_ = alert.runModal()
			}
		}
		Logger.write("5", className: className)
		Logger.logout("", className: className)
		return opened
	}
		
	
	/// Try different encodings to open the .ps text file
	/// - Parameter opened: Returns true if opened successfully
	fileprivate func string1(_ opened: inout Bool) {
		profile.measure(className: className, {
			if let data = NSData(contentsOf: psFileUrl.url) {
				// try different encondings
				for encoding in allPossibleEncodings {
					if let myString = String(data: data as Data, encoding: encoding) {
						string = myString
						viewController.setEncoding(item: encoding.description)
						assignSyntaxColors(syntax: viewController.segmentedSyntax)
						opened = true
						break
					}
				}
			}
		})
	}
	
	/// Try different encodings to open the .ps text file
	/// - Parameter opened: Returns true if opened successfully
	fileprivate func string2(_ opened: inout Bool) {
		profile.measure(className: className, {
			// Open the file independently of its encoding!
			let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [:]
			var dict: NSDictionary? = [:]
			do {
				let myString = try NSAttributedString(
					url: psFileUrl.url
					, options: options
					, documentAttributes: &dict
				)
				let encoding = String.Encoding(
					rawValue: (dict?.value(forKey: "CharacterEncoding"))! as! UInt
				)
				viewController.setEncoding(item: encoding.description)
				
				string = myString.string
				assignSyntaxColors(syntax: viewController.segmentedSyntax)
				opened = true
			}
			catch {
				Logger.write("\(error)")
				string = ""
				Logger.write("Open file failed with \(error.localizedDescription)"
							 , level: OSLogType.error
							 , className: className
				)
				let alert = NSAlert()
				
				alert.alertStyle = .critical
				alert.messageText = String(
					localized: "PSNotLoadedKey"
					, defaultValue: """
							Postscript file \
							\(psFileUrl.url.myPath) \
							could not be loaded
							"""
				)
				alert.informativeText = "\(error.localizedDescription)"
				_ = alert.runModal()
			}
		})
	}
	
	/// Try different encodings to open the .ps text file
	/// - Parameter opened: Returns true if opened successfully
	fileprivate func string3(_ opened: inout Bool) {
		// about 5-10 faster than string 1 and string2
		profile.measure(className: className, {
			for fileEncoding in allPossibleEncodings  {
				opened = openFileWithEncoding(fileEncoding
											  , showAlert: fileEncoding == allPossibleEncodings.last
				)
				if opened {
					viewController.setEncoding(item: fileEncoding.description)
					break
				}
			}
		})
	}
	
	/// Copies contents of the file to self.string to display it by using openFileWithEncoding.
    /// - Returns: true if new file was opened successfully
	fileprivate func openFilePrivate() -> Bool {
        Logger.login("", className: className)
		var opened: Bool = false
        saved = true
		
		//string1(&opened)
		//string2(&opened)
		string3(&opened)
		
        Logger.logout("\(string.count)", className: className)
        return opened
    }
    
    /// Displays an alert to offer to save the changes in case document has been changed
    func checkToSaveChanges() {
		Logger.login("\(saved ? "saved": "not saved")", className: className)
        if !saved {
            let alert = NSAlert()
            
            alert.alertStyle = .warning
            alert.messageText = String(localized:
									"Changes to Postscript file were not saved"
			                    )
            alert.informativeText = String(localized:
                        """
                        The current file contains changes, that
                        were not yet stored onto the disk!
                        """
			)
            alert.addButton(withTitle: String(localized: "Save the changes"))
            alert.addButton(withTitle: String(localized: "Ignore and don't save"))
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                Logger().log("Save changes")
                _ = saveFileToPsUrl()
            default:
                break
            }
        }
		Logger.logout("", className: className)
    }
    
	/// revert to stored file
	/// - Returns: true if loading did succeed
    func revert() -> Bool {
		return openFilePrivate()
    }
    
    /// openFileUrlAsPs load file and apply syntax coloring
    /// - Returns: true if loading did succeed
    func openFileUrlAsPs(url: URL) -> Bool {
        Logger.login("\(url)", className: className)
        checkToSaveChanges()
        setPathes(urlForPrefix: url, known: true)

		let success = openFilePrivate()
        if success {
            Logger.write("will be converted", className: className)
        }
        Logger.logout("", className: className)
        return success
    }
    
	/// openSecurityScopedResource is needed to re-open a file that has been opened in a session
	/// before due to Apples security limitations.
	/// - Parameter bookmark: stored file security state
	/// - Returns: URL as optional
    func openSecurityScopedResource(bookmark: Data) -> URL? {
        Logger.login("", className: className)
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
				checkToSaveChanges()
                setPathes(urlForPrefix: bookmarkedUrl!, known: true)
				let success = openFilePrivate()
                if success {
                    Logger.write("will be converted", className: className)
                }
            }
            
        }
        catch {
            Logger.write("Reading bookmark failed: \(error)"
						 , level: OSLogType.error
						 , className: className
			)
        }
        Logger.logout("", className: className)
        return bookmarkedUrl
    }
	
	/// saveFileTo Store a file to absolute path
	/// - Parameter path: Absolute path to store the file
	/// - Returns: true if file was stored successfully
    func saveFileTo(path: String) -> Bool {
        
        Logger.login("\(path)", level: OSLogType.default, className: className)
        var success = false
        do {
            try string.write(toFile: path
                             , atomically: true
                             , encoding: .utf8
            )
			
            success = true
			viewController.setEncoding(item: String.Encoding.utf8.description)
        } catch {
            let alert = NSAlert()
            
            alert.alertStyle = .warning
            alert.messageText = String(localized: "Postscript file couldn't be saved")
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        Logger.logout("\(success)", level: OSLogType.default, className: className)
        return success
    }
    
    /// saveFileToPsUrl load file and apply syntax coloring
	/// - Returns: true if file was stored successfully
    func saveFileToPsUrl() -> Bool {
        Logger.write("\(psFileUrl)", className: className)
        if psFileUrl.knownToFileManager {
            saved = saveFileTo(path: psFileUrl.url.myPath)
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
            , title: String(localized: "Write to Postscript file")
            , fileType: postScriptUTType
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
	
	/// Getter for the current context (avoids deprecation)
	private var currentContext: CGContext? {
		get {
			if #available(OSX 10.10, *) {
				return NSGraphicsContext.current?.cgContext
			}
			else if let contextPointer = NSGraphicsContext.current?.graphicsPort {
				return Unmanaged.fromOpaque(contextPointer).takeUnretainedValue()
			}
			return nil
		}
	}

	/*
	override open func draw(_ dirtyRect: NSRect) {
		let rect = visibleRect.insetBy(dx: 30.0, dy: 30.0)

		let backgroundColor = NSColor.red.withAlphaComponent(0.1)
		backgroundColor.set()
		NSBezierPath.fill(rect)
		super.draw(dirtyRect)
		
	}
	
	@MainActor func textView(
		_ textView: NSTextView,
		shouldChangeTypingAttributes oldTypingAttributes: [String : Any] = [:],
		toAttributes newTypingAttributes: [NSAttributedString.Key : Any] = [:]
	) -> [NSAttributedString.Key : Any] {
		//assignSyntaxColors(false, inside: textView.string[...])

		return 	[NSAttributedString.Key.backgroundColor: NSColor.yellow.withAlphaComponent(0.1)]

	}
	 
	 */
}

/// PsEditView extension for NSTextViewDelegate protocol
extension PsEditView: NSTextViewDelegate {
	// May be I missed something, but seams to be empty
}

/// PsEditView extension for SaveAsProtocol protocol
extension PsEditView: SaveAsProtocol {
	// already satisfied in implementation of SaveAsProtocol extension
}

