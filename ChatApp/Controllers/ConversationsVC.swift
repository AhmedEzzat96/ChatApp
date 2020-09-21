//
//  ViewController.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import FirebaseAuth

class ConversationsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateAuth()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            let loginNav = UINavigationController(rootViewController: loginVC)
            loginNav.modalPresentationStyle = .fullScreen
            self.present(loginNav, animated: false)
        }
    }


}

