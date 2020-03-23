//
//  LeaderboardEntry.swift
//  Scorecards
//
//  Created by Joey Lemon on 3/23/20.
//  Copyright © 2020 Joey Lemon. All rights reserved.
//

import Foundation

class LeaderboardListing: Codable {

    //MARK: Properties
    var ID: Int
    var Title: String
    var Entries: [LeaderboardEntry]
    
    private enum CodingKeys: String, CodingKey {
        case ID, Title, Entries
    }

    //MARK: Initialization
    init(ID: Int, Title: String, Entries: [LeaderboardEntry]) {
        // Initialize stored properties.
        self.ID = ID
        self.Title = Title
        self.Entries = Entries
    }

}
