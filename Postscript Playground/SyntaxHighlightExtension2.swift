//
//  SyntaxHighlightExtension2.swift
//  Postscript Playground
//
//  Created by LegoEsprit on 17.12.23.
//

import os.log
import Cocoa
import RegexBuilder


/// SyntaxColors delivers all colors available for syntax coloring
class SyntaxColors {
	
	/// Colorspaces returns the name, the color or the default color
	enum ColorSpaces: Int, CaseIterable {
		case UnassignedColor = 0
		case GraphicsColor = 1
		case MathColor = 2
		case DefineColor = 3
		case FlowControlColor = 4
		case NumbersColor = 5
		case CommentColor = 6
		
		var string: String {
			get {
				switch self {
				case .GraphicsColor:
					return "GraphicsColor"
				case .MathColor:
					return "MathColor"
				case .DefineColor:
					return "DefineColor"
				case .FlowControlColor:
					return "FlowControlColor"
				case .NumbersColor:
					return "NumbersColor"
				case .CommentColor:
					return "CommentColor"
				default:
					return "UnassignedColor"
				}
			}
		}
				
		var color: NSColor {
			get {
				return SyntaxColors.colors[self.rawValue]
			}
			set(color) {
				SyntaxColors.colors[self.rawValue] = color
			}
		}
		
		var defaultColor: NSColor {
			get {
				return defaultColors[self.rawValue]
			}
		}
		
	}

	
	/// Array with the factory default colors. Used when the app is started for the very first time.
	static var defaultColors = [NSColor.black
								, NSColor.blue                                  ///< some colors for the syntax highlighting
								, NSColor.magenta
								, NSColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
								, NSColor.red
								, NSColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0)
								, NSColor.brown
							   ]
	
	/// colors array  initiated with default colors
	static var colors = defaultColors
	/// undoColors array  initiated with default colors
	static var undoColors = defaultColors
	
	
	
	/// Reads the colors from the preferences and assigns them to colors and undoColors.
	static func storeUndoColors() {
		let userdefault = UserDefaults.standard
		for var color in SyntaxColors.ColorSpaces.allCases {
			color.color = userdefault.color(forKey: color.string)
		}

		undoColors = colors
	}
	
	/// Cancels any changes and sets the actual colors to the undoColors.
	static func retrieveUndoColors() {
		colors = undoColors
		
		let userdefault = UserDefaults.standard
		for color in SyntaxColors.ColorSpaces.allCases {
			userdefault.set(color: color.color, forKey: color.string)
		}

	}
	
	/// Resets all colors to the factory default - including the colors in the preferences.
	static func resetAllColors() {
		colors = defaultColors

		let userdefault = UserDefaults.standard
		for color in SyntaxColors.ColorSpaces.allCases {
			userdefault.set(color: color.defaultColor, forKey: color.string)
		}
	}
	
	
	init() {
	}
}

/// Swift Regex to obtain any valid .ps number including numbers using a different base.
fileprivate let numerical = Regex {
	ChoiceOf {
		
		Regex {
			Optionally {
				One(.anyOf("+-"))
			}
			OneOrMore(.digit)
			Optionally {
				Regex {
					"."
					OneOrMore(.digit)
				}
			}
			Optionally {
				Regex {
					"E"
					Optionally {
						One(.anyOf("+-"))
					}
					OneOrMore(.digit)
				}
			}
		}
		
		Regex {
			OneOrMore(.digit)
			"#"
			OneOrMore {
				CharacterClass(
					("0"..."9"),
					("a"..."z")
				)
			}
		}
		"true"
		"false"

	}
}.ignoresCase()



/// Regular expression finding strings starting with slash
fileprivate let definesRegEx = Regex {
	/^/
	ZeroOrMore(.reluctant) {
		.whitespace
	}
	Capture {
		"/"
		OneOrMore(.whitespace.inverted)
	}
}

/// Extension to Collection class avoiding endIndex less than startIndex error
extension Collection where Indices.Iterator.Element == Index {
	
	/// Avoids Swift index complains
	/// - Parameters:
	///   - save index:  Index of the collection
	/// - Returns: Valid element or nil if index was invalid
	/// ```
	/// Should be called like: myString[safe: myString.index] for example
	/// ```
	public subscript(safe index: Index) -> Iterator.Element? {
		return (startIndex <= index && index < endIndex) ? self[index] : nil
	}
	
}

/// Extension to add simple syntax color
extension NSTextView {
	
	/// Dictionary from symbols and syntax/color
	static let syntaxDictionary = syntaxColors()
	
