//
//  ConversationCell.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 9/21/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import SDWebImage

class ConversationCell: UITableViewCell {
    
    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configImgView()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    private func configImgView() {
        userImgView.layer.cornerRadius = userImgView.bounds.width / 2
        userImgView.layer.masksToBounds = true
        userImgView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func configCell(conversation: Conversation) {
        self.messageLabel.text = conversation.latestMsg.message
        self.userNameLabel.text = conversation.name
        
        let path = ("images/\(conversation.otherUserEmail)_profile_picture.png")
        StorageManager.shared.downloadUrl(with: path) { [weak self] (Result) in
            switch Result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImgView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}
