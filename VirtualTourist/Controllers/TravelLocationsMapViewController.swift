//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 6/8/24.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultController: NSFetchedResultsController<PhotoAlbum>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map's data
        fetchDataFromPersistentContainer()
        loadFetechedDataToMapView()
        
        // Map's configs
        mapView.delegate = self
        addGestureRecognizerWhenHoldOnMap()
        restoreCameraPosition()
    }
    
    // MARK: - Delegate Methods
    
    func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
        performSegue(withIdentifier: "openPhotoAlbumSegue", sender: (annotation as! TravelPinAnnotation).photoAlbum)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveCameraPosition()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openPhotoAlbumSegue" {
            let destinationController = segue.destination as! PhotoAlbumViewController
            destinationController.photoAlbum = sender as? PhotoAlbum
        }
    }
    
    // MARK: - Core Data
    
    private func fetchDataFromPersistentContainer() {
        let fetchRequest: NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func loadFetechedDataToMapView() {
        guard let fetchedObjects = fetchedResultController.fetchedObjects else { return }
        
        for photoAlbum in fetchedObjects {
            createNewAnnotationOnMap(photoAlbum)
        }
    }
    
    private func createNewPhotoAlbumInPersistentContainer(_ coordinate: CLLocationCoordinate2D) -> PhotoAlbum {
        let photoAlbum = PhotoAlbum(context: DataController.shared.viewContext)
        photoAlbum.createdDate = Date()
        photoAlbum.latitude = coordinate.latitude
        photoAlbum.longitude = coordinate.longitude
        do {
            try DataController.shared.viewContext.save()
        } catch {
            fatalError("Failed to save new item: \(error)")
        }
        return photoAlbum
    }
    
    // MARK: - Press gesture
    
    private func addGestureRecognizerWhenHoldOnMap() {
        let uILongPressGestureRecognizer = UILongPressGestureRecognizer()
        uILongPressGestureRecognizer.minimumPressDuration = 1
        uILongPressGestureRecognizer.addTarget(self, action: #selector(longPressGestureCallback(_:)))
        mapView.addGestureRecognizer(uILongPressGestureRecognizer)
    }
    
    @objc private func longPressGestureCallback(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == UILongPressGestureRecognizer.State.began else {
            return
        }
        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        let photoAlbum = createNewPhotoAlbumInPersistentContainer(coordinate)
        createNewAnnotationOnMap(photoAlbum)
        
        performSegue(withIdentifier: "openPhotoAlbumSegue", sender: photoAlbum)
    }
    
    // MARK: - Mapkit
    
    private func restoreCameraPosition() {
        if let cameraConfig = UserDefaults.standard.dictionary(forKey: "cameraPosition") {
            let mkMapCamera: MKMapCamera = MKMapCamera()
            mkMapCamera.centerCoordinate.latitude = cameraConfig["latitude"] as! Double
            mkMapCamera.centerCoordinate.longitude = cameraConfig["longitude"] as! Double
            mkMapCamera.centerCoordinateDistance = cameraConfig["centerCoordinateDistance"] as! Double
            mkMapCamera.heading = cameraConfig["heading"] as! Double
            mkMapCamera.pitch = cameraConfig["pitch"] as! Double
            mapView.camera = mkMapCamera
        } else {
            saveCameraPosition()
        }
    }
    
    private func saveCameraPosition() {
        let cameraPosition = self.mapView.camera
        UserDefaults.standard.set(["latitude": cameraPosition.centerCoordinate.latitude, "longitude": cameraPosition.centerCoordinate.longitude, "centerCoordinateDistance": cameraPosition.centerCoordinateDistance, "heading": cameraPosition.heading, "pitch": cameraPosition.pitch], forKey: "cameraPosition")
    }
    
    private func createNewAnnotationOnMap(_ photoAlbum: PhotoAlbum) {
        let annotation = TravelPinAnnotation(photoAlbum)
        mapView.addAnnotation(annotation)
    }
}
