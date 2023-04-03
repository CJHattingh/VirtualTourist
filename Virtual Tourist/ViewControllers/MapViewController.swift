//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2022/02/21.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController!
    var pins: [CoreDataPin] = []
    var selectedAnnotation: MKAnnotation? = nil
    var pinTitle: String = ""
    var titlePin: String = ""
    var pin = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongTapGesture(gesture:)))
        
        self.mapView.addGestureRecognizer(longTapGesture)
        
        let fetchrequest:NSFetchRequest<CoreDataPin> = NSFetchRequest(entityName: "CoreDataPin")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: false)
        fetchrequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchrequest) {
            pins = result
            
            var annotations = [MKPointAnnotation]()
            
            for dictionary in result {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: dictionary.lattitude, longitude: dictionary.longitude)
                annotation.title = dictionary.title
                annotations.append(annotation)
            }
            self.mapView.addAnnotations(annotations)
        }
    }
    
    @objc func handleLongTapGesture(gesture: UILongPressGestureRecognizer) {
        if gesture.state != UIGestureRecognizer.State.ended{
            let touchLocation = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            pin.coordinate = coordinate
            pin.title = " "
            mapView.addAnnotation(pin)
            
            //Reverse geocode the location to an address that can be used for a title
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { [self] (placemarks, error) in
                self.processResponse(withPlacemarks: placemarks,coordinate: coordinate, error: error)
            }
        }
        if gesture.state != UIGestureRecognizer.State.began{
            return
        }
    }
    
    func processResponse(withPlacemarks placemarks: [CLPlacemark]?, coordinate: CLLocationCoordinate2D, error: Error?) {
        if let error = error {
            print("Unable to Reverse Geocode Location (\(error))")
        } else {
            if let placemarks = placemarks, let placemark = placemarks.first {
                pinTitle = placemark.locality ?? ""
                titlePin = pinTitle
                pin.title = pinTitle
                self.addPin(title: self.titlePin, latitude: coordinate.latitude, longitude: coordinate.longitude)
            } else {
                print("No Matching Addresses Found")
            }
        }
    }
    
    func addPin(title: String, latitude: Double, longitude: Double) {
        let pin = CoreDataPin(context: dataController.viewContext)
        pin.longitude = longitude
        pin.lattitude = latitude
        pin.title = title
        try? dataController.viewContext.save()
        pins.append(pin)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CollectionViewController {
            destination.selectedPin = selectedAnnotation
            destination.dataController = dataController
        }
    }
    
    func mapView(_ mapview: MKMapView, didSelect view: MKAnnotationView) {
        selectedAnnotation = view.annotation
        performSegue(withIdentifier: "ShowCollectionView", sender: self)
        mapView.deselectAnnotation(view.annotation, animated: true)
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
}

extension CLPlacemark {

    var compactAddress: String? {
        if let name = name {
            var result = name

            if let city = locality {
                result += ", \(city)"
            }
            if let country = country {
                result += ", \(country)"
            }
            return result
        }
        return nil
    }
}
