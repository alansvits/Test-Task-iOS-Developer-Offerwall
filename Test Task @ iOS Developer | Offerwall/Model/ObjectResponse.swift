//
//  ObjectResponse.swift
//  Test Task @ iOS Developer | Offerwall
//
//  Created by Stas Shetko on 2/01/20.
//  Copyright © 2020 Stas Shetko. All rights reserved.
//

import Foundation

struct ObjectResponse: Codable {
    
    var type: String
    var contents: String?
    var url: String?
    
}
