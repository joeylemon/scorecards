//
//  LeaderboardEntry.swift
//  Scorecards
//
//  Created by Joey Lemon on 3/23/20.
//  Copyright © 2020 Joey Lemon. All rights reserved.
//

import Foundation

class LeaderboardEntry: Codable {

    //MARK: Properties
    var Name: String
    var Value: String
    var GameList: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case Name, Value, GameList
    }

    //MARK: Initialization
    init(Name: String, Value: String, GameList: [Int]) {
        // Initialize stored properties.
        self.Name = Name
        self.Value = Value
        self.GameList = GameList
    }

}
