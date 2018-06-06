//
//  IdexTicker.swift
//  idex01
//
//  Created by Albrecht Weber on 01.06.18.
//  Copyright © 2018 TestOrga. All rights reserved.
//

import Foundation
import Alamofire

class IdexQuery {
    
    static let shared = IdexQuery()
    
    struct Balances {
        let symbol: String
        let value: Double
        let percentChange: Double
    }
    struct Tickers {
        let symbol: String
        let last: Double
        let percentChange: Double
    }
    
    var allPrices = [Tickers]()
    var allBalances = [Balances]()

    var isNewTrade = false
    
   
    
    func returnCompleteBalances(completionHandler: @escaping ([Balances]) -> ()) {
        guard UserDefaults.standard.string(forKey: "UserEtherAdress") != nil && UserDefaults.standard.string(forKey: "UserEtherAdress") != "" else {
            completionHandler([Balances]())
            return
        }
        var balancesFromEthplorer = EthplorerBalances.shared.balancesFromEthplorer
        
        
        let parameters = ["address": UserDefaults.standard.string(forKey: "UserEtherAdress") ?? ""] as [String : Any]
        
        Alamofire.request("https://api.idex.market/returnCompleteBalances", parameters: parameters).responseJSON { responseData in
            
            switch responseData.result {
            case .success:
                
                if((responseData.result.value) != nil) {
                    
                    guard let dict = responseData.result.value as? NSDictionary else { print("kein dictionary");  return }
                    
                    self.allBalances.removeAll()
                    
                    for (key, value) in dict {
                        
                        if let coin = value as? NSDictionary {
                          
                            let available = Double((coin["available"] as? String) ?? "") ?? 0.0
                            let onOrders = Double((coin["onOrders"] as? String) ?? "") ?? 0.0

                            let rightCoinFromPrices = self.allPrices.first(where: {$0.symbol == (key as? String) ?? ""})
                            
                            let ethplorerBalance = balancesFromEthplorer.first(where: {$0.symbol == (key as? String) ?? "" })
                            

                            
                            
                            if (key as? String) ?? "" == "ETH" {
                                let result = Balances(symbol: (key as? String) ?? "", value: (available + onOrders + (ethplorerBalance?.balance ?? 0.0)), percentChange:  0.0)
                                self.allBalances.append(result)
                                
                                
                            } else {
                                let result = Balances(symbol: (key as? String) ?? "", value: (rightCoinFromPrices?.last ?? 0.0) * (available + onOrders + (ethplorerBalance?.balance ?? 0.0)), percentChange: (rightCoinFromPrices?.percentChange) ?? 0.0)
                                self.allBalances.append(result)
                            }
                            
                            let index = balancesFromEthplorer.index(where: {$0.symbol == (key as? String) ?? "" })
                            if index != nil {
                                balancesFromEthplorer.remove(at: index!)
                            }
                            
                           
                           
                        }
                    }
                    
                    for balance in balancesFromEthplorer {
                        if balance.symbol == "ETH" {
                            let result = Balances(symbol: balance.symbol, value: balance.balance, percentChange:  0.0)
                            self.allBalances.append(result)
                            
                            
                        } else {
                            let rightCoinFromPrices = self.allPrices.first(where: {$0.symbol == balance.symbol})
                            
                            let result = Balances(symbol: balance.symbol, value: balance.balance * (rightCoinFromPrices?.last ?? 0.0), percentChange:  (rightCoinFromPrices?.percentChange ?? 0.0))
                            self.allBalances.append(result)
                        }
                    }
                }
               // print(self.allBalances)
                completionHandler(self.allBalances)

            case .failure:
                print("error in returnCompleteBalances")
                return
            }
        }
        
        for coin in balancesFromEthplorer {
            if self.allBalances.first(where: {$0.symbol == coin.symbol}) == nil {
                let price = self.allPrices.first(where: {$0.symbol == coin.symbol})
                self.allBalances.append(Balances(symbol: coin.symbol, value: (coin.balance * (price?.last ?? 0.0)), percentChange: (price?.percentChange ?? 0.0)))
            }
        }
        
    }
    
    
    func returnTicker(completionHandler: @escaping () -> ()) {
    
        guard UserDefaults.standard.string(forKey: "UserEtherAdress") != nil && UserDefaults.standard.string(forKey: "UserEtherAdress") != "" else {
            completionHandler()
            return
        }
        Alamofire.request("https://api.idex.market/returnTicker").responseJSON { responseData in
            
            switch responseData.result {
            case .success:
                
                if((responseData.result.value) != nil) {
                    
                    guard let dict = responseData.result.value as? NSDictionary else { print("kein dictionary");  return }
                    
                    self.allPrices.removeAll()
                    
                    for (key, value) in dict {
                        
                        if let coin = value as? NSDictionary {
                            
                            let symbol = ((key as? String) ?? "").substring(from: (((key as? String) ?? "").range(of: "_")?.upperBound)!)
                            let last = Double((coin["last"] as? String) ?? "") ?? 0.0
                            let percentChange = Double((coin["percentChange"] as? String) ?? "") ?? 0.0
                            
                            let result = Tickers(symbol: symbol, last: last, percentChange: percentChange)
                            self.allPrices.append(result)
                        }
                    }
                }
                
                completionHandler()

            case .failure:
                print("error in returnTicker")
                return
            }
        }
    }
    
    
    
