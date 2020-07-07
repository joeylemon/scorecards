//
//  PostRequest.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/18/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation
import UIKit
    
func sendGameRequest(url: String, id: Int, completion: @escaping (Data?) -> ()) {
    let url = URL(string: url)!
    let session = URLSession.shared

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let postString = "id=\(id)&device=\(UIDevice.current.name)"
    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = postString.data(using: String.Encoding.utf8)

    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

        guard error == nil else {
            print(error ?? "no error")
            return
        }

        guard let data = data else {
            print("can't let data = data")
            return
        }
        
        //print(String(data: data, encoding: .utf8) ?? "can't parse result data as UTF")
        
        completion(data)
    })
    task.resume()
}

func sendSetScoreRequest(id: Int, scores: [[Score]], playerIDs: [String], completion: @escaping (Data?) -> (), incomplete: @escaping () -> ()) {
    let url = URL(string: "https://jlemon.org/golf/setscorenew")!
    let session = URLSession.shared

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    var postArray = [String]()
    for hole in 0..<scores.count {
        for score in scores[hole] {
            postArray.append("score[\(hole+1)][\(score.PlayerID)]=\(score.Score)")
        }
    }
    postArray.append("gameID=\(id)")
    postArray.append("holes=\(scores.count)")
    postArray.append("players=\(playerIDs.joined(separator: ","))")
    postArray.append("device=\(UIDevice.current.name)")
    let postString = postArray.joined(separator: "&")
    
    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = postString.data(using: String.Encoding.utf8)

    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

        guard error == nil else {
            print(error ?? "no error")
            return
        }

        guard let data = data else {
            print("can't let data = data")
            return
        }
        
        completion(data)
    })
    task.resume()
}

func sendDeleteGameRequest(id: Int) {
    let url = URL(string: "https://jlemon.org/golf/deletegame")!
    let session = URLSession.shared

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let postString = "game=\(id)&device=\(UIDevice.current.name)"
    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = postString.data(using: String.Encoding.utf8)

    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
        guard error == nil else {
            print(error ?? "no error")
            return
        }
    })
    task.resume()
}

func sendCreateGameRequest(lat: Double, lon: Double, players: [String], front: Bool, holes: Int, completion: @escaping () -> ()) {
    let url = URL(string: "https://jlemon.org/golf/createnew")!
    let session = URLSession.shared

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let postString = "lat=\(lat)&lon=\(lon)&players=\(players.joined(separator: ","))&front=\(front)&holes=\(holes)&device=\(UIDevice.current.name)"
    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = postString.data(using: String.Encoding.utf8)

    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
        guard error == nil else {
            print(error ?? "no error")
            return
        }
        
        completion()
    })
    task.resume()
}
