//
//  photoListResponse.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2022/05/10.
//

import Foundation

struct PhotosList: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let photo: [Photo]
    let page: Int
    let pages: Int
}

struct Photo: Codable {
    let id: String
    let secret: String
    let server: String
}
