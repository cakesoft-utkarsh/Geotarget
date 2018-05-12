//
//  Created by Utkarsh Phirke
//  Copyright © 2018 CakeSoft. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var monitoredRegions: Dictionary<String, Date> = [:]
    var lastLocation: CLLocation?
    var delegate: CLLocationManagerDelegate?
    let file = "LocationUpdateLog.txt"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup locationManager
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        // setup Background location, with significant change in location
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // setup mapView
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // setup test data
        setupData()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
            // authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            fileLog(logString: "Location services were previously denied. Please enable location services for this app in Settings.")
        }
            // we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func setupData() {
        // check if can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            // region data
            let title = "A1 Furniture Shop"
            let coordinate = CLLocationCoordinate2DMake(37.703026, -121.759735)
            let regionRadius = 300.0
            
            // setup region
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude), radius: regionRadius, identifier: title)
            locationManager.startMonitoring(for: region)
            
            // setup annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate;
            annotation.title = "\(title)";
            mapView.addAnnotation(annotation)
            
            // setup circle
            let circle = MKCircle(center: coordinate, radius: regionRadius)
            mapView.add(circle)
        }
        else {
            print("System can't track regions")
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("enter \(region.identifier)")
        fileLog(logString: "Did Enter Region \(region.identifier)"  )
        monitoredRegions[region.identifier] = Date()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("exit \(region.identifier)")
        fileLog(logString: "Did Exit Region \(region.identifier)" )
        monitoredRegions.removeValue(forKey: region.identifier)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateRegionsWithLocation(locations[0])
        guard let location = locations.last else {
            return
        }
        
        // singleton for get last location
        self.lastLocation = location
        
        // Log Location coordinates
        print(location.coordinate.latitude.description + ", " + location.coordinate.longitude.description)
        let str = "Location Update " + location.coordinate.latitude.description + ", " + location.coordinate.longitude.description
        fileLog(logString: str)
    }
    
    // MARK: - Comples business logic
    
    func updateRegionsWithLocation(_ location: CLLocation) {
        
        let regionMaxVisiting = 10.0
        var regionsToDelete: [String] = []
        
        for regionIdentifier in monitoredRegions.keys {
            if Date().timeIntervalSince(monitoredRegions[regionIdentifier]!) > regionMaxVisiting {
                fileLog(logString: "Thanks for spending 10 Sec here")
                
                regionsToDelete.append(regionIdentifier)
            }
        }
        
        for regionIdentifier in regionsToDelete {
            monitoredRegions.removeValue(forKey: regionIdentifier)
        }
    }
    
    // MARK: - Helpers
    private func fileLog(logString: String){

        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        var text = dateString + logString + "\n"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            //reading
            do {
                let text2 = try String(contentsOf: fileURL, encoding: .utf8)
                print(text2)
                text = text + text2
            }
            catch {/* error handling here */}
            
            //writing
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {/* error handling here */}
        }
    }
}

