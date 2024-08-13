//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 11/8/24.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var photoAlbum: PhotoAlbum!
    var photos: [Photo] = []
    var fetchedResultController: NSFetchedResultsController<Photo>!
    var isDownloadingState: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Data
        fetchDataFromPersistentContainer()
        
        // Map's configs
        setCameraPosition()
        addAnnotation()
    }
    
    // MARK: - Action
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        for photo in photos {
            DataController.shared.viewContext.delete(photo)
        }
        saveContexts()
        photos = []
        collectionView.reloadData()
        getNewImageSetFromFlickr()
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isDownloadingState {
            return 12
        } else {
            return photos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TourPhotoCollectionReuseIndentifier", for: indexPath) as! CustomCollectionViewCell
        if isDownloadingState {
            cell.customImageView.image = UIImage(named: "placeholderImage")
        } else {
            let photo = photos[indexPath.row]
            cell.customImageView.image = UIImage(data: photo.rawPhoto!)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isDownloadingState else { return }
        
        DataController.shared.viewContext.delete(photos[indexPath.row])
        saveContexts()
        photos.remove(at: indexPath.row)
        collectionView.reloadData()
    }
    
    // MARK: - Core data
    
    private func fetchDataFromPersistentContainer() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        let predicate = NSPredicate(format: "photoAlbum == %@", photoAlbum)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
            guard let fetchedObjects = fetchedResultController.fetchedObjects else {
                fatalError("Unable to fetch photos")
            }
            if fetchedObjects.isEmpty {
                getNewImageSetFromFlickr()
            } else {
                photos = fetchedObjects
                collectionView.reloadData()
            }
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
            fatalError(error.localizedDescription)
        }
    }
    
    private func saveContexts() {
        do {
            try DataController.shared.viewContext.save()
        } catch {
            showAlert(title: "Error", message: "Failed to save item(s): \(error)")
            fatalError("Failed to save item(s): \(error)")
        }
    }
    
    // MARK: - Flickr API
    
    private func getNewImageSetFromFlickr() {
        toggleDownloadingState(isDownloading: true)
        FlickrAPIService.getPhotoList(latitude: photoAlbum.latitude, longitude: photoAlbum.longitude) { ressult in
            switch ressult {
            case .success(let photoList):
                FlickrAPIService.downloadPhotoFromFlickr(responseGetPhotoList: photoList) { result in
                    switch result {
                    case .success(let images):
                        var photoArray: [Photo] = []
                        for image in images {
                            let newPhoto = Photo(context: DataController.shared.viewContext)
                            newPhoto.createdDate = Date()
                            newPhoto.rawPhoto = image.jpegData(compressionQuality: 1)
                            newPhoto.photoAlbum = self.photoAlbum
                            photoArray.append(newPhoto)
                        }
                        self.saveContexts()
                        self.photos = photoArray
                        self.collectionView.reloadData()
                        break
                    case .failure(let error):
                        self.showAlert(title: "Error", message: error.localizedDescription)
                        break
                    }
                    self.toggleDownloadingState(isDownloading: false)
                }
                break
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
                self.toggleDownloadingState(isDownloading: false)
                break
            }
        }
    }
    
    private func toggleDownloadingState(isDownloading: Bool) -> Void {
        newCollectionButton.isEnabled = !isDownloading
        isDownloadingState = isDownloading
    }
    
    // MARK: - Map kit
    
    private func setCameraPosition() {
        if let cameraConfig = UserDefaults.standard.dictionary(forKey: "cameraPosition") {
            let mkMapCamera: MKMapCamera = MKMapCamera()
            mkMapCamera.centerCoordinate.latitude = photoAlbum.latitude
            mkMapCamera.centerCoordinate.longitude = photoAlbum.longitude
            mkMapCamera.centerCoordinateDistance = cameraConfig["centerCoordinateDistance"] as! Double
            mkMapCamera.heading = cameraConfig["heading"] as! Double
            mkMapCamera.pitch = cameraConfig["pitch"] as! Double
            mapView.camera = mkMapCamera
        }
    }
    
    private func addAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = photoAlbum.latitude
        annotation.coordinate.longitude = photoAlbum.longitude
        mapView.addAnnotation(annotation)
    }
}
