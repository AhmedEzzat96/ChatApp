//
//  UserNameProfileCellTableViewCell.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 10/2/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit

class UserNameProfileCell: UITableViewCell {
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let name = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        userNameLabel.text = name
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
