//
//  CollectionViewController.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2022/02/23.
//

import Foundation
import CoreData
import UIKit
import MapKit
import Combine

class CollectionViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        let fetchRequest:NSFetchRequest<CoreDataPhoto> = CoreDataPhoto.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.predicate = predicate

        if let result = try? self.dataController.viewContext.fetch(fetchRequest) {
            self.coreDataPhotos = result
        }
        dataController.deleteImages(images: self.coreDataPhotos, pin: self.pin!)
        //collectionView.dataSource = nil
        //collectionView.dataSource = self
        //collectionView.delegate = self
        self.response = nil
        self.images = []
        self.coreDataPhotos = []

        //cancellableResponse = nil
        //cancellableImageArray = nil
        updateUI()
        //newCollectionPressedArray = true
        //newCollectionPressedResponse = true
        downloadImages()
    }
    
    var newCollectionPressedArray: Bool = false
    var newCollectionPressedResponse: Bool = false
    var selectedPin: MKAnnotation? = nil
    var pinTitle: String? = ""
    var dataController: DataController!
    var coreDataPhotos: [CoreDataPhoto] = [] //Core data class
    var images: [UIImage]? = []//Downloaded images
    var response: [Photo]? = nil//Image data from API
    var pin: CoreDataPin? = nil
    
    let client = Client()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.mapView.addAnnotation(selectedPin!) // force unwrap!!
        if let selectedPin = selectedPin {
            self.mapView.setCenter(selectedPin.coordinate, animated: true)
            let coordinate = selectedPin.coordinate
            let span = MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
            pinTitle = selectedPin.title!
        }
        
        let flowLayout = UICollectionViewFlowLayout()
        
        // Set up FlowLayout
        let space:CGFloat = 2.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        collectionView.collectionViewLayout = flowLayout

        downloadImages()
    }
        
    private var cancellableResponse: AnyCancellable?
    private var cancellableImageArray: AnyCancellable?
    func observeReloadImageData(completion: @escaping () -> Void) {
        if newCollectionPressedResponse == false {
            cancellableResponse = client.updatedResponceData.sink(receiveValue: { [weak self] response in
                self?.response = response
                completion()
            })
        }
    }
    
    func observeReloadImageArray(completion: @escaping () -> Void) {
        cancellableImageArray = client.updatedImageArray.sink(receiveValue: { [weak self] images in
            self?.images = []
            self?.images = images
            completion()
        })
    }

    func addImageToCoreData (image: UIImage) throws {
        let context = dataController.viewContext
        let photo = CoreDataPhoto(context: context)
        
        photo.image = image.jpegData(compressionQuality: 1.0)
        photo.pin = pin
        dataController.saveContext()
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.canShowCallout = false
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if coreDataPhotos == [] {
            if self.response != nil {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                return self.response!.count
            } else {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                return 0
            }
        } else {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            return coreDataPhotos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        if (images != nil && images != []) && indexPath.row < images!.count {
            let photo = images![indexPath.row]
            cell.imageView.image = photo
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
        } else {
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = coreDataPhotos[indexPath.row]
        dataController.viewContext.delete(photoToDelete)
        dataController.saveContext()
        images!.remove(at: indexPath.row)
        coreDataPhotos.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        self.collectionView.reloadData()
    }
    
    func downloadImages() {
        let pinFetchRequest:NSFetchRequest<CoreDataPin> = CoreDataPin.fetchRequest()
        let pinPredicate = NSPredicate(format: "title == %@", selectedPin!.title!!)
        pinFetchRequest.predicate = pinPredicate
        
        if let result = try? dataController.viewContext.fetch(pinFetchRequest) {
            pin = result[0]
        }
        
        let fetchRequest:NSFetchRequest<CoreDataPhoto> = CoreDataPhoto.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin!)
        fetchRequest.predicate = predicate
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            coreDataPhotos = result
        }
        
        if coreDataPhotos == [] {
            observeReloadImageData {
                //if self.newCollectionPressedResponse == true {
                //    self.response = nil
                //}
                if self.response == nil {
                    self.client.getFlikrPhotos(searchString: (self.pinTitle ?? " ")!)
                    //self.newCollectionPressedResponse = false
                } else {
                    self.observeReloadImageArray {
                        //if self.newCollectionPressedArray == true {
                        //    self.images = nil
                        //}
                        if self.images == nil {
                            self.client.getImages(photosArray: self.response!)
                            //self.newCollectionPressedArray = false
                        }
                        self.updateUI()
                        // save images to core data
                        let count = self.images!.count
                        if count > 0{
                            do {
                                try self.addImageToCoreData(image: self.images![count-1])
                            } catch {
                                self.showFailure(title: "Could not save images", message: "Could not save images")
                            }
                        }
                    }
                }
            }
        } else {
            if images == nil {
                images = []
            }
            // show images from core data
            for photo in self.coreDataPhotos {
                if let image = UIImage(data: photo.image!) {
                    self.images!.append(image)
                }
            }
            updateUI()
        }
        //|| newCollectionPressedArray == false
        if images == nil  ||  images == []{
            observeReloadImageArray {
                self.updateUI()
            }
        }
        updateUI()
        //newCollectionPressed = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingToParent {
//            images = nil
//            response = nil
//            cancellableResponse = nil
//            cancellableImageArray = nil
//            coreDataPhotos = []
        }
    }
}
