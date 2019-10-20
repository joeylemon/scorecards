//
//  CreateViewController.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/17/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import UIKit
import CoreLocation

class CreateViewController: UIViewController {
    
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let locManager = CLLocationManager()
    var didCreate: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        didCreate = 1
        
        locManager.requestWhenInUseAuthorization()
        print(getCurrentLocation()?.coordinate.latitude ?? "Can't get current latitude")
        print(getCurrentLocation()?.coordinate.longitude ?? "Can't get current longitude")
    }
    
    func getCurrentLocation() -> CLLocation? {
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() ==  .authorizedAlways) {
            return locManager.location
        } else {
            return nil
        }

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
