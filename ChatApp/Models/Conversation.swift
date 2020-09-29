
import Foundation

struct Conversation {
    let id: String
    let name: String
    let latestMsg: LatestMsg
    let otherUserEmail: String
}

struct LatestMsg {
    let date: String
    let isRead: Bool
    let message: String
}
