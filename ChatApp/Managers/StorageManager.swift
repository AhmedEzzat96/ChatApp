

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias uploadPicCompletion = (Result<String, Error>) -> Void
    
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping uploadPicCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {metadata, error in
            guard error == nil else {
                print("Failed to upload data to firebase pic")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("downloaded url is: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadUrl(with path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let refrence = storage.child(path)
        refrence.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        }
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    /// upload chat send image
    public func uploadMsgPhoto(with data: Data, fileName: String, completion: @escaping uploadPicCompletion) {
        storage.child("messages_images/\(fileName)").putData(data, metadata: nil, completion: {metadata, error in
            guard error == nil else {
                print("Failed to upload data to firebase pic")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("messages_images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("downloaded url is: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
}
