//
//  ScorecardTableViewController.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/18/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import UIKit

class ScorecardTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    var scorecardListing: ScorecardListing?
    var scorecard: Scorecard?
    var dataLoaded = false
    
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scorecardListing = scorecardListing {
            navigationItem.title = scorecardListing.DateString
            
            scorecard = Scorecard(listing: scorecardListing)
            
            activityIndicator()
            showActivityIndicator()
            scorecard?.load {
                DispatchQueue.main.async {
                    self.dataLoaded = true
                    self.tableView.reloadData()
                    self.hideActivityIndicator()
                }
            }
        }
        
        self.tableView.allowsSelection = false // Disable row highlighting
        self.tableView.rowHeight = 50;
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getTotalRows()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ScorecardScoreCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ScorecardScoreCell  else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        // Don't continue if the data isn't loaded yet
        if !dataLoaded { return cell }
        
        // Remove previous labels from stack view
        cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
        
        if indexPath.row == 1 {
            addLabel(text: "", toView: cell.stackView)
            scorecard?.Players.forEach { player in
                addLabel(text: player.Name, toView: cell.stackView)
            }
        } else if indexPath.row > 1 && indexPath.row != getTotalRows() {
            addLabel(text: String(indexPath.row - 1), toView: cell.stackView)
            scorecard?.Scores[indexPath.row-2].forEach { score in
                addButton(text: String(score.Score), toView: cell.stackView)
            }
        }

        return cell
    }
    
    func addLabel(text: String, toView: UIStackView) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        label.textAlignment = .center
        label.text = text
        toView.addArrangedSubview(label)
    }
    
    func addButton(text: String, toView: UIStackView) {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 100)
        button.backgroundColor = UIColor.red
        button.setTitle(text, for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        toView.addArrangedSubview(button)
    }
    
    @objc func buttonAction(sender: UIButton!) {
       print("Button tapped")
    }
    
    func getTotalRows() -> Int {
        return 2 + (scorecard?.Scores.count ?? 0)
    }
 
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    private func showActivityIndicator() {
        indicator.startAnimating()
        indicator.backgroundColor = .white
    }
    
    private func hideActivityIndicator() {
        indicator.stopAnimating()
        indicator.hidesWhenStopped = true
    }

}
