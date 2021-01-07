
import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation


class ChatVC: MessagesViewController {
    
    private var senderUserPhotoUrl: URL?
    private var otherUserPhotoUrl: URL?
    
    public let otherUserEmail: String
    private var convId: String?
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
        print("isNewConv: \(isNewConv)")
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
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self]  _ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let locationPickerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationPickerVC") as! LocationPickerVC
        locationPickerVC.navigationItem.largeTitleDisplayMode = .never
        locationPickerVC.title = "Pick Location"
        locationPickerVC.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self else {
                return
            }
            guard let createMsgId = strongSelf.createMsgId(),
                let name = strongSelf.title,
                let selfSender = strongSelf.selfSender,
                let convId = strongSelf.convId
                else {
                    return
            }
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: createMsgId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMsg(to: convId, newMessage: message, otherUserEmail: strongSelf.otherUserEmail, name: name) { (success) in
                if success {
                    print("Sent location msg")
                } else {
                    print("Failed to send location msg")
                }
            }

            
            print("long: \(longitude) lat: \(latitude)")
            
        }
        navigationController?.pushViewController(locationPickerVC, animated: true)
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
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where you would like to attach video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: false)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: false)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = convId {
            listenForMsgs(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private func listenForMsgs(id : String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMsgForConv(with: id) { [weak self] (result) in
            switch result {
                
            case .success(let messages):
                print("message: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()

                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
                
            case .failure(let error):
                print("failed to get messages: \(error)")
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
        
        guard let createMsgId = createMsgId(),
            let name = self.title,
            let selfSender = self.selfSender,
            let convId = convId
            else {
                return
        }
        
        // upload image, then send image
        if let image = info[.editedImage] as? UIImage, let imgData = image.pngData() {
            let fileName = ("photo_message_\(createMsgId.replacingOccurrences(of: " ", with: "-")).png")
            
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
        } else if let videoUrl = info[.mediaURL] as? URL{
            
            let fileName = ("video_message_\(createMsgId.replacingOccurrences(of: " ", with: "-")).mov")
            guard let videoData = NSData(contentsOf: videoUrl) as Data? else {
                return
            }
            print(videoUrl)
            
            // upload video
            StorageManager.shared.uploadMsgVideo(with: videoData, fileName: fileName) { [weak self] (result) in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                    
                case .success(let urlString):
                    print("video msg uploaded: \(urlString) ")
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
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMsg(to: convId, newMessage: message, otherUserEmail: strongSelf.otherUserEmail, name: name) { (success) in
                        if success {
                            print("Sent video msg")
                        } else {
                            print("Failed to send video msg")
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
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
            DatabaseManager.shared.createNewConv(with: otherUserEmail, firstMessage: message, name: self.title ?? "User") { [weak self] (success) in
                if success == true {
                    print("Msg Send")
                    self?.isNewConv = false
                    let newConvId = ("conversation_\(message.messageId)")
                    self?.convId = newConvId
                    self?.listenForMsgs(id: newConvId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("Failed to send msg")
                }
            }
        } else {
            
            // append to existing data
            guard let conversationId = self.convId, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMsg(to: conversationId, newMessage: message, otherUserEmail: otherUserEmail , name: name) { [weak self] (success) in
                if success == true {
                    print("Message send")
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("Failed to send msg")
                }
            }
        }
    }
    
    private func createMsgId() -> String? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
            else {
                return nil
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: email)
        let dateString = ChatVC.dateFormatter.string(from: Date())
        let newIdentifier = ("\(otherUserEmail)_\(currentEmail)_\(dateString)")
        print("created message id: \(newIdentifier)")
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
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
                return
            }
            let message = messages[indexPath.section]
            
            switch message.kind {
            case .location(let locationData):
                let coordinates = locationData.location.coordinate
                
                let locationPickerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationPickerVC") as! LocationPickerVC
                locationPickerVC.coordinates = coordinates
                locationPickerVC.isPickable = locationPickerVC.coordinates == nil
                locationPickerVC.title = "Location"
                self.navigationController?.pushViewController(locationPickerVC, animated: true)
        
            default:
                break
            }
    }
    
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
            
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let videoPlayer = AVPlayerViewController()
            videoPlayer.player = AVPlayer(url: videoUrl)
            present(videoPlayer, animated: true) {
                videoPlayer.player?.play()
            }
    
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our msg we have sent
            return .systemBlue
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            if let currentUserPhotoUrl = self.senderUserPhotoUrl {
                avatarView.sd_setImage(with: currentUserPhotoUrl, completed: nil)
            } else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadUrl(with: path) { [weak self] (result) in
                    switch result {
                    case .success(let url):
                        self?.senderUserPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("failed to download url \(error)")
                    }
                }
            }
            
        } else {
            if let otherUserPhotoUrl = self.otherUserPhotoUrl {
                avatarView.sd_setImage(with: otherUserPhotoUrl, completed: nil)
            } else {
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadUrl(with: path) { [weak self] (result) in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("failed to download url \(error)")
                    }
                }
            }
        }
    }
    
    
}
