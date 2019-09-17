//
//  EarthquakeTableViewCell.swift
//  OperationExample
//
//  Created by viwii on 2019/9/16.
//  Copyright © 2019 viwii. All rights reserved.
//

import UIKit

class EarthquakeTableViewCell: UITableViewCell {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var magnitudeLabel: UILabel!
    @IBOutlet weak var magnitudeImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
