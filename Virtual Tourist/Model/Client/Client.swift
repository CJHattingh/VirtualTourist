//
//  Client.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2022/04/25.
//

import Foundation
import UIKit
import Combine
import CoreData

class Client {
    
    var updatedResponceData: Published<[Photo]?>.Publisher { $responseData }
    var updatedImageArray: Published<[UIImage]?>.Publisher { $imageArray }
    @Published var responseData: [Photo]? = nil
    @Published var imageArray: [UIImage]? = nil
    
    var viewController = UIViewController()
    
    var randomPage = Int.random(in: 1...10)
    
    func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> ()) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            print(String(data: data, encoding: .utf8))
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                     completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        
        return task
    }
    
    func getFlikrPhotos(searchString: String) {
        var completeURL = URLComponents(string: "https://www.flickr.com/services/rest/")
        completeURL!.queryItems = [
            URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "api_key", value: "d38bad772a759c17ffee9839360566a7"),
            URLQueryItem(name: "text", value: searchString),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "nojsoncallback", value: String(1)),
            URLQueryItem(name: "page", value: String(randomPage)),
            URLQueryItem(name: "per_page", value: String(5))
        ]
        print(searchString)
        taskForGETRequest(url: completeURL!.url!, responseType: PhotosList.self) { response, error in
            if let response = response {
                self.responseData = response.photos.photo
            } else {
                self.viewController.showFailure(title: "Could not get photos", message: error?.localizedDescription ?? "Could not find any images to download")
            }
        }
    }
    
    func getImage(photoId: String, serverId: String, secret: String, completion: @escaping (UIImage?) -> ()) -> URLSessionDataTask {
        let completeURL = URL(string: "https://live.staticflickr.com/\(serverId)/\(photoId)_\(secret)_w.jpg")
        var image: UIImage?
        let task = URLSession.shared.dataTask(with: completeURL!) { data, response, error in
            if let data = data {
                image = UIImage(data: data)
                completion(image)
            } else {
                completion(nil)
            }
        }
        task.resume()
        return task
    }
    
    func getImages(photosArray: [Photo]) {
        imageArray = []
        for photo in photosArray {
            getImage(photoId: photo.id, serverId: photo.server, secret: photo.secret) { [self]image in
                if let image = image {
                    imageArray?.append(image)
                }
            }
        }
    }
}
