//
//  PostRequest.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/18/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation
    
func sendPostRequest(url: String, id: Int, completion: @escaping (Data?) -> ()) {
    print("post request to \(url)")
    
    let url = URL(string: url)!
    let session = URLSession.shared

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let postString = "id=\(id)"
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
        
        print(String(data: data, encoding: .utf8) ?? "can't parse result data as UTF")
        
        completion(data)
    })
    task.resume()
}
