//
//  SignUpVC.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class SignUpVC: UIViewController {
    @IBOutlet weak var registerImgView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerBtn: UIButton!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldUI(firstNameTextField)
        textFieldUI(lastNameTextField)
        textFieldUI(emailTextField)
        textFieldUI(passwordTextField)
        registerImgView.image = UIImage(systemName: "person.circle")
        registerBtn.layer.cornerRadius = 12
        registerBtn.layer.masksToBounds = true
        registerImgView.layer.masksToBounds = true
        registerImgView.layer.cornerRadius = registerImgView.bounds.width / 2
        registerImgView.layer.borderWidth = 2
        registerImgView.layer.borderColor = UIColor.lightGray.cgColor
        
    }
    
    func textFieldUI(_ textField: UITextField) {
        textField.delegate = self
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1
    }
    
    @IBAction func registerBtnPressed(_ sender: UIButton) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        
        guard let firstName = firstNameTextField.text,
            let lastName = lastNameTextField.text,
            let email = emailTextField.text,
            let password = passwordTextField.text,
            !email.isEmpty,
            !password.isEmpty,
            !firstName.isEmpty,
            !lastName.isEmpty,
            password.count >= 6 else {
                alertUserLoginError()
                return
        }
        
        spinner.show(in: view)
        
        DatabaseManager.shared.userExists(with: email) { [weak self] exists in
            guard let strongSelf = self else {return}
            
            
            guard !exists else {
                // alert for user already Exists
                strongSelf.alertUserLoginError(message: "Email address already exists, please try another email address.")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) {(result, error) in
                guard result != nil, error == nil else {
                    print(error?.localizedDescription ?? "")
                    return
                }
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                
                let chatUser = User(firstName: firstName,
                                    lastName: lastName,
                                    email: email)
                DatabaseManager.shared.createUser(with: chatUser, completion: {success in
                    if success {
                        guard let image = strongSelf.registerImgView.image, let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = chatUser.profilePicFileName
                        StorageManager.shared.uploadProfilePic(with: data, fileName: fileName) { (result) in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profilePicUrl")
                                DispatchQueue.main.async {
                                    strongSelf.spinner.dismiss()
                                }
                                print(downloadUrl)
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                    }
                })
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    func alertUserLoginError(message: String = "Please enter all information to create a new account.") {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @IBAction func selectProfilePhotoBtnPressed(_ sender: UIButton) {
        presentPhotoActionSheet()
    }
    
}

extension SignUpVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        }
        else if textField == lastNameTextField {
            emailTextField.becomeFirstResponder()
        }
        else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            registerBtnPressed(registerBtn)
        }
        
        return true
    }
}

extension SignUpVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentCamera()
                                                
        }))
        actionSheet.addAction(UIAlertAction(title: "Chose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentPhotoPicker()
                                                
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        registerImgView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
