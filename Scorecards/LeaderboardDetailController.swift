//
//  LeaderboardDetailController.swift
//  Scorecards
//
//  Created by Joey Lemon on 3/23/20.
//  Copyright © 2020 Joey Lemon. All rights reserved.
//

import UIKit
import os.log

class LeaderboardDetailController: UITableViewController {
    
    //MARK: Properties
    var Title = String()
    var Entries = [LeaderboardEntry]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 60
        self.tableView.tableFooterView = UIView() // Only show bottom separators between cells
        
        navigationItem.title = Title
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "LeaderboardListingTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LeaderboardListingTableViewCell  else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        // Fetches the appropriate scorecard for the data source layout.
        let entry = Entries[indexPath.row]
        
        cell.personLabel.text = entry.Name
        cell.valueLabel.text = entry.Value
        cell.rowImage.image = UIImage(systemName: entry.Name.lowercased().prefix(1) + ".circle.fill")

        return cell
    }
    
}
