//
//  HelpWindow.swift
//  Postscript Playground
//
//  Created by LegoEsprit on 21.02.25.
//

import AppKit
import WebKit
import os.log

class HelpWindow: NSWindow, WKUIDelegate, WKNavigationDelegate {
    
    /// View for the html tzext
    @IBOutlet weak var webViewOutLet: WKWebView!
    
    
    /// Class function to generate the help window
    class func create() {
        let helpWindow = HelpWindow.loadFromNib()
        helpWindow?.title = String(localized: "Help")
        helpWindow?.makeKeyAndOrderFront(self)
    }
    
    /// Requests the html help pages from the bundle
    fileprivate func loadRequest() {
        var language = Locale.current.language.languageCode
        switch language {
        case "en":
            language = "Base"
        default:
            break
        }
        if let language = language
            , let url = Bundle.main.url(
                forResource:"Postscript PlaygroundHelp"
                , withExtension: "html"
                , subdirectory: "HelpFolder/\(language).lproj"
            ) {
            let request = URLRequest(url: url)
            webViewOutLet.loadFileURL(url, allowingReadAccessTo: url)
            webViewOutLet.load(request)
        }
    }
    
    
    /// load html help automatically when window opens
    override func awakeFromNib() {
        Logger.login("", className: className)
        loadRequest()
        Logger.logout("", className: className)
    }
    
    
    
}
