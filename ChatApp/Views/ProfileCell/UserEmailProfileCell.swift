//
//  UserEmailProfileCell.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 10/2/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit

class UserEmailProfileCell: UITableViewCell {
    @IBOutlet weak var userEmailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        userEmailLabel.text = email
        selectionStyle = .none
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
