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
    var Title: String
    var Entries: [LeaderboardEntry]
    
    private enum CodingKeys: String, CodingKey {
        case Title, Entries
    }

    //MARK: Initialization
    init(Title: String, Entries: [LeaderboardEntry]) {
        // Initialize stored properties.
        self.Title = Title
        self.Entries = Entries
    }

}
