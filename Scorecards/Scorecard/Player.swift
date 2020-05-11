//
//  Player.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/18/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation

class Player: Codable {
    
    var ID: Int
    var Name: String
    
    //MARK: Initialization
    init(ID: Int, Name: String) {
        // Initialize stored properties.
        self.ID = ID
        self.Name = Name
    }
    
}
