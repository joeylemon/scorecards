//
//  Scorecard.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/17/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation
import UIKit

class Scorecard: Codable {

    //MARK: Properties
    var ID: Int
    var DateString: String
    var People: String
    var Course: Course
    var Front: Bool
    var Holes: Int
    var LowestScore: Int
    
    var Pars: [Int]
    var Scores: [[Score]] = []
    var Players: [Player]
    
    var age: Int = 0
    var curTask: DispatchWorkItem = DispatchWorkItem {}
    
    private enum CodingKeys: String, CodingKey {
        case ID, DateString, People, Course, Front, Holes, LowestScore, Pars, Scores, Players
    }

    //MARK: Initialization
    init(listing: ScorecardListing) {
        // Initialize stored properties.
        self.ID = listing.ID
        self.DateString = listing.DateString
        self.People = listing.People
        self.Course = listing.Course
        self.Front = true
        self.Holes = listing.HoleCount
        self.LowestScore = 200
        self.Scores = [[Score]]()
        self.Players = [Player]()
        self.Pars = [Int]()
    }
    
    func load(loaded: @escaping () -> Void) {
        sendGameRequest(url: "https://jlemon.org/golf/getgamenew", id: self.ID, completion: { result in
            let decoder = JSONDecoder()
            do {
                let jsonScorecard = try decoder.decode(Scorecard.self, from: result!)
                self.Scores = jsonScorecard.Scores
                self.Players = jsonScorecard.Players
                self.Pars = jsonScorecard.Pars
                self.LowestScore = jsonScorecard.LowestScore
                self.Front = jsonScorecard.Front
                
                loaded()
            } catch {
                print(error.localizedDescription)
            }
        })
    }
    
    func isExpired() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d yyyy"
        if let date = dateFormatter.date(from: self.DateString) {
            let today = Date()
            return today.timeIntervalSince(date) > 86400
        }
        
        return false
    }
    
    func isComplete() -> Bool {
        // Check if any of the scores in the first column are 0
        for hole in 0..<self.Holes {
            if self.Scores[hole][0].Score == 0 { return false }
        }
        
        return true
    }
    
    func getParForHole(hole: Int) -> Int {
        return self.Pars[hole-1]
    }
    
    func getParForGame() -> Int {
        var sum = 0
        
        // Begin/end change depending on if the game is front nine or back nine
        var begin = 0
        var end = self.Holes
        if !self.Front {
            begin = 9
            end = 18
        }
        
        for hole in begin..<end {
            sum += self.Pars[hole]
        }
        
        return sum
    }
    
    func getPlayerIDs() -> [String] {
        var names = [String]()
        for player in Players {
            names.append(String(player.ID))
        }
        return names
    }
    
    func getUnderForPlayer(playerIndex: Int) -> String {
        var under = 0
        for hole in 0..<self.Holes {
            let score = self.Scores[hole][playerIndex].Score
            if score > 0 {
                under += score - self.getParForHole(hole: hole+1)
            }
        }
        return under >= 0 ? "+\(under)" : "\(under)"
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
