
import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noConversationLabel: UILabel!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversationArr = [Conversation]()
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTabelView()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConv()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        validateAuth()
        startListeningForConv()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            let loginNav = UINavigationController(rootViewController: loginVC)
            loginNav.modalPresentationStyle = .fullScreen
            present(loginNav, animated: false)
        }
    }
    
    private func setUpTabelView() {
        tableView.register(UINib(nibName: "ConversationCell", bundle: nil), forCellReuseIdentifier: "ConversationCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func startListeningForConv() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("starting conversation fetch...")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConv(for: safeEmail) { [weak self] (result) in
            switch result {
            case .success(let conversations):
                print("successfully got conversation")
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                    return
                }
                self?.tableView.isHidden = false
                self?.noConversationLabel.isHidden = true
                self?.conversationArr = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationLabel.isHidden = false
                print("failed to get conversations \(error)")
            }
        }
    }

    @IBAction func composeBtnPressed(_ sender: UIBarButtonItem) {
        guard let newConversationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewConversationVC") as? NewConversationVC else {
            return
        }
        
        newConversationVC.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            print("conversationArr: \(strongSelf.conversationArr)")
            let currentConv = strongSelf.conversationArr
            
            if let targetConv = currentConv.first(where: { $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email) }) {
                print("targetConv: \(targetConv)")
                let chatVC = ChatVC(with: targetConv.otherUserEmail, id: targetConv.id)
                chatVC.isNewConv = false
                chatVC.title = targetConv.name
                chatVC.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(chatVC, animated: true)
            } else {
                print("resulllllllt: \(result)")
                strongSelf.createNewConv(result: result)
            }
        }
        let newConvNav = UINavigationController(rootViewController: newConversationVC)
        newConvNav.modalPresentationStyle = .fullScreen
        present(newConvNav, animated: true)
    }
    
    private func createNewConv(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        // check in datbase if conversation with these two users exists
        // if it does, reuse conversation id
        // otherwise use existing code
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                let vc = ChatVC(with: email, id: conversationId)
                vc.isNewConv = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatVC(with: email, id: nil)
                vc.isNewConv = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
}

extension ConversationsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as? ConversationCell else {
            return UITableViewCell()
        }
        cell.configCell(conversation: conversationArr[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openConversation(conversationArr[indexPath.row])
    }
    
    private func openConversation(_ conversation: Conversation) {
        let vc = ChatVC(with: conversation.otherUserEmail, id: conversation.id)
        vc.title = conversation.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let convId = conversationArr[indexPath.row].id
            
            tableView.beginUpdates()
            self.conversationArr.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(convId: convId) { [weak self] (success) in
                if !success {
                    print("failed to delete")
                    let alert = UIAlertController(title: "Error!", message: "Failed To Delete Message", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self?.present(alert, animated: true)
                }
                
                tableView.endUpdates()
            }
        }
        
    }
}

