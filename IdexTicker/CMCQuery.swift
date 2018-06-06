//
//  IdexTicker.swift
//  idex01
//
//  Created by Albrecht Weber on 01.06.18.
//  Copyright © 2018 TestOrga. All rights reserved.
//

import Foundation
import Alamofire

class CMCQuery {
    
    static let shared = CMCQuery()
    
   
    
    
    func returnEthPrice(completionHandler: @escaping (Double) -> ()) {
        
        guard UserDefaults.standard.string(forKey: "UserEtherAdress") != nil && UserDefaults.standard.string(forKey: "UserEtherAdress") != "" else {
            completionHandler(0.0)
            return
        }
        
        Alamofire.request("https://api.coinmarketcap.com/v2/ticker/1027/").responseJSON { responseData in
            
            switch responseData.result {
            case .success:
               // print(responseData.result.value)
                
                if((responseData.result.value) != nil) {
                    
                    guard let dict = responseData.result.value as? NSDictionary else { print("kein dictionary");  return }
                    
                    if let data = dict["data"] as? NSDictionary {
                        if let quotes = data["quotes"] as? NSDictionary {
                            if let USD = quotes["USD"] as? NSDictionary {
                                let ethPrice = (USD["price"] as? Double ?? 0.0)
                                completionHandler(ethPrice)
                                return
                                
                            }
                            
                        }

                    }
                    
                    
                }

                completionHandler(0.0)
                
            case .failure:
                print("error in returnCompleteBalances")
                return
            }
        }
    }
    

    
}





