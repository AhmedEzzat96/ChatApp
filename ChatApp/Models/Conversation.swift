
import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMsg: LatestMsg
}

struct LatestMsg {
    let date: String
    let isRead: Bool
    let message: String
}
