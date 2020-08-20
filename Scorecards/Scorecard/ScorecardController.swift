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
    private let goldColor = UIColor(red: 255.0/255.0, green: 217.0/255.0, blue: 0.0/255.0, alpha: 1)
    private let parColor = UIColor(red: 50.0/255.0, green: 168.0/255.0, blue: 54.0/255.0, alpha: 0.5)
    private let birdieColor = UIColor(red: 230.0/255.0, green: 216.0/255.0, blue: 62.0/255.0, alpha: 0.5)
    
    let refreshController = UIRefreshControl()
    var indicator = UIActivityIndicatorView()
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    
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
        
        let row = indexPath.section
        let column = indexPath.item
        let playerIndex = column-1
        let hole = row-1
        let adjustedHole = scorecard!.Front ? hole : hole + 9
        
        // Reset all cell elements
        cell.label.text = ""
        cell.smallLabel.text = ""
        cell.bigImage.image = nil
        cell.bigImage.setNeedsDisplay()
        cell.layer.borderWidth = 0
        cell.layer.backgroundColor = nil
        
        if row == 1 {
            // Header row
            cell.label.font = cell.label.font.withSize(18)
            cell.label.textColor = UIColor.secondaryLabel
            
            if column > 0 && column < getTotalColumns() - 1 {
                // Player names
                cell.layer.backgroundColor = UIColor.tertiaryLabel.cgColor
                
                let player = scorecard!.Players[playerIndex]
                let score = scorecard!.getSumForPlayer(playerIndex: playerIndex)
                
                cell.label.font = cell.label.font.withSize(35)
                cell.label.textColor = UIColor.label
                cell.label.text = String(player.Name.prefix(1))
                if scorecard?.isComplete() ?? true && score == scorecard?.LowestScore {
                    cell.layer.backgroundColor = goldColor.withAlphaComponent(0.8).cgColor
                }
            } else if column == getTotalColumns() - 1 {
                // Par column
                cell.layer.backgroundColor = UIColor.quaternaryLabel.cgColor
                cell.label.font = cell.label.font.withSize(35)
                cell.label.textColor = UIColor.secondaryLabel
                cell.label.text = "P"
            }
        } else if row > 1 && row < getTotalRows() - 1 {
            // Score rows
            if column == 0 {
                // Hole number
                cell.label.font = cell.label.font.withSize(14)
                cell.label.textColor = UIColor.tertiaryLabel
                cell.label.text = String(adjustedHole)
            } else if column > 0 && column < getTotalColumns() - 1 {
                // Player score
                cell.layer.borderColor = UIColor.secondaryLabel.withAlphaComponent(0.25).cgColor
                cell.layer.borderWidth = 1
                
                let score = scorecard!.Scores[hole-1][playerIndex]
                if score.Score == 0 { return cell }
                
                // Highlight pars
                if score.Score == scorecard!.getParForHole(hole: adjustedHole) {
                    cell.layer.backgroundColor = parColor.cgColor
                    //cell.layer.borderColor = parColor.cgColor
                    
                // Highlight birdies and better
                } else if score.Score <= scorecard!.getParForHole(hole: adjustedHole) - 1 {
                    cell.layer.backgroundColor = birdieColor.cgColor
                    //cell.layer.borderColor = birdieColor.cgColor
                }
                
                cell.label.font = cell.label.font.withSize(30)
                cell.label.textColor = UIColor.label
                cell.label.text = String(score.Score)
            } else if column == getTotalColumns() - 1 {
                // Par count
                cell.layer.borderColor = UIColor.secondaryLabel.withAlphaComponent(0.25).cgColor
                cell.layer.borderWidth = 1
                
                cell.label.font = cell.label.font.withSize(30)
                cell.label.textColor = UIColor.secondaryLabel
                cell.label.text = String(scorecard!.getParForHole(hole: adjustedHole))
            }
        } else if row == getTotalRows() - 1 {
            if column > 0 && column < getTotalColumns() - 1 {
                // Total row
                cell.layer.backgroundColor = UIColor.tertiaryLabel.cgColor
                
                let score = scorecard!.getSumForPlayer(playerIndex: playerIndex)
                let under = scorecard!.getUnderForPlayer(playerIndex: playerIndex)
                cell.label.font = cell.label.font.withSize(25)
                cell.label.textColor = UIColor.label
                cell.label.text = "\(score)"
                cell.smallLabel.text = under
            } else if column == getTotalColumns() - 1 {
                // Par total row
                cell.layer.backgroundColor = UIColor.quaternaryLabel.cgColor
                
                cell.label.font = cell.label.font.withSize(25)
                cell.label.textColor = UIColor.label
                cell.label.text = String(scorecard!.getParForGame())
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.section
        let column = indexPath.item
        
        // Only allow selecting score cells
        if column == 0 || column == getTotalColumns() - 1 ||
            row <= 1 || row == getTotalRows() - 1 { return }
        
        // Don't allow editing score of old scorecards
        if scorecard!.isExpired() { return }
        
        scorecard?.incrementScore(hole: indexPath.section-2, playerIndex: indexPath.item-1)
        collectionView.reloadData()
        
        feedback.impactOccurred()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let row = indexPath.section
        let column = indexPath.item
        
        var cellHeight = 63
        var cellWidth = (collectionView.bounds.size.width - 50 - 50) / CGFloat(getTotalColumns() - 2)
        
        if row == 0 {
            // Padding row
            cellHeight = 13
        } else if row == 1 {
            // Header row
            cellHeight = 55
        } else if row == getTotalRows() - 1 {
            // Last row
            cellHeight = 55
        }
        
        if column == 0 {
            // Hole numbers
            cellWidth = 40
        } else if column == getTotalColumns() - 1 {
            // Par count
            cellWidth = 50
        }
        
        return CGSize(width: CGFloat(cellWidth), height: CGFloat(cellHeight))
    }
    
    func getTotalRows() -> Int {
        // 3 = Padding row, player names, total row
        return 3 + (scorecard?.Scores.count ?? 0)
    }
    
    func getTotalColumns() -> Int {
        // 2 = Hole numbers, par counts
        return 2 + (scorecard?.Players.count ?? 0)
    }
    
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