    struct Trade {
        let symbol: String
        let timeStamp: Double
        let amount: Double
        let type: String
    }
    
    var allTrades = [Trade]()
    
    
    func returnLastTrade(completionHandler: @escaping (Trade?) -> ()) {
        guard UserDefaults.standard.string(forKey: "UserEtherAdress") != nil && UserDefaults.standard.string(forKey: "UserEtherAdress") != "" else {
            completionHandler(nil)
            return
        }
        let startTime = Int(Date().timeIntervalSince1970 - 86400)

        
        let parameters = ["address": UserDefaults.standard.string(forKey: "UserEtherAdress") ?? "", "start": "\(startTime)"] as [String : Any]
        
        Alamofire.request("https://api.idex.market/returnTradeHistory", parameters: parameters).responseJSON { responseData in
            
            switch responseData.result {
            case .success:
                
                if((responseData.result.value) != nil) {
                    
                    guard let dict = responseData.result.value as? NSDictionary else { print("kein dictionary");  return }
                    
                    
                    self.allTrades.removeAll()
                    
                    for (key, value) in dict {
                        if let values = value as? NSArray {
                            for innerdict in values {
                                if let finaldict = innerdict as? NSDictionary {
                                    
                                    let symbol = ((key as? String) ?? "").substring(from: (((key as? String) ?? "").range(of: "_")?.upperBound)!)
                                    let timestamp = (finaldict["timestamp"] as? Double) ?? 0.0
                                    let amount = Double((finaldict["amount"] as? String) ?? "") ?? 0.0
                                    let type = (finaldict["type"] as? String) ?? ""

                                    let result = Trade(symbol: symbol, timeStamp: timestamp, amount: amount, type: type)
                                    
                                    self.allTrades.append(result)
                                }
                            }
                        }
                    }
                    
                    let sortedTrades = self.allTrades.sorted(by: {$0.timeStamp > $1.timeStamp})
                    
                   
                    if UserDefaults.standard.double(forKey: "lastTradeTimeStamp") == 0.0 || UserDefaults.standard.double(forKey: "lastTradeTimeStamp") != sortedTrades.first?.timeStamp || self.isNewTrade {
                       
                        UserDefaults.standard.set(sortedTrades.first?.timeStamp, forKey: "lastTradeTimeStamp")
                        completionHandler(sortedTrades.first)
                        
                        self.isNewTrade = true
                        
                        return
                    } else {
                        
                        completionHandler(nil)
                        return
                    }
                    
                   
              
                    
                }
                
            case .failure:
                print("error in returnCompleteBalances")
                return
            }
        }
    }
    
    
    
    
    
    
    
    
    
    

}





