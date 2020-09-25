//
//  User.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 9/8/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import Foundation

struct User {
    let firstName: String!
    let lastName: String!
    let email: String!
    
    var profilePicFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
