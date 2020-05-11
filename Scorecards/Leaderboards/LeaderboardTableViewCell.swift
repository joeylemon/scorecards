//
//  LeaderboardTableViewCell.swift
//  Scorecards
//
//  Created by Joey Lemon on 3/23/20.
//  Copyright © 2020 Joey Lemon. All rights reserved.
//

import UIKit

class LeaderboardTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var rowImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var personLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    var Entries = [LeaderboardEntry]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
