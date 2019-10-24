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
    var DateString: String
    var People: String
    var Location: String
    var Holes: Int
    var LowestScore: Int
    
    var Scores: [[Score]] = []
    var Players: [Player]
    
    var age: Int = 0
    var curTask: DispatchWorkItem = DispatchWorkItem {}
    
    private enum CodingKeys: String, CodingKey {
        case ID, DateString, People, Location, Holes, LowestScore, Scores, Players
    }

    //MARK: Initialization
    init(listing: ScorecardListing) {
        // Initialize stored properties.
        self.ID = listing.ID
        self.DateString = listing.DateString
        self.People = listing.People
        self.Location = listing.Location
        self.Holes = listing.HoleCount
        self.LowestScore = 200
        self.Scores = [[Score]]()
        self.Players = [Player]()
        
        // Calculate age of game by converting date string to date
        // and subtracting from now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = dateFormatter.date(from:self.DateString)!
        
        let calendar = Calendar.current
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfTimeStamp = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfTimeStamp, to: startOfNow)
        age = components.day!
    }
    
    func load(loaded: @escaping () -> Void) {
        sendGameRequest(url: "https://jlemon.org/golf/getgamenew", id: self.ID, completion: { result in
            let decoder = JSONDecoder()
            do {
                let jsonScorecard = try decoder.decode(Scorecard.self, from: result!)
                self.Scores = jsonScorecard.Scores
                self.Players = jsonScorecard.Players
                self.LowestScore = jsonScorecard.LowestScore
                
                loaded()
            } catch {
                print(error.localizedDescription)
            }
        })
    }
    
    func isComplete() -> Bool {
        var complete = true
        
        // Check if any of the scores in the first column are 0
        for hole in 0..<self.Holes {
            if self.Scores[hole][0].Score == 0 { complete = false }
        }
        
        return complete
    }
    
    func isNewGame() -> Bool {
        return age < 1
    }
    
    func getPlayerIDs() -> [String] {
        var names = [String]()
        for player in Players {
            names.append(String(player.ID))
        }
        return names
    }
    
    func getSumForPlayer(playerIndex: Int) -> Int {
        var sum = 0
        for hole in 0..<self.Holes {
            sum += self.Scores[hole][playerIndex].Score
        }
        return sum
    }
    
    func incrementScore(hole: Int, playerIndex: Int) {
        self.Scores[hole][playerIndex].Score += 1
        if self.Scores[hole][playerIndex].Score > 10 {
            self.Scores[hole][playerIndex].Score = 0
        }
        
        curTask.cancel()
        let task = DispatchWorkItem {
            sendSetScoreRequest(id: self.ID, scores: self.Scores, playerIDs: self.getPlayerIDs(), completion: { result in
                self.curTask.cancel()
            }, incomplete: {
                self.incrementScore(hole: hole, playerIndex: playerIndex)
            })
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: task)
        curTask = task
    }

}
