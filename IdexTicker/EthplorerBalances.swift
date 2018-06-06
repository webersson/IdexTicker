//
//  EthplorerBalances.swift
//  idex01
//
//  Created by Albrecht Weber on 03.06.18.
//  Copyright © 2018 TestOrga. All rights reserved.
//

import Foundation
import Alamofire

class EthplorerBalances {
    
    static let shared = EthplorerBalances()
    
    struct balancesContainer {
        let symbol: String
        let balance: Double
    }
    
    var balancesFromEthplorer = [balancesContainer]()
    
    func getAddressBalances(completion: @escaping () -> Void)  {
        
        guard UserDefaults.standard.string(forKey: "UserEtherAdress") != nil && UserDefaults.standard.string(forKey: "UserEtherAdress") != "" else {
            completion()
            return
        }
        balancesFromEthplorer.removeAll()

        
        Alamofire.request("https://api.ethplorer.io/getAddressInfo/\(UserDefaults.standard.string(forKey: "UserEtherAdress") ?? "")?apiKey=freekey&limit=5000").responseJSON { (responseData) -> Void in
            
            guard let orderDicts = responseData.result.value as? NSDictionary  else {completion(); return }
            
 
            
            let eth = orderDicts["ETH"] as? NSDictionary
            
            let amount = (eth?["balance"] as? Double) ?? 0.0
            if  amount > 0.0 {
                
                self.balancesFromEthplorer.append(balancesContainer(symbol: "ETH", balance: amount))
            }
            
            guard let tokens = orderDicts["tokens"] as? NSArray else {completion(); return}
            
            for token in tokens {
                
                if let dict = token as? NSDictionary {
                    
                    let balance = ((dict["balance"] as? Double) ?? 0.0) / 1000000000000000000.0 // decimals
                    
                    if let tokenInfo = dict["tokenInfo"] as? NSDictionary {
                        _ = (tokenInfo["address"] as? String) ?? ""
                        _  = (tokenInfo["decimals"] as? Int)
                        let symbol = (tokenInfo["symbol"] as? String) ?? ""
                        
                        self.balancesFromEthplorer.append(balancesContainer(symbol: symbol, balance: balance))

                        
                        
                    }
                }
            }
            
            completion()
            return
            
        }  
    }
}
