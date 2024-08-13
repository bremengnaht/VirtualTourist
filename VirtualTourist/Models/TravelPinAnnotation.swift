//
//  TravelPinAnnotation.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 11/8/24.
//

import Foundation
import MapKit

class TravelPinAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var photoAlbum: PhotoAlbum
    
    init(_ photoAlbum: PhotoAlbum) {
        self.coordinate = CLLocationCoordinate2D(latitude: photoAlbum.latitude, longitude: photoAlbum.longitude)
        self.photoAlbum = photoAlbum
    }
}
