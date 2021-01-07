
import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configImgView()
    }
    
    private func configImgView() {
        userImgView.layer.cornerRadius = userImgView.bounds.width / 2
        userImgView.layer.masksToBounds = true
        userImgView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func configCell(conversation: SearchResult) {
        userNameLabel.text = conversation.name
        
        let path = ("images/\(conversation.email)_profile_picture.png")
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
