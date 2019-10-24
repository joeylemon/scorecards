//
//  Scorecard.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/17/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation

class ScorecardListing: Codable {

    //MARK: Properties
    var ID: Int
    var DateString: String
    var DurationString: String
    var People: String
    var Location: String
    var HoleCount: Int
    var Winner: String
    
    private enum CodingKeys: String, CodingKey {
        case ID, DateString, DurationString, People, Location, HoleCount, Winner
    }

    //MARK: Initialization
    init(ID: Int, DateString: String, DurationString: String, People: String, Location: String, HoleCount: Int, Winner: String) {
        // Initialize stored properties.
        self.ID = ID
        self.DateString = DateString
        self.DurationString = DurationString
        self.People = People
        self.Location = Location
        self.HoleCount = HoleCount
        self.Winner = Winner
    }

}
