//
//  Score.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/18/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation

class Score: Codable {
    
    var PlayerID: Int
    var Score: Int
    
    //MARK: Initialization
    init(PlayerID: Int, Score: Int) {
        // Initialize stored properties.
        self.PlayerID = PlayerID
        self.Score = Score
    }
    
}
