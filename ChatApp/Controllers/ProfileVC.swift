//
//  ProfileVC.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

class ProfileVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "LogOutProfileCell", bundle: nil), forCellReuseIdentifier: "LogOutProfileCell")
        tableView.register(UINib(nibName: "UserNameProfileCell", bundle: nil), forCellReuseIdentifier: "UserNameProfileCell")
        tableView.register(UINib(nibName: "UserEmailProfileCell", bundle: nil), forCellReuseIdentifier: "UserEmailProfileCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        tableView.tableHeaderView = createTableViewHeader()
    }
    
    func createTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        print(safeEmail)
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.frame.width,
                                        height: 200))
        headerView.backgroundColor = .systemBackground
        let imageView = UIImageView(frame: CGRect(x: (view.frame.width-150) / 2,
                                                  y: 50,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.cornerRadius = imageView.layer.frame.width/2
        imageView.layer.masksToBounds = true
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(with: path) { (reuslt) in
            switch reuslt {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        return headerView
    }

}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let userNameProfileCell = tableView.dequeueReusableCell(withIdentifier: "UserNameProfileCell", for: indexPath) as? UserNameProfileCell else {
                return UITableViewCell()
            }
            return userNameProfileCell
        } else if indexPath.row == 1 {
            guard let userEmailProfileCell = tableView.dequeueReusableCell(withIdentifier: "UserEmailProfileCell", for: indexPath) as? UserEmailProfileCell else {
                return UITableViewCell()
            }
            return userEmailProfileCell
        } else {
            guard let logOutProfileCell = tableView.dequeueReusableCell(withIdentifier: "LogOutProfileCell", for: indexPath) as? LogOutProfileCell else {
                return UITableViewCell()
            }
            return logOutProfileCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 2 {
            let actionSheet = UIAlertController(title: "Are you sure to logout?", message: "", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: {[weak self] (_) in
                guard let strongSelf = self else {
                    return
                }
                
                GIDSignIn.sharedInstance()?.signOut()
                FBSDKLoginKit.LoginManager().logOut()
                
                UserDefaults.standard.set(nil, forKey: "email")
                UserDefaults.standard.set(nil, forKey: "name")
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                    let loginNav = UINavigationController(rootViewController: loginVC)
                    loginNav.modalPresentationStyle = .fullScreen
                    strongSelf.tabBarController?.present(loginNav, animated: true) {
                        strongSelf.tabBarController?.selectedIndex = 0
                    }
                    
                }
                catch {
                    print("Failed to logout")
                }
                
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true)
        }
        
    }
    
    
}
