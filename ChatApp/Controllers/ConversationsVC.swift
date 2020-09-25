//
//  ViewController.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noConversationLabel: UILabel!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateAuth()
        setUpTabelView()
        getConversation()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            let loginNav = UINavigationController(rootViewController: loginVC)
            loginNav.modalPresentationStyle = .fullScreen
            self.present(loginNav, animated: false)
        }
    }
    
    private func setUpTabelView() {
        tableView.register(UINib(nibName: "ConversationCell", bundle: nil), forCellReuseIdentifier: "ConversationCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func getConversation() {
        tableView.isHidden = false
    }

    @IBAction func composeBtnPressed(_ sender: UIBarButtonItem) {
        let newConversationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewConversationVC") as! NewConversationVC
        let newConvNav = UINavigationController(rootViewController: newConversationVC)
        newConvNav.modalPresentationStyle = .fullScreen
        self.present(newConvNav, animated: true)
    }
    
}

extension ConversationsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as? ConversationCell else {
            return UITableViewCell()
        }
        cell.helloTextField.text = "Ahmed Ezzat"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
        chatVC.title = "Ahmed Ezzat"
        chatVC.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    
}

