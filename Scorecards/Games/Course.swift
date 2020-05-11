//
//  Course.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/27/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import Foundation

class Course: Codable {

    //MARK: Properties
    var ID: Int
    var Name: String
    var Latitude: Float
    var Longitude: Float

    //MARK: Initialization
    init(ID: Int, Name: String, Latitude: Float, Longitude: Float) {
        // Initialize stored properties.
        self.ID = ID
        self.Name = Name
        self.Latitude = Latitude
        self.Longitude = Longitude
    }

}
