//
//  ListViewController.swift
//  FoodTrack
//
//  Created by Joey Lemon on 10/17/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import UIKit
import os.log

class ListViewController: UITableViewController {
    
    //MARK: Properties
    var scorecards = [ScorecardListing]()
    
    let refreshController = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 95
        self.tableView.tableFooterView = UIView() // Only show bottom separators between cells
        
        self.tableView.refreshControl = refreshController
        // Configure Refresh Control
        refreshController.addTarget(self, action: #selector(refreshScorecards), for: .valueChanged)
        refreshController.attributedTitle = NSAttributedString(string: "Loading games ...")
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem

        // Load the sample data.
        loadScorecards()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scorecards.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ScorecardTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ScorecardTableViewCell  else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        // Fetches the appropriate scorecard for the data source layout.
        let scorecard = scorecards[indexPath.row]
        cell.dateLabel.text = scorecard.DateString
        cell.peopleLabel.text = scorecard.People
        cell.locationLabel.text = scorecard.Location

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let scorecard = scorecards[indexPath.row]
            print("Delete scorecard id=\(scorecard.ID) date=\(scorecard.DateString)")
            
            scorecards.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            case "NewGame":
            os_log("Adding a new game.", log: OSLog.default, type: .debug)

            case "ShowDetail":
            guard let scorecardDetailViewController = segue.destination as? ScorecardTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

            guard let selectedScorecardCell = sender as? ScorecardTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }

            guard let indexPath = tableView.indexPath(for: selectedScorecardCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }

            let selectedScorecard = scorecards[indexPath.row]
            scorecardDetailViewController.scorecardListing = selectedScorecard

            default:
                fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToScorecardList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? CreateViewController, let creation = sourceViewController.didCreate {
            if creation == 1 {
                self.loadScorecards()
            }
        }
    }
    
    //MARK: Private Methods
    @objc private func refreshScorecards(_ sender: Any) {
        loadScorecards()
    }
    
    private func loadScorecards() {
        sendPostRequest(url: "https://jlemon.org/golf/listentries", id: -1) { (result) -> () in
            let decoder = JSONDecoder()
            do {
                self.scorecards = try decoder.decode([ScorecardListing].self, from: result!)
                
                // Can't reload data from non-main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshController.endRefreshing()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}
