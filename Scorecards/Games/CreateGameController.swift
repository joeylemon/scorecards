//
//  CreateGameController.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/23/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import UIKit
import CoreLocation

class CreateGameController: UIViewController {
    
    private let greenColor = UIColor(red: 41.0/255.0, green: 141.0/255.0, blue: 36.0/255.0, alpha: 1)
    private let goldColor = UIColor(red: 255.0/255.0, green: 217.0/255.0, blue: 0.0/255.0, alpha: 1)
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet var playerButtons: [UIButton]!
    @IBOutlet var frontBackButtons: [UIButton]!
    @IBOutlet var holeButtons: [UIButton]!
    
    let locManager = CLLocationManager()
    var playerIDs: [String] = [String]()
    var front: Bool = true
    var holes: Int = 9
    var didCreate: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager.requestWhenInUseAuthorization()
        
        for button in playerButtons {
            button.addTarget(self, action: #selector(playerButtonSelected), for: .touchUpInside)
            let image = button.backgroundImage(for: .normal)?.withRenderingMode(.alwaysTemplate)
            button.setBackgroundImage(image, for: .normal)
            button.tintColor = UIColor.secondaryLabel
        }
        
        for button in frontBackButtons {
            button.addTarget(self, action: #selector(frontBackButtonSelected), for: .touchUpInside)
            let image = button.backgroundImage(for: .normal)?.withRenderingMode(.alwaysTemplate)
            button.setBackgroundImage(image, for: .normal)
            
            // Tag==1: front    Tag==2: back
            if button.tag == 1 {
                button.tintColor = goldColor
            } else {
                button.tintColor = UIColor.secondaryLabel
            }
        }
        
        for button in holeButtons {
            button.addTarget(self, action: #selector(holeButtonSelected), for: .touchUpInside)
            let image = button.backgroundImage(for: .normal)?.withRenderingMode(.alwaysTemplate)
            button.setBackgroundImage(image, for: .normal)
            
            if button.tag == 9 {
                button.tintColor = goldColor
            } else {
                button.tintColor = UIColor.secondaryLabel
            }
        }
    }
    
    func getCurrentLocation() -> CLLocation? {
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() ==  .authorizedAlways) {
            return locManager.location
        } else {
            return nil
        }
    }
    
    @objc func playerButtonSelected(sender: UIButton!) {
        didCreate = 1
        
        sender.isSelected = !sender.isSelected;
        
        // Player ID comes from Attributes Inspector -> View -> Tag
        let playerID = String(sender.tag)
        
        if sender.isSelected {
            sender.tintColor = greenColor
            playerIDs.append(playerID)
        } else {
            sender.tintColor = UIColor.secondaryLabel
            playerIDs.removeAll(where: { $0 == playerID })
        }
    }
    
    @objc func frontBackButtonSelected(sender: UIButton!) {
        // Don't allow user to select front/back when choosing 18 holes
        if holes == 18 {
            return
        }
        
        // Tag comes from Attributes Inspector -> View -> Tag
        // Tag==1: front    Tag==2: back
        front = sender.tag == 1
        
        for button in frontBackButtons {
            if button.tag == sender.tag {
                button.tintColor = goldColor
            } else {
                button.tintColor = UIColor.secondaryLabel
            }
        }
    }
    
    @objc func holeButtonSelected(sender: UIButton!) {
        // Hole count comes from Attributes Inspector -> View -> Tag
        holes = sender.tag
        
        for button in holeButtons {
            if button.tag == holes {
                button.tintColor = goldColor
            } else {
                button.tintColor = UIColor.secondaryLabel
            }
        }
        
        // If user selects 18 holes, gray out the front/back buttons
        if holes == 18 {
            for b in frontBackButtons {
                b.tintColor = UIColor.quaternaryLabel
            }
        } else {
            front = true
            frontBackButtons[0].tintColor = goldColor
            frontBackButtons[1].tintColor = UIColor.secondaryLabel
        }
    }
    
}
