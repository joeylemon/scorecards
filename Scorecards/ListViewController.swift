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
    var indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 121
        self.tableView.tableFooterView = UIView() // Only show bottom separators between cells
        
        activityIndicator()
        
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
        cell.locationLabel.text = scorecard.Course.Name
        cell.durationLabel.text = scorecard.DurationString
        
        cell.rowImage.image = UIImage(systemName: scorecard.Winner + ".circle.fill")
        if scorecard.Winner == "t" {
            // Tie
            cell.rowImage.tintColor = UIColor(red: 201.0/255.0, green: 117.0/255.0, blue: 0.0/255.0, alpha: 1)
        } else if scorecard.Winner == "i" {
            // Incomplete
            cell.rowImage.tintColor = UIColor(red: 201.0/255.0, green: 201.0/255.0, blue: 0.0/255.0, alpha: 1)
        } else {
            cell.rowImage.tintColor = UIColor(red: 41.0/255.0, green: 141.0/255.0, blue: 36.0/255.0, alpha: 1)
        }

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let scorecard = scorecards[indexPath.row]
            sendDeleteGameRequest(id: scorecard.ID)
            scorecards.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            case "NewGame":
            os_log("Adding a new game.", log: OSLog.default, type: .debug)

            case "ShowDetail":
            guard let scorecardDetailViewController = segue.destination as? ScorecardController else {
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
        if let gameCreation = sender.source as? CreateGameController, let creation = gameCreation.didCreate {
            if creation == 1 && gameCreation.playerIDs.count > 0 {
                showActivityIndicator()
                
                let loc = gameCreation.getCurrentLocation()?.coordinate
                sendCreateGameRequest(lat: loc?.latitude ?? 0, lon: loc?.longitude ?? 0, players: gameCreation.playerIDs, holes: gameCreation.holes) {
                    DispatchQueue.main.async {
                        self.loadScorecards()
                    }
                }
            }
        }
    }
    
    //MARK: Private Methods
    private func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    private func showActivityIndicator() {
        indicator.startAnimating()
    }
    
    private func hideActivityIndicator() {
        indicator.stopAnimating()
        indicator.hidesWhenStopped = true
    }
    
    @objc private func refreshScorecards(_ sender: Any) {
        loadScorecards()
    }
    
    private func loadScorecards() {
        showActivityIndicator()
        sendGameRequest(url: "https://jlemon.org/golf/listentries", id: -1) { (result) -> () in
            let decoder = JSONDecoder()
            do {
                self.scorecards = try decoder.decode([ScorecardListing].self, from: result!)

                // Can't reload data from non-main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshController.endRefreshing()
                    self.hideActivityIndicator()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}