	/*
	 // Not required anymore
	/// Returns visible string portion as Substring
	var visibleSubString: Substring {
		//return profile.measure(profile.className(of: self), {
		return profile.measure(className: className, {
			let margin = 0.0
			let origin = visibleRect.origin.y
			let height = visibleRect.height
			
			let startPoint = CGPoint(x: 0.0, y: origin + margin)
			let endPoint = CGPoint(x: 0.0, y: origin + height - margin)
			let startCharacter = characterIndexForInsertion (at: startPoint)
			let endCharacter = characterIndexForInsertion (at: endPoint)

			let start = string.index(string.startIndex, offsetBy: startCharacter)
			let end = string.index(start
								   , offsetBy: endCharacter
								   , limitedBy: string.endIndex
					   ) ?? string.endIndex
			return string[start..<end]
		})!
	}
	
	/// Returns visible range as Range<String.Index>
	var visibleRange: Range<String.Index> {
		return profile.measure(className: className, {
			let margin = 0.0
			let origin = visibleRect.origin.y
			let height = visibleRect.height
			
			let startPoint = CGPoint(x: 0.0, y: origin + margin)
			let endPoint = CGPoint(x: 0.0, y: origin + height - margin)
			let startCharacter = characterIndexForInsertion (at: startPoint)
			let endCharacter = characterIndexForInsertion (at: endPoint)
			let nsRange = NSMakeRange(startCharacter, max(0, endCharacter-startCharacter))
			return Range(nsRange, in: string) ?? string.startIndex..<string.startIndex
		})!
	}
	 */

	

	/// syntaxColors builds and returns an attributes directory.
	/// - Returns: A dictionary containing ps symbols and their corresponding syntax color
	///
	fileprivate static func syntaxColors() -> [String: SyntaxColors.ColorSpaces] {
		
		let graphicsCommands = [
					"get"
					, "moveto", "lineto", "rmoveto", "rlineto"
					, "newpath", "closepath", "stroke"
					, "show", "showpage"
					, "gsave", "grestore"
					, "scale", "translate", "rotate"
					, "setlinewidth"
					, "push", "pop", "dup", "exch", "copy", "index", "roll"
					, "clear", "mark", "cleartomark", "counttomark"
					, "findfont", "scalefont", "setfont", "charpath"
					, "selectfont", "stringwidth"
					, "setgray"
					, "fill"
					, "setrgbcolor"
					, "length"
					, "putinterval"
					, "bind"
					, "cvs", "cvi", "cvn"
				]
		let mathCommands = [
					"add", "div", "idiv", "mod", "mul", "sub", "abs", "neg"
					, "ceiling", "floor", "round", "truncate"
					, "sqrt", "atan", "cos", "sinus", "exp", "ln"
					, "rand", "srand", "rrand"
				]
		let flowCommands = [
					"exec"
					, "if", "ifelse", "for", "forall", "repeat", "loop", "exit"
					, "start", "stop", "stopped", "countexecstack", "execstack"
					, "quit"
		]
		let defineCommands = [
					"def"
		]
		
		var syntaxDictionary:[String: SyntaxColors.ColorSpaces] = [:]
		for commands in graphicsCommands {
			syntaxDictionary[commands] = .GraphicsColor
		}
		for commands in mathCommands {
			syntaxDictionary[commands] = .MathColor
		}
		for commands in flowCommands {
			syntaxDictionary[commands] = .FlowControlColor
		}
		for commands in defineCommands {
			syntaxDictionary[commands] = .DefineColor
		}

		return syntaxDictionary
			
	}
	
	
	
	/// Adds foreground color attribute for numbers and symbols in the syntaxDictionary.
	/// - Parameters:
	///   - subString: The symbol to be analysed for the syntax as Substring
	///   - shiftedRange: The range of the expression inside the complete textView.string
	fileprivate func colorize(_ subString: Substring
							  , nsRange shiftedRange: NSRange
	) {
		if nil != (try? numerical.wholeMatch(in: subString)) {
			self.textStorage?.addAttribute(
				.foregroundColor
				, value: SyntaxColors.ColorSpaces.NumbersColor.color
				, range: shiftedRange
			)
		}
		else if let color = NSTextView.syntaxDictionary[String(subString)] {
			self.textStorage?.addAttribute(
				.foregroundColor
				, value: color.color
				, range: shiftedRange
			)
		}
	}
	
	/// Uses Regex matches to analyse the symbols inside a single line
	/// - Parameters:
	///   - line: The complete line without the comments
	///   - distance: Distance from the start of the string as NSRange distance
	///   ```
	///   This is nearly as fast implementation 250kB -> 0.40s
	///   ```
	func syntaxColorLineByRegex(line: Substring, distance: Int) {
		let regEx = Regex {
			Capture {
				OneOrMore(.whitespace.inverted)
			}
			ZeroOrMore(.whitespace)
		}
		let subStrings = line.matches(of: regEx)
		for match in subStrings {
			let subRange = match.range
			let subString = match.output.1
			var shiftedRange = NSRange(subRange, in: line)
			shiftedRange.location += distance
			
			colorize(subString, nsRange: shiftedRange)
		}
	}

