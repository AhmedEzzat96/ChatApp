//
//  LoginVC.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginVC: UIViewController {
    @IBOutlet weak var logninImgView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldUI(emailTextField)
        textFieldUI(passwordTextField)
        loginBtn.layer.cornerRadius = 12
        loginBtn.layer.masksToBounds = true
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
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) {[weak self] (authResult, error) in
            guard let strongSelf = self else {return}
            guard let result = authResult, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            let user = result.user
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
