//
//  Average.swift
//  idex01
//
//  Created by Albrecht Weber on 03.06.18.
//  Copyright © 2018 TestOrga. All rights reserved.
//

import Foundation



struct Average {
    
    static func calc(array: [IdexQuery.Balances]) -> Double  {
        
        var sum = 0.0
        
        for item in array {
            sum += item.value * (1 + (item.percentChange / 100 ))
        }
        
        let factor = sum / (array.reduce(0, {$0 + $1.value}))
        
        let percent = -( 1 - factor) * 100
                
        return percent
        
        
    }
    
    
    
    
    
    
    
    
}
