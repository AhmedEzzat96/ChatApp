
import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage


class ChatVC: MessagesViewController {

    public let otherUserEmail: String
    private let convId: String?
    public var isNewConv = false
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.convId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputBtn()

    }
    
    private func setupInputBtn() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = .lightGray
        button.onTouchUpInside { [weak self] _ in
            self?.inputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func inputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {  _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach photo",
                                            message: "Where you would like to attach photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: false)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: false)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = convId {
            listenForMsgs(id: conversationId, shouldScrollToButtom: true)
        }
    }
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private func listenForMsgs(id : String, shouldScrollToButtom: Bool) {
        DatabaseManager.shared.getAllMsgForConv(with: id) { [weak self] (result) in
            switch result {
                
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    if shouldScrollToButtom {
                        self?.messagesCollectionView.reloadData()
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

}

extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
            let imgData = image.pngData(),
            let createMsgId = createMsgId(),
            let name = self.title,
            let selfSender = self.selfSender,
            let convId = convId
            else {
                return
        }
        let fileName = ("photo_message_\(createMsgId.replacingOccurrences(of: " ", with: "-")).png")
        
        // upload image, then send image
        StorageManager.shared.uploadMsgPhoto(with: imgData, fileName: fileName) { [weak self](result) in
            guard let strongSelf = self else {
                return
            }
            switch result {
                
            case .success(let urlString):
                
                guard let url = URL(string: urlString),
                    let placeholder = UIImage(systemName: "plus") else {
                        return
                }
                
                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placeholder,
                                  size: .zero)
                
                let message = Message(sender: selfSender,
                                      messageId: createMsgId,
                                      sentDate: Date(),
                                      kind: .photo(media))
                
                DatabaseManager.shared.sendMsg(to: convId, newMessage: message, otherUserEmail: strongSelf.otherUserEmail, name: name) { (success) in
                    if success {
                        print("Sent photo msg")
                    } else {
                        print("Failed to send photo msg")
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let msgId = createMsgId()
            else {
                return
        }
        let message = Message(sender: selfSender,
                              messageId: msgId,
                              sentDate: Date(),
                              kind: .text(text))
        if isNewConv {
            // create new conv in database
            DatabaseManager.shared.createNewConv(with: otherUserEmail, firstMessage: message, name: self.title ?? "") { [weak self] (success) in
                if success {
                    print("Msg Send")
                    self?.isNewConv = false
                } else {
                    print("Failed to send msg")
                }
            }
        } else {
            
            // append to existing data
            guard let conversationId = self.convId, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMsg(to: conversationId, newMessage: message, otherUserEmail: otherUserEmail , name: name) { (success) in
                if success {
                    print("Message send")
                } else {
                    print("Failed to send msg")
                }
            }
        }
    }
    
    private func createMsgId() -> String? {
        let dateString = ChatVC.dateFormatter.string(from: Date())
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
            else {
                return nil
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        let newIdentifier = ("\(otherUserEmail)_\(currentEmail)_\(dateString)")
        return newIdentifier
    }
}

extension ChatVC: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("selfSender is Nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    
}

extension ChatVC: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let photoViewerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoViewerVC") as! PhotoViewerVC
            photoViewerVC.title = message.sender.displayName
            photoViewerVC.imgUrl = imageUrl
            self.navigationController?.pushViewController(photoViewerVC, animated: true)
            
        default:
            break
        }
    }
}
