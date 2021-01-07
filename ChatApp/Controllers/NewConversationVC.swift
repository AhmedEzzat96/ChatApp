//
//  NewConversationVC.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationVC: UIViewController {
    
    public var completion: ((SearchResult) -> Void)?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    private let spinner = JGProgressHUD(style: .dark)
    private var results = [SearchResult]()
    private var users = [[String: String]]()
    
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search..."
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .cancel,
                                                              target: self,
                                                              action: #selector(dismissView)),
                                              animated: true)
        searchBar.becomeFirstResponder()
        
    }
    
    private func configTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "NewConversationCell", bundle: nil), forCellReuseIdentifier: "NewConversationCell")
    }
    
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension NewConversationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewConversationCell", for: indexPath) as? NewConversationCell else {
            return UITableViewCell()
        }
        cell.configCell(conversation: results[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension NewConversationVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        
        findUsers(text: text)
    }
    
    func findUsers(text: String) {
        // check if array have firebase results
        if hasFetched {
            // if it does: filter
            filterUsers(with: text)
            
        } else {
            // if not, fetch then filter
            DatabaseManager.shared.getUsers { [weak self] (result) in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: text)
                case.failure(let error):
                    print("failed to get users \(error)")
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }

        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        print(safeEmail)
        spinner.dismiss()
        
        let results: [SearchResult] = users.filter({
            guard let email = $0["safeEmail"], email != safeEmail else {
                return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            
            guard let email = $0["safeEmail"],
                let name = $0["name"] else {
                    return nil
            }
            return SearchResult(name: name, email: email)
        })
        print(results)
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
