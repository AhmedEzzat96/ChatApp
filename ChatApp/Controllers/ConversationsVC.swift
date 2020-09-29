
import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noConversationLabel: UILabel!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversationArr = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateAuth()
        setUpTabelView()
        getConversation()
        startListeningForConv()
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
        newConversationVC.completion = { [weak self] result in
            self?.createNewConv(result: result)
        }
        let newConvNav = UINavigationController(rootViewController: newConversationVC)
        newConvNav.modalPresentationStyle = .fullScreen
        self.present(newConvNav, animated: true)
    }
    
    private func startListeningForConv() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConv(for: safeEmail) { [weak self] (result) in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversationArr = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func createNewConv(result: [String: String]) {
        guard let name = result["name"],
            let email = result["safeEmail"] else {
                return
        }
        let chatVC = ChatVC(with: email, id: nil)
        chatVC.isNewConv = true
        chatVC.title = name
        chatVC.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(chatVC, animated: true)
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
        let chatVC = ChatVC(with: conversationArr[indexPath.row].otherUserEmail, id: conversationArr[indexPath.row].id)
        chatVC.title = conversationArr[indexPath.row].name
        chatVC.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

