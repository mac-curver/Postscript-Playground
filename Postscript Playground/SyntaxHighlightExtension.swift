//
//  SyntaxHighlighter.swift
//  SimplePsViewer
//
//  Created by LegoEsprit on 18.04.23.
//

import os.log
import Cocoa
import RegexBuilder



//protocol SyntaxHighLighter<NSTextView> {
//
//    func syntaxColors() -> [NSColor: Regex<Substring>]
//    func assignSyntaxColors()
//}

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
                    return ""
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

    
    static var defaultColors = [NSColor.black
                                , NSColor.blue                                  ///< some colors for the syntax highlighting
                                , NSColor.magenta
                                , NSColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
                                , NSColor.red
                                , NSColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0)
                                , NSColor.brown
                               ]
    
    static var colors = defaultColors
    static var undoColors = defaultColors

    
    
    static func storeUndoColors() {
        undoColors = colors
    }
    
    static func retrieveUndoColors() {
        colors = undoColors
        
        let userdefault = UserDefaults.standard
        let colorTransFormer = ColorValueTransformer()
        
        for var color in SyntaxColors.ColorSpaces.allCases {
            color.color = color.defaultColor
            userdefault.set(colorTransFormer.reverseTransformedValue(color.color), forKey: color.string)
        }
    }


    
    static func resetAllColors() {
        let userdefault = UserDefaults.standard
        let colorTransFormer = ColorValueTransformer()
        for var color in SyntaxColors.ColorSpaces.allCases {
            color.color = color.defaultColor
            userdefault.set(colorTransFormer.reverseTransformedValue(color.color), forKey: color.string)
        }
    }
    
    fileprivate static func getSetBoundColor(default defaultColor: NSColor, forKey colorKey: String) -> NSColor{
        let userdefault = UserDefaults.standard
        let colorTransFormer = ColorValueTransformer()

        if let encodedColor = userdefault.object(forKey: colorKey) as? Data {
            return colorTransFormer.transformedValue(encodedColor) as! NSColor
        }
        else {
            userdefault.set(colorTransFormer.reverseTransformedValue(defaultColor), forKey: colorKey)
            return defaultColor
        }
    }
    
    
    /// Called like a static initializer to set-up all colors from the preferences
    static func initializeColors() {
        for var color in SyntaxColors.ColorSpaces.allCases {
            color.color = getSetBoundColor(default: color.defaultColor, forKey: color.string)
        }
    }
    

}


/// Extension to add simple syntax color
extension NSTextView {
    
    
    /// Called when starting the app to initialize the colors
    func initializeSyntaxColors() {
        SyntaxColors.initializeColors()
    }
    
    /// Set the colors to the factory default values
    func resetAllColors() {
        SyntaxColors.resetAllColors()
    }
    

    /// syntaxColors builds and returns an attributes directory
    /// - Returns: A dictionary containing colors and regular expressions
    ///
    /// Simple and effective but not efficient syntax highligthing. Not all
    /// ps reservered words are covered.
    fileprivate func syntaxColors() -> [SyntaxColors.ColorSpaces: Regex<Substring>] {
        SyntaxColors.initializeColors()
        
        
        return [
            SyntaxColors.ColorSpaces.GraphicsColor: Regex {
                Anchor.wordBoundary
                ChoiceOf {
                    "get"
                    "moveto"; "lineto"; "rmoveto"; "rlineto"
                    "newpath"; "closepath"; "stroke"
                    "show"; "showpage"
                    "gsave"; "grestore"
                    "scale"; "translate"; "rotate"
                    "setlinewidth"
                    "push"; "pop"; "dup"; "exch"; "copy"; "index"; "roll";
                    "clear"; "mark"; "cleartomark"; "counttomark"
                    "findfont"; "scalefont"; "setfont"; "charpath"
                    "selectfont"; "stringwidth"
                    "setgray"
                    "fill"
                    "setrgbcolor"
                    "length"
                    "putinterval"
                    "bind"
                    "cvs"; "cvi"; "cvn"
                }
                Anchor.wordBoundary
            }
            , SyntaxColors.ColorSpaces.MathColor: Regex {
                Anchor.wordBoundary
                ChoiceOf {
                    "add"; "div"; "idiv"; "mod"; "mul"; "sub"; "abs"; "neg"
                    "ceiling"; "floor"; "round"; "truncate"
                    "sqrt"; "atan"; "cos"; "sinus"; "exp"; "ln"
                    "rand"; "srand"; "rrand"
                }
                Anchor.wordBoundary
            }
            
            
            , SyntaxColors.ColorSpaces.FlowControlColor: Regex {
                Anchor.wordBoundary
                ChoiceOf {
                    "exec"
                    "if"; "ifelse"; "for"; "forall"; "repeat"; "loop"; "exit"
                    "start"; "stop"; "stopped"; "countexecstack"; "execstack"
                    "quit"
                }
                Anchor.wordBoundary
            }
            
            , SyntaxColors.ColorSpaces.NumbersColor: Regex {
                Anchor.wordBoundary
                ChoiceOf {
                    Regex {
                        Optionally("-")
                        ZeroOrMore(.digit)
                        "."
                        OneOrMore(.digit)
                    }
                    Regex {
                        Optionally("-")
                        OneOrMore(.digit)
                    }
                    "true"
                    "false"
                }
                Anchor.wordBoundary
            }
            
            , SyntaxColors.ColorSpaces.DefineColor: Regex {
                //Anchor.wordBoundary
                ChoiceOf {
                    Regex {
                        "/"
                        OneOrMore(
                            ChoiceOf {
                                .word
                                "-"
                            }
                        )
                    }
                    "def"
                }
                //Anchor.wordBoundary
            }

            
            , SyntaxColors.ColorSpaces.CommentColor: Regex {
                "%"
                ZeroOrMore {
                    /./
                }
            }
        ]
    
    }
    
    /// assignSyntaxColors takes the syntax directory and assigns it to
    /// textStorage
    ///
    /// Simple and effective but not efficient syntax highligthing. Therefore limited to 10000 chars!
    func assignSyntaxColors() {
        if string.count < 10000 {
            textStorage?.attributeRuns = []
            
            let dictionary = syntaxColors()
            //for color in dictionary.keys {                                    /// Use sorted order instead ?!
            for colorSpace in [
                SyntaxColors.ColorSpaces.GraphicsColor
                , SyntaxColors.ColorSpaces.MathColor
                , SyntaxColors.ColorSpaces.FlowControlColor
                , SyntaxColors.ColorSpaces.NumbersColor
                , SyntaxColors.ColorSpaces.DefineColor
                , SyntaxColors.ColorSpaces.CommentColor
            ] {
                let color = colorSpace.color
                if let regex: Regex = dictionary[colorSpace] {
                    for wordRange in string.ranges(of: regex) {
                        textStorage?.removeAttribute(
                            NSAttributedString.Key.foregroundColor
                            , range: NSRange(wordRange, in: string))
                        textStorage?.addAttributes(
                            [NSAttributedString.Key.foregroundColor: color]
                            , range: NSRange(wordRange, in: string)
                        )
                    }
                }
                
            }
            setNeedsDisplay(visibleRect)
        }
    }
    
    
}
