//
//  Item.swift
//  GoodsManageTool
//
//  Created by 汤寿麟 on 2026/6/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