	/// Uses NSRegularExpression to analyse the symbols inside a single line
	/// - Parameters:
	///   - line: The complete line with comments
	///   - distance: Distance from the start of the string as NSRange distance
	///   ```
	///   This is the slowest implementation 250kB -> 0.60s
	///   ```
	func syntaxColorLineByNSRegularExpression(line: String
											  , nsRange: NSRange
											  , distance: Int
	) {
		let regEx = try? NSRegularExpression(pattern: "(?:(\\S+)\\W*)")
		regEx?.enumerateMatches(in: line
								, options: .withoutAnchoringBounds
								, range: nsRange
		) {
			match, matchingFlags, bool in
			
			var shiftedRange = match!.range(at:1)
			if let range = Range(shiftedRange, in: line) {
				let subString = line[range]
				shiftedRange.location += distance
				colorize(subString, nsRange: shiftedRange)
			}
		}
	}
	
	/// Uses String.components to analyse the symbols inside a single line
	/// - Parameters:
	///   - line: The complete line without the comments
	///   - distance: Distance from the start of the string as NSRange distance
	///   ```
	///   This is the fastest implementation 250kB -> 0.35s
	///   ```
	func syntaxColorLineByComponents(line: Substring, distance: Int) {
		let delimiters = CharacterSet(charactersIn: " ()\t\r\n")
		
		var position = line.startIndex
		let _ = line.components(separatedBy: delimiters).compactMap {
			subString in
			if let subRange = line.range(
				of: subString
				, range: position..<line.endIndex
			) {
				position = subRange.upperBound
				var shiftedRange = NSRange(subRange, in: line)
				shiftedRange.location += distance
				colorize(subString[subString.startIndex...]
						 , nsRange: shiftedRange
				)
			}
			
		}
	}

	
	/// Removes foreground color attribute from the given line
	/// - Parameter nsRange: Range of characters given as NSRange
	func removeAttributesInLine(_ nsRange: NSRange) {
		self.textStorage?.removeAttribute(.foregroundColor, range: nsRange)
	}
	
	/// Method to be called for a single line
	/// - Parameters:
	///   - lineString: Complete line as String?
	///   - nsStartDistance: Distance to 1st letter as NSRange distance
	///   - syntax: Syntax method to be applied as Int (from SyntaxSegemented control)
	/// ```
	/// Splits the line into comment and non comment part. The comment part
	/// will be colored correctly. Checks if a define statement starts the
	/// line by identifying text starting with "/".
	/// ```
	func assignSyntaxColorToLine(_ lineString: String?
								 , nsStartDistance: Int
	) {
		if let line = lineString {
						
			let startCommentIndex = line.firstIndex(of: "%") ?? line.endIndex
			let commentRange = startCommentIndex..<line.endIndex
			let nonCommentRange = line.startIndex..<startCommentIndex
			
			var nsShiftedCommentRange = NSRange(commentRange, in: self.string)
			nsShiftedCommentRange.location += nsStartDistance
			
			self.textStorage?.addAttribute(
				.foregroundColor
				, value: SyntaxColors.ColorSpaces.CommentColor.color
				, range: nsShiftedCommentRange
			)
			
			let nonCommentLine = line[nonCommentRange]

			if let match = (try? definesRegEx.firstMatch(in: nonCommentLine)) {
				var nsRange = NSRange(match.range, in: nonCommentLine)
				nsRange.location += nsStartDistance
				
				self.textStorage?.addAttribute(
					.foregroundColor
					, value: SyntaxColors.ColorSpaces.DefineColor.color
					, range: nsRange
				)
			}
			/*
			self.syntaxColorLineByRegex(
				line: nonCommentLine
				, distance: nsStartDistance
			)
			
			self.syntaxColorLineByNSRegularExpression(
				line: line
				, nsRange: NSRange(nonCommentRange, in: line)
				, distance: nsStartDistance
			)
			*/
			self.syntaxColorLineByComponents(
				line: nonCommentLine
				, distance: nsStartDistance
			)

			
		}
	}
	
	/// assignSyntaxColors takes the syntax directory and assigns it to
	/// textStorage
	///
	/// Simple and effective but not efficient syntax highligthing.
	/// - Parameter syntax: Syntax method to be applied (see SyntaxSegementedControl)
	func assignSyntaxColors() {
		Logger.login("", className: className)

		profile.measure(className: className, {
		
			/// Enumerate the text line by line!
			string.enumerateSubstrings(in: string.startIndex...
									   , options: .byLines
			) {
				lineString, lineRange, _, _  in
				
				let nsLineRange = NSRange(lineRange, in: self.string)
				
				self.assignSyntaxColorToLine(
					lineString
					, nsStartDistance: nsLineRange.location
				)
			}

			setNeedsDisplay(visibleRect)
		})!
		Logger.logout("", className: className)

	}
	

}

