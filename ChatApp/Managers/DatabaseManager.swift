import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

extension DatabaseManager {
    public func getDataForUser(with path: String, completion: @escaping (Result<Any, Error>)  -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)) {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func getUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseErrors: Error {
        case failedToFetch
    }
    
    /// insert user in database
    public func createUser(with user: User, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
            ], withCompletionBlock: { [weak self] error, _ in
                guard error == nil else {
                    print("failed to write to database")
                    completion(false)
                    return
                }
                self?.database.child("users").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElement = [
                            "name": "\(user.firstName ?? "") \(user.lastName ?? "")",
                            "safeEmail": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        self?.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    } else {
                        // create that array
                        let newCollection: [[String: String]] = [
                            ["name": "\(user.firstName ?? "") \(user.lastName ?? "")",
                                "safeEmail": user.safeEmail]
                        ]
                        self?.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                }
        })
    }
}
// Mark :- Send messages & conversations
extension DatabaseManager {
    /// create new conversation with user email & his first message sent
    public func createNewConv(with otherUserEmail: String, firstMessage: Message, name: String, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String
            else {
                return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
            case .text(let msgText):
                message = msgText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let convId = ("conversation_\(firstMessage.messageId)")
            
            let newConversationData: [String: Any] = [
                "id": convId,
                "name": name,
                "otherUserEmail": otherUserEmail,
                "latestMsg": [
                    "date": dateString,
                    "message": message,
                    "isRead": false
                ]
            ]
            
            let recipientNewConvData: [String: Any] = [
                "id": convId,
                "name": currentName,
                "otherUserEmail": safeEmail,
                "latestMsg": [
                    "date": dateString,
                    "message": message,
                    "isRead": false
                ]
            ]
            
            // Update recipient conversaiton entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                if var conversations = snapshot.value as? [[String: Any]] {

                    conversations.append(recipientNewConvData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {

                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConvData])
                }
            }
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreateConv(name: name,
                                           convId: convId,
                                           firstMsg: firstMessage,
                                           completion: completion)
                })
                
            } else {
                userNode["conversations"] = [ newConversationData ]
                
                ref.setValue(userNode, withCompletionBlock: { (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreateConv(name: name,
                                           convId: convId,
                                           firstMsg: firstMessage,
                                           completion: completion)
                })
            }
        })
    }
    
    private func finishCreateConv(name: String, convId: String, firstMsg: Message, completion: @escaping (Bool) -> Void) {
        
        var message = ""
        switch firstMsg.kind {
        case .text(let msgText):
            message = msgText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMsg.sentDate
        let dateString = ChatVC.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let msgCollection: [String: Any] = [
            "id": firstMsg.messageId ,
            "type": firstMsg.kind.msgKindString,
            "content": message,
            "date": dateString,
            "senderEmail": currentUserEmail,
            "isRead": false,
            "name": name
        ]
        
        
        
        let value: [String: Any] = [
            "messages": [msgCollection]
        ]
        
        print("adding convo: \(convId)")
        
        database.child("\(convId)").setValue(value, withCompletionBlock: { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    /// fetch & return all conversation for user with email
    public func getAllConv(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe( .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let conversationArr: [Conversation] = value.compactMap { (dictionary) in
                guard let convId = dictionary["id"] as? String,
                    let latestMsg = dictionary["latestMsg"] as? [String: Any],
                    let date = latestMsg["date"] as? String,
                    let isRead = latestMsg["isRead"] as? Bool,
                    let message = latestMsg["message"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["otherUserEmail"] as? String else {
                        return nil
                }
                let latestMsgObject = LatestMsg(date: date,
                                                isRead: isRead,
                                                message: message)
                return Conversation(id: convId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMsg: latestMsgObject)
            }
            completion(.success(conversationArr))
        }
    }
    /// get all messages for a given conversation
    public func getAllMsgForConv(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let messageArr: [Message] = value.compactMap { (dictionary) in
                guard let content = dictionary["content"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let id = dictionary["id"] as? String,
                    let isRead = dictionary["isRead"] as? Bool,
                    let name = dictionary["name"] as? String,
                    let senderEmail = dictionary["senderEmail"] as? String,
                    let type = dictionary["type"] as? String,
                    let date = ChatVC.dateFormatter.date(from: dateString)
                    else {
                        return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    guard let imgUrl = URL(string: content),
                        let placeHolder = UIImage(systemName: "plus") else {
                            return nil
                    }
                    let media = Media(url: imgUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let videoUrl = URL(string: content),
                        let placeHolder = UIImage(named: "playBtn") else {
                            return nil
                    }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else if type == "location" {
                    let locationComponent = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponent[0]),
                        let latitude = Double(locationComponent[1]) else {
                            return nil
                    }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                            size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: id,
                               sentDate: date,
                               kind: finalKind)
                
            }
            completion(.success(messageArr))
        }
    }
    /// send a message for a conversation & msg type
    public func sendMsg(to convId: String, newMessage: Message,otherUserEmail: String, name: String, completion: @escaping (Bool) -> Void) {
        // add new msg to messages
        // update sender latest msg
        // update recipient latest msg
        
        database.child("\(convId)/messages").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {
                return
            }
            guard var currentMsg = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
            case .text(let msgText):
                let extraSpaceRemoveText = msgText.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).filter{!$0.isEmpty}.joined(separator: "\n")
                message = extraSpaceRemoveText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
                break
            case .video(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMsgCollection: [String: Any] = [
                "id": newMessage.messageId ,
                "type": newMessage.kind.msgKindString,
                "content": message,
                "date": dateString,
                "senderEmail": currentEmail,
                "isRead": false,
                "name": name
            ]
            currentMsg.append(newMsgCollection)
            strongSelf.database.child("\(convId)/messages").setValue(currentMsg) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    var databaseEntryConversation = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "message": message,
                        "date": dateString,
                        "isRead": false
                    ]
                    if var currentUserConv = snapshot.value as? [[String: Any]]  {
                        // we need to create conversation entry
                        var targetConversation: [String: Any]?
                        var postion = 0
                        for conversation in currentUserConv {
                            if let currentConvId = conversation["id"] as? String, currentConvId == convId {
                                targetConversation = conversation
                                break
                            }
                            postion += 1
                        }
                        if var targetConversation = targetConversation {
                            targetConversation["latestMsg"] = updatedValue
                            currentUserConv[postion] = targetConversation
                            databaseEntryConversation = currentUserConv
                            
                        } else {
                            let newConvData: [String: Any] = [
                                "id": convId,
                                "name": name,
                                "otherUserEmail": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "latestMsg": updatedValue
                            ]
                            currentUserConv.append(newConvData)
                            databaseEntryConversation = currentUserConv
                        }
                    } else {
                        let newConvData: [String: Any] = [
                            "id": convId,
                            "name": name,
                            "otherUserEmail": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "latestMsg": updatedValue
                        ]
                        
                        databaseEntryConversation = [newConvData]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversation) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //update latestMsg
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                            var databaseEntryConversation = [[String: Any]]()
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            let updatedValue: [String: Any] = [
                                "message": message,
                                "date": dateString,
                                "isRead": false
                            ]
                            
                            if var otherUserConv = snapshot.value as? [[String: Any]]  {
                                var targetConversation: [String: Any]?
                                var postion = 0
                                for conversation in otherUserConv {
                                    if let currentConvId = conversation["id"] as? String, currentConvId == convId {
                                        targetConversation = conversation
                                        break
                                    }
                                    postion += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latestMsg"] = updatedValue
                                    otherUserConv[postion] = targetConversation
                                    databaseEntryConversation = otherUserConv
                                } else {
                                    let newConvData: [String: Any] = [
                                        "id": convId,
                                        "name": currentName,
                                        "otherUserEmail": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "latestMsg": updatedValue
                                    ]
                                    otherUserConv.append(newConvData)
                                    databaseEntryConversation = otherUserConv
                                }
                                
                            } else {
                                let newConvData: [String: Any] = [
                                    "id": convId,
                                    "name": currentName,
                                    "otherUserEmail": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "latestMsg": updatedValue
                                ]
                                
                                databaseEntryConversation = [newConvData]
                            }
                        
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversation) { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
   
    public func deleteConversation(convId: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("deleting conv with id: \(convId)")
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if var conversations = snapshot.value as? [[String: Any]] {
                var removePostion = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                        id == convId {
                        print("found the conversation to delete it")
                        break
                    }
                    removePostion += 1
                }
                conversations.remove(at: removePostion)
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("failed to delete conversation")
                        return
                    }
                    completion(true)
                    print("conversation succefully deleted")
                })
            }
        }
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["otherUserEmail"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseErrors.failedToFetch))
                    return
                }
                print("succefully get id: \(id)")
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseErrors.failedToFetch))
            return
            
        }
    }
    
}

