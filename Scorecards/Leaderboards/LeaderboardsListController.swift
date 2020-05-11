//
//  LeaderboardsListController.swift
//  Scorecards
//
//  Created by Joey Lemon on 3/23/20.
//  Copyright © 2020 Joey Lemon. All rights reserved.
//

import UIKit
import os.log

class LeaderboardsListController: UITableViewController {
    
    //MARK: Properties
    var listings = [LeaderboardListing]()
    
    let refreshController = UIRefreshControl()
    var indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 92
        self.tableView.tableFooterView = UIView() // Only show bottom separators between cells
        
        activityIndicator()
        
        self.tableView.refreshControl = refreshController
        // Configure Refresh Control
        refreshController.addTarget(self, action: #selector(refreshListings), for: .valueChanged)
        refreshController.attributedTitle = NSAttributedString(string: "Loading stats ...")

        self.loadListings()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "LeaderboardTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LeaderboardTableViewCell  else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        // Fetches the appropriate scorecard for the data source layout.
        let listing = listings[indexPath.row]
        let winner = listing.Entries[0].Name
        
        cell.titleLabel.text = listing.Title
        cell.personLabel.text = listing.Entries[0].Name
        cell.valueLabel.text = listing.Entries[0].Value
        cell.Entries = listing.Entries
        cell.rowImage.image = UIImage(systemName: winner.lowercased().prefix(1) + ".circle.fill")

        return cell
    }

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            case "ShowDetail":
            guard let detailController = segue.destination as? LeaderboardDetailController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

            guard let selectedCell = sender as? LeaderboardTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }

            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }

            let selectedListing = listings[indexPath.row]
            detailController.Title = selectedListing.Title
            detailController.Entries = selectedListing.Entries

            default:
                fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
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
    
    @objc private func refreshListings(_ sender: Any) {
        loadListings()
    }
    
    private func loadListings() {
        showActivityIndicator()
        sendGameRequest(url: "https://jlemon.org/golf/leaderboard", id: -1) { (result) -> () in
            let decoder = JSONDecoder()
            do {
                self.listings = try decoder.decode([LeaderboardListing].self, from: result!)

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
