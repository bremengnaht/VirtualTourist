//
//  ResponseGetPhotoList.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 11/8/24.
//

import Foundation

struct ResponseGetPhotoList: Codable {
    let photos: ResponsePhotos
}

struct ResponsePhotos: Codable {
    let photo: [ResponsePhoto]
}

struct ResponsePhoto: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
}
