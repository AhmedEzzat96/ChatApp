//
//  LoginVC.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginVC: UIViewController {
    @IBOutlet weak var logninImgView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var fbLoginBtn: FBLoginButton!
    @IBOutlet weak var googleLoginBtn: GIDSignInButton!
    
    private var loginObserver: NSObjectProtocol?
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main) {[weak self] (_) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        GIDSignIn.sharedInstance()?.presentingViewController = self
        textFieldUI(emailTextField)
        textFieldUI(passwordTextField)
        loginBtn.layer.cornerRadius = 12
        loginBtn.layer.masksToBounds = true
        fbLoginBtn.delegate = self
        fbLoginBtn.permissions = ["email", "public_profile"]
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func textFieldUI(_ textField: UITextField) {
        textField.delegate = self
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1
    }
    
    @IBAction func loginBtnPressed(_ sender: UIButton) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text, let password = passwordTextField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        
        spinner.show(in: view)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) {[weak self] (authResult, error) in
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataForUser(with: safeEmail) { (result) in
                switch result {
                    
                case .success(let data):
                    guard let userData = data as? [String: Any],
                        let firstName = userData["firstName"] as? String,
                        let lastName = userData["lastName"] as? String
                        else {
                            return
                    }
                    UserDefaults.standard.set(("\(firstName) \(lastName)"), forKey: "name")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            UserDefaults.standard.set(email, forKey: "email")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            print("Logged in user: \(user)")
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @IBAction func registerBtnPressed(_ sender: UIBarButtonItem) {
        let signupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpVC") as! SignUpVC
        signupVC.title = "Create Account"
        self.navigationController?.pushViewController(signupVC, animated: true)
    }
    
}
extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginBtnPressed(loginBtn)
        }
        return true
    }
}

extension LoginVC: LoginButtonDelegate {
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("user failed to login with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":
                                                            "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start { (connection, results, error) in
            guard let results = results as? [String: Any], error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            guard let firstName = results["first_name"] as? String,
                let lastName = results["last_name"] as? String,
                let email = results["email"] as? String,
                let picture = results["picture"] as? [String: Any],
                let picData = picture["data"] as? [String: Any],
                let picUrl = picData["url"] as? String else {return}
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            DatabaseManager.shared.userExists(with: email) { (exists) in
                if !exists {
                    let chatUser = User(firstName: firstName,
                                        lastName: lastName,
                                        email: email)
                    DatabaseManager.shared.createUser(with: chatUser, completion: {success in
                        if success {
                            guard let url = URL(string: picUrl) else {
                                print("Failed to get data from facebook")
                                return
                            }
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {return}
                                print("data is uploading from facebook ...")
                                let fileName = chatUser.profilePicFileName
                                StorageManager.shared.uploadProfilePic(with: data, fileName: fileName) { (result) in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profilePicUrl")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print(error.localizedDescription)
                                    }
                                }
                            }.resume()
                        }
                    })
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
                guard let strongSelf = self else { return }
                guard authResult != nil, error == nil else {
                    print("failed to logged in")
                    return
                }
                print("Succefully logged in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // not needed for use
    }
    
    
}
