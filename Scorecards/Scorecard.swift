//
//  Scorecard.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/17/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation

class Scorecard: Codable {

    //MARK: Properties
    var ID: Int
    var Date: String
    var People: String
    var Location: String
    var Holes: Int
    
    var Scores: [[Score]] = []
    var Players: [Player]

    //MARK: Initialization
    init(listing: ScorecardListing) {
        // Initialize stored properties.
        self.ID = listing.ID
        self.Date = listing.DateString
        self.People = listing.People
        self.Location = listing.Location
        self.Holes = listing.HoleCount
        self.Scores = [[Score]]()
        self.Players = [Player]()
        
        sendPostRequest(url: "https://jlemon.org/golf/getgamenew", id: self.ID) { (result) -> () in
            let decoder = JSONDecoder()
            do {
                let jsonScorecard = try decoder.decode(Scorecard.self, from: result!)
                self.Scores = jsonScorecard.Scores
                self.Players = jsonScorecard.Players
                for (holeNum, arr) in self.Scores.enumerated() {
                    for score in arr {
                        let playerName = self.Players.first{$0.ID == score.PlayerID}?.Name
                        print("score on hole \(holeNum) for player \(playerName ?? "UNK") is \(score.Score)")
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}
