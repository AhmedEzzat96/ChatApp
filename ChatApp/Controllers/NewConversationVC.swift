//
//  NewConversationVC.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 8/28/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import UIKit

class NewConversationVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    private var searchBar: UISearchBar {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search..."
        return searchBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
        searchBar.delegate = self
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .cancel,
                                                              target: self,
                                                              action: #selector(dismissView)),
                                              animated: true)
        self.navigationController?.navigationBar.topItem?.titleView = searchBar
        searchBar.becomeFirstResponder()
        
    }
    
    private func configTableView() {
        tableView.isHidden = true
        tableView.register(UINib(nibName: "NewConversationCell", bundle: nil), forCellReuseIdentifier: "NewConversationCell")
    }
    
    @objc private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension NewConversationVC: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
