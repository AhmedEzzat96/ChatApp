//
//  ConversationCell.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 9/21/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit

class ConversationCell: UITableViewCell {

    @IBOutlet weak var helloTextField: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
