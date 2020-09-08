import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()

}

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)) {
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
        })
        completion(true)
    }
    
    /// insert user in database
    public func createUser(with user: User) {
        database.child(user.email).setValue([
            "firstName": user.firstName,
            "lastName:": user.lastName
        ])
    }
}
