

//
//  AppDelegate.swift
//  idex01
//
//  Created by Albrecht Weber on 01.06.18.
//  Copyright © 2018 TestOrga. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    static let shared = AppDelegate()
    
    @IBOutlet weak var window: NSWindow!
    
    @IBOutlet weak var EtherAdressField: NSTextField!
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBAction func closeButton(_ sender: Any) {
        
        if !EtherAdressField.stringValue.isEmpty {
            if EtherAdressField.stringValue != UserDefaults.standard.string(forKey: "UserEtherAdress") {
               makeQuery()
            }
           
            let cleanedAdress = EtherAdressField.stringValue.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "")
            
            if cleanedAdress.count != 42 {
                
                returnNothing(frage: "Doesn't seem to be an ETH-Adress.", infotext: "Press ⌘A delete all and paste again.")
                return

            } else {
                
                UserDefaults.standard.set(cleanedAdress, forKey: "UserEtherAdress")
            }
            
           
        }
        window.close()
    }
    
    var windowController: NSWindowController?
    
    let formatter: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.numberStyle = .decimal
        _formatter.minimumFractionDigits = 2
        _formatter.maximumFractionDigits = 2
        _formatter.minimumIntegerDigits = 1
        _formatter.decimalSeparator = "."
        _formatter.secondaryGroupingSize = 3
        _formatter.groupingSeparator = ","
        //_formatter.generatesDecimalNumbers = false
        return _formatter
    }()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()
    

    let queue = DispatchQueue(label: "Timer", qos: .background, attributes: .concurrent)
    var timer: Timer? = Timer()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //UserDefaults.standard.set(0.0, forKey: "lastTradeTimeStamp")
    
        window.styleMask.remove(.resizable)
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = true

        // make title color
        window.titlebarAppearsTransparent = true
        window.titleVisibility = NSWindow.TitleVisibility.hidden
        window.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        
        // self.view.window?.backgroundColor = NSColor.red
        // self.view.window?.styleMask = NSFullSizeContentViewWindowMask
        //self.view.window?.styleMask = NSTexturedBackgroundWindowMask
        
        window.isMovableByWindowBackground = true
        
        statusItem.menu = menu
        
        // noch nicht socher
        //self.setTitleButton(false)
        
        makeQuery()
        
        queue.async { [unowned self] in
            if let _ = self.timer {
                self.timer?.invalidate()
                self.timer = nil
            }
            
            let currentRunLoop = RunLoop.current
            self.timer = Timer(timeInterval: 60, target: self, selector: #selector(AppDelegate.makeQuery), userInfo: nil, repeats: true)
            currentRunLoop.add(self.timer!, forMode: .commonModes)
            currentRunLoop.run()
        }
    }
    
    var averageChange = 0.0
    
    func setTitleButton(_ withFire: Bool) {
        
        if let button = self.statusItem.button {
            // button.image = NSImage(named: NSImage.Name(rawValue: "BitcoinSign_blue"))
            
            var fire: String {
                if withFire {
                    return "🚀 "
                }
                return ""
            }
            
            DispatchQueue.main.async {
                if self.averageChange.isNaN {
                    let str =  "Ø +0.0 %"
                    button.attributedTitle = NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)])
                    
                    
                } else if self.averageChange < 0.0 {
                    
                    let str2 =   "\(fire)Ø \(self.formatter.string(from: self.averageChange as NSNumber) ?? "") %"
                    button.attributedTitle = NSAttributedString(string: str2, attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1),  .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)])
                    
                } else {
                   
                    let str =  "\(fire)Ø +\(self.formatter.string(from: abs(self.averageChange) as NSNumber) ?? "") %"
                    button.attributedTitle = NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)])
                }
            }
        }
    }
    
    @objc func makeQuery()  {

        CMCQuery.shared.returnEthPrice() { ethPrice in
            
            EthplorerBalances.shared.getAddressBalances() { () in
                
                IdexQuery.shared.returnTicker() { () in
                    
                    IdexQuery.shared.returnCompleteBalances() { (allBalances) in
                        
                        IdexQuery.shared.returnLastTrade() { (lastTrade) in
                            
                            self.averageChange = Average.calc(array: allBalances)
                            
                            self.setTitleButton(lastTrade != nil)
                            
                            self.menu.removeAllItems()
                            
                            let sum =  self.formatter.string(from: (allBalances.reduce(0, {$0 + $1.value}) * ethPrice) as NSNumber) ?? ""
                            let topMenuItem = NSMenuItem()
                            
                            let topParagraph = NSMutableParagraphStyle()
                            topParagraph.tabStops = [
                                NSTextTab(textAlignment: .right, location: 220, options: [:]),
                            ]
                            
                            let str = "Total Balance\t$ \(sum)"
                            
                            let attributed = NSMutableAttributedString(
                                string: str,
                                attributes: [.paragraphStyle: topParagraph, .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)]
                            )
                            
                            topMenuItem.attributedTitle = attributed
                            topMenuItem.action = #selector(AppDelegate.totalBalance)
                            
                            self.menu.addItem(topMenuItem)
                            
                            // self.menu.addItem(NSMenuItem(title: "Preferences", action: #selector(AppDelegate.showMyCoins), keyEquivalent: ","))
                            self.menu.addItem(.separator())
                            
                            for item in allBalances.sorted(by: {$0.value > $1.value}) {
                                
                                let paragraph = NSMutableParagraphStyle()
                                paragraph.tabStops = [
                                    NSTextTab(textAlignment: .right, location: 120, options: [:]),
                                    NSTextTab(textAlignment: .right, location: 220, options: [:])
                                ]
                                
                                var str: String {
                                    
                                    if item.symbol == "ETH" {
                                        return "\(item.symbol)\t\t\((self.formatter.string(from: (item.value * ethPrice) as NSNumber)) ?? "")"
                                    }
                                    return "\(item.symbol)\t\((self.formatter.string(from: item.percentChange as NSNumber)) ?? "") %\t\((self.formatter.string(from: (item.value * ethPrice) as NSNumber)) ?? "")"
                                }
                                
                                let attributed = NSMutableAttributedString(
                                    string: str,
                                    attributes: [.paragraphStyle: paragraph, .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)]
                                )
                                
                                if item.percentChange < 0 {
                                    attributed.setColorForText("\((self.formatter.string(from: item.percentChange as NSNumber)) ?? "") %", with: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))
                                } else {
                                    attributed.setColorForText("\((self.formatter.string(from: item.percentChange as NSNumber)) ?? "") %", with: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
                                }
                                
                                if item.symbol == lastTrade?.symbol {
                                    
                                    attributed.setBackGroundColorForText(item.symbol, with: #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1))
                                }
                                
                                let menuItem = NSMenuItem()
                                menuItem.attributedTitle = attributed
                                menuItem.action = #selector(AppDelegate.showMyCoins)
                                menuItem.keyEquivalent = ""
                                
                                self.menu.addItem(menuItem)
                                
                                //  self.menu.addItem(NSMenuItem(title: "\(item.symbol)  \(item.value * 580)", action: #selector(AppDelegate.showMyCoins), keyEquivalent: ""))
                                
                            }
                            
                            self.menu.addItem(.separator())
                            
                            let preferenceAttributed = NSMutableAttributedString(
                                string: "Preferences",
                                attributes: [.paragraphStyle: topParagraph, .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)]
                            )
                            
                            let preferencesItem = NSMenuItem()
                            preferencesItem.attributedTitle = preferenceAttributed
                            preferencesItem.action = #selector(AppDelegate.showPreferences)
                            preferencesItem.keyEquivalent = ","
                            
                            self.menu.addItem(preferencesItem)
                            
                            ///////
                            
                            let quitAttributed = NSMutableAttributedString(
                                string: "Quit",
                                attributes: [.paragraphStyle: topParagraph, .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)]
                            )
                            
                            let quitItem = NSMenuItem()
                            quitItem.attributedTitle = quitAttributed
                            quitItem.action = #selector(AppDelegate.shutDown)
                            quitItem.keyEquivalent = "q"
                            
                            self.menu.addItem(quitItem)
                            
                           // self.menu.addItem(NSMenuItem(title: "Donate", action: #selector(AppDelegate.showMyCoins), keyEquivalent: ""))
                            //self.menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.shutDown), keyEquivalent: "q"))
                            
                        }    
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func showPreferences(sender: NSMenuItem) {
        self.tabView.selectTabViewItem(at: 0)
        NSApp.activate(ignoringOtherApps: true)
        self.openMyWindow()
    }
    
    @objc func totalBalance(sender: NSMenuItem) {
        if let url = URL(string: "https://idex.market/balances") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func showMyCoins(sender: NSMenuItem) {
        
        setTitleButton(false)
        IdexQuery.shared.isNewTrade = false
        
        if let url = URL(string: "https://idex.market/eth/\(sender.title.split(separator: "\t")[0].lowercased())") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func shutDown(sender: NSMenuItem) {
        
        NSApp.terminate(self)
    }
    
    func openMyWindow() {
        
        if UserDefaults.standard.string(forKey: "UserEtherAdress") != nil {
            EtherAdressField.stringValue = UserDefaults.standard.string(forKey: "UserEtherAdress")!
        }

        window.makeKeyAndOrderFront(nil)
    }
    
    func returnNothing(frage: String, infotext: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = frage
            alert.informativeText = infotext
            alert.alertStyle = NSAlert.Style.informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
    }
}

extension NSMutableAttributedString{
    func setColorForText(_ textToFind: String?, with color: NSColor) {
        let range: NSRange?
        if let text = textToFind{
            range = self.mutableString.range(of: text, options: .caseInsensitive)
        }else{
            range = NSMakeRange(0, self.length)
        }
        if range!.location != NSNotFound {
            addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: range!)
        }
    }
    
    func setBackGroundColorForText(_ textToFind: String?, with color: NSColor) {
        let range: NSRange?
        if let text = textToFind{
            range = self.mutableString.range(of: text, options: .caseInsensitive)
        }else{
            range = NSMakeRange(0, self.length)
        }
        if range!.location != NSNotFound {
            addAttribute(NSAttributedStringKey.backgroundColor, value: color, range: range!)
        }
    }
}


