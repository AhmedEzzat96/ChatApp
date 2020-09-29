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
    
    public var completion: (([String: String]) -> (Void))?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    private let spinner = JGProgressHUD(style: .dark)
    private var usersArr = [[String: String]]()
    private var resultsArr = [[String: String]]()
    
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search..."
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .cancel,
                                                              target: self,
                                                              action: #selector(dismissView)),
                                              animated: true)
        self.navigationController?.navigationBar.topItem?.titleView = searchBar
        self.searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
    }
    
    private func configTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        tableView.register(UINib(nibName: "NewConversationCell", bundle: nil), forCellReuseIdentifier: "NewConversationCell")
    }
    
    @objc private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension NewConversationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewConversationCell", for: indexPath) as? NewConversationCell else {
            return UITableViewCell()
        }
        cell.userNameLabel.text = resultsArr[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUser = resultsArr[indexPath.row]
        self.dismiss(animated: true) { [weak self] in
            self?.completion?(targetUser)
        }
    }
    
}

extension NewConversationVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        self.resultsArr.removeAll()
        spinner.show(in: view)
        self.findUsers(text: text)
    }
    
    func findUsers(text: String) {
        // check if array have firebase results
        if hasFetched {
            // if it does: filter
            self.filterUsers(with: text)
            
        } else {
            // if not, fetch then filter
            DatabaseManager.shared.getUsers { [weak self] (result) in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.usersArr = usersCollection
                    self?.filterUsers(with: text)
                case.failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        guard hasFetched else {
            return
        }
        self.spinner.dismiss()
        
        let results: [[String: String]] = self.usersArr.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.resultsArr = results
        updateUI()
    }
    
    func updateUI() {
        if resultsArr.isEmpty {
            self.noResultLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
