//
//  FlickrAPIService.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 11/8/24.
//

import Foundation
import UIKit

class FlickrAPIService {
    static let A_P_I_K_E_Y = "e144e3c2811c64336e74fc6f8855f20f"
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest"
        
        case getPhotoList(Double, Double)
        case getPhoto(Int, String, String, String)
        
        var stringValue: String {
            switch self {
            case let .getPhotoList(latitude, longitude):
                return Endpoints.base + "?method=flickr.photos.search&format=json&nojsoncallback=1&api_key=\(FlickrAPIService.A_P_I_K_E_Y)&lat=\(latitude)&lon=\(longitude)"
            case let .getPhoto(farm, server, id, secret):
                return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    static func getPhotoList(latitude: Double, longitude: Double, completion: @escaping (Result<ResponseGetPhotoList, Error>) -> Void) {
        let url = Endpoints.getPhotoList(latitude, longitude).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseGetPhotoList.self, from: data!)
                completion(.success(responseObject))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    static func downloadPhotoFromFlickr(responseGetPhotoList: ResponseGetPhotoList, completion: @escaping (Result<[UIImage], Error>) -> Void) {
        let twelveShuffedPhotos: [ResponsePhoto] = Array(responseGetPhotoList.photos.photo.shuffled().prefix(12))
        let dispatchGroup = DispatchGroup()
        var downloadedImages: [UIImage] = []
        
        for photo in twelveShuffedPhotos {
            dispatchGroup.enter()
            let url = Endpoints.getPhoto(photo.farm, photo.server, photo.id, photo.secret).url
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    downloadedImages.append(image)
                } else {
                    downloadedImages.append(UIImage(named: "placeholderImage")!)
                }
                dispatchGroup.leave()
            }
            task.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(downloadedImages))
        }
    }
}
