//
//  CreateViewController.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/17/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import UIKit
import CoreLocation

class CreateViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let reuseIdentifier = "playerCell"
    let players = [
        Player(ID: 1, Name: "Joey"),
        Player(ID: 2, Name: "Casey"),
        Player(ID: 3, Name: "Riley"),
        Player(ID: 4, Name: "Wesley"),
        Player(ID: 5, Name: "Mom"),
        Player(ID: 6, Name: "Dad")
    ]
    
    let locManager = CLLocationManager()
    var didCreate: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
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
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // number of rows
        return getTotalRows()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of columns
        return getTotalColumns()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PlayerSelectCell
        
        let player = players[indexPath.section * getTotalRows() + indexPath.item]
        
        cell.image.image = UIImage(systemName: player.Name.lowercased().prefix(1) + ".circle.fill")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellHeight = (collectionView.bounds.size.height) / CGFloat(getTotalRows())
        let cellWidth = (collectionView.bounds.size.width) / CGFloat(getTotalColumns())
        
        return CGSize(width: CGFloat(cellWidth), height: CGFloat(cellHeight))
    }
    
    func getTotalRows() -> Int {
        return 3
    }
    
    func getTotalColumns() -> Int {
        return 2
    }

}
