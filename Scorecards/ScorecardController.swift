//
//  ScorecardController.swift
//  Scorecards
//
//  Created by Joey Lemon on 10/21/19.
//  Copyright © 2019 Joey Lemon. All rights reserved.
//

import UIKit

class ScorecardController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "cell"
    private let greenColor = UIColor(red: 41.0/255.0, green: 141.0/255.0, blue: 36.0/255.0, alpha: 1)
    private let goldColor = UIColor(red: 255.0/255.0, green: 217.0/255.0, blue: 0.0/255.0, alpha: 1)
    
    let refreshController = UIRefreshControl()
    var indicator = UIActivityIndicatorView()
    
    var scorecardListing: ScorecardListing?
    var scorecard: Scorecard?
    var dataLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.refreshControl = refreshController
        refreshController.addTarget(self, action: #selector(refreshScores), for: .valueChanged)
        refreshController.attributedTitle = NSAttributedString(string: "Loading scores ...")
        
        // Lets controller use sizeForItemAt func
        collectionView.delegate = self

        if let scorecardListing = scorecardListing {
            navigationItem.title = scorecardListing.DateString
            
            scorecard = Scorecard(listing: scorecardListing)
            
            activityIndicator()
            showActivityIndicator()
            self.loadScores()
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

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! ScoreCell
        
        if !dataLoaded { return cell }
        
        let playerIndex = indexPath.item-1
        
        // Reset all cell elements
        cell.label.text = ""
        cell.bigImage.image = nil
        cell.bigImage.setNeedsDisplay()
        cell.layer.borderWidth = 0
        cell.layer.backgroundColor = nil
        
        if indexPath.section == 1 {
            // Header row
            cell.label.font = cell.label.font.withSize(18)
            cell.label.textColor = UIColor.secondaryLabel
            
            if indexPath.item != 0 {
                cell.layer.backgroundColor = UIColor.tertiaryLabel.cgColor
                
                let player = scorecard!.Players[playerIndex]
                let score = scorecard!.getSumForPlayer(playerIndex: playerIndex)
                
                cell.label.font = cell.label.font.withSize(35)
                cell.label.textColor = UIColor.label
                cell.label.text = String(player.Name.prefix(1))
                if scorecard?.isComplete() ?? true && score == scorecard?.LowestScore {
                    cell.layer.backgroundColor = goldColor.withAlphaComponent(0.8).cgColor
                }
            }
        } else if indexPath.section > 1 && indexPath.section < getTotalRows() - 1 {
            // Score rows
            if indexPath.item == 0 {
                // Hole number
                cell.label.font = cell.label.font.withSize(14)
                cell.label.textColor = UIColor.tertiaryLabel
                cell.label.text = String(indexPath.section-1)
            } else {
                // Player score
                cell.layer.borderColor = UIColor.secondaryLabel.withAlphaComponent(0.25).cgColor
                cell.layer.borderWidth = 1
                
                let score = scorecard!.Scores[indexPath.section-2][playerIndex]
                if score.Score == 0 { return cell }
                
                cell.label.font = cell.label.font.withSize(30)
                cell.label.textColor = UIColor.label
                cell.label.text = String(score.Score)
            }
        } else if indexPath.section == getTotalRows() - 1 {
            // Total row
            if indexPath.item != 0 {
                cell.layer.backgroundColor = UIColor.tertiaryLabel.cgColor
                
                let score = scorecard!.getSumForPlayer(playerIndex: playerIndex)
                cell.label.font = cell.label.font.withSize(25)
                cell.label.textColor = UIColor.label
                cell.label.text = String(score)
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Only allow selecting score cells
        if indexPath.item == 0 || indexPath.section <= 1 || indexPath.section == getTotalRows() - 1 { return }
        
        scorecard?.incrementScore(hole: indexPath.section-2, playerIndex: indexPath.item-1)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var cellHeight = 63
        var cellWidth = (collectionView.bounds.size.width - 50) / CGFloat(getTotalColumns() - 1)
        
        if indexPath.section == 0 {
            // Padding row
            cellHeight = 13
        }else if indexPath.section == 1 {
            // Header row
            cellHeight = 55
        } else if indexPath.section == getTotalRows() - 1 {
            // Last row
            cellHeight = 55
        }
        
        if indexPath.item == 0 {
            // Hole numbers
            cellWidth = 40
        }
        
        return CGSize(width: CGFloat(cellWidth), height: CGFloat(cellHeight))
    }
    
    func getTotalRows() -> Int {
        return 3 + (scorecard?.Scores.count ?? 0)
    }
    
    func getTotalColumns() -> Int {
        return 1 + (scorecard?.Players.count ?? 0)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc private func refreshScores(_ sender: Any) {
        loadScores()
    }
    
    private func loadScores() {
        scorecard?.load {
            DispatchQueue.main.async {
                self.dataLoaded = true
                self.collectionView.reloadData()
                self.hideActivityIndicator()
                self.refreshController.endRefreshing()
            }
        }
    }
    
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

}
