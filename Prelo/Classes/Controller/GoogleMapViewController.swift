//
//  GoogleMapViewController.swift
//  Prelo
//
//  Created by Djuned on 4/4/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces

typealias BlockMapPickerChoosed = ([String: String]) -> ()

class GoogleMapViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // You don't need to modify the default init(nibName:bundle:) method.
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var vwDetails: UIView!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var vwBackgroundSearchResult: UIView!
    @IBOutlet weak var searchResultTableView: UITableView!
    @IBOutlet weak var consBottomSearchResult: NSLayoutConstraint!
    
    @IBOutlet weak var btnMarkerTeks: UIButton!
    
    var locationManager: CLLocationManager!
    @IBOutlet var mapView: GMSMapView!
//    var marker: GMSMarker!
    var selectedLocation: CLLocationCoordinate2D!
    
    var placesClient: GMSPlacesClient!
    
    var searchActive : Bool = false
    //var data = ["San Francisco","New York","San Jose","Chicago","Los Angeles","Austin","Seattle"]
    var filtered: [String] = []
    var placeId: [String] = []
    
    let mapZoomLevel: Float = 15.0
    
    // Delegate
    var blockDone : BlockMapPickerChoosed?
    
    //var startTime : TimeInterval! = nil
    var SwiftTimer = Timer()
    var SwiftCounter: Float = 0.0
    
    let epsilon = 0.00005
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnMarkerTeks.backgroundColor = UIColor.colorWithColor(UIColor.gray, alpha: 0.7)
        placesClient = GMSPlacesClient.shared()
        
        // search bar
        self.vwBackgroundSearchResult.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        // search result
        searchBar.delegate = self
        
        /* Setup delegates */
        searchResultTableView.dataSource = self
        searchResultTableView.delegate = self
        searchResultTableView.tableFooterView = UIView()
        
        searchResultTableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        searchResultTableView.backgroundColor = UIColor.clear
        
        // define location default
        selectedLocation = CLLocationCoordinate2D(latitude: -0.7893/*-33.86*/, longitude: 113.9213/*151.20*/)
        
//        let panoView = GMSPanoramaView(frame: .zero)
//        self.view = panoView
//        
//        panoView.moveNearCoordinate(selectedLocation)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        let camera = GMSCameraPosition.camera(withTarget: selectedLocation, zoom: mapZoomLevel)
        
        //mapView.delegate = self
        
//        marker = GMSMarker()
//        marker.position = selectedLocation
////        marker.title = "Your Current Location"
//        marker.map = mapView
//        marker.isDraggable = true
        
        mapView.camera = camera
        mapView.mapType = .normal
        mapView.isMyLocationEnabled = true
        
        lbAddress.text = ""
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GoogleMapViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        vwBackgroundSearchResult.addGestureRecognizer(tapGesture)
        
        self.title = "Pilih Lokasi"
        
        // swipe gesture for carbon (pop view)
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.consBottomSearchResult.constant = r.height
            } else {
                self.consBottomSearchResult.constant = 120
            }
        }, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func placeAutocomplete(_ query: String) {
        if (query.length < 3) {
            return
        }
        
//        if ((Date().timeIntervalSinceReferenceDate - self.startTime) < 1.0) { // 1 detik
//            return
//        }
        
//        Constant.showDialog("REQUEST", message: "call")
        
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        filter.country = "ID" // ISO 3166-1 Alpha-2 country code
        placesClient.autocompleteQuery(query, bounds: nil, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                //Constant.showDialog("Peringatan", message: "Terdapat kesalahan saat mengakses peta \(error)")
                print("Autocomplete error \(error)")
                return
            }
            if let results = results {
                self.filtered = []
                self.placeId = []
                for result in results {
                    self.filtered.append(result.attributedFullText.string)
                    print("Result \(result.attributedFullText) with placeID \(String(describing: result.placeID))")
                    
                    self.placeId.append(result.placeID ?? "")
                }
                
                if(self.filtered.count == 0){
                    self.searchActive = false;
                } else {
                    self.searchActive = true;
                }
                self.searchResultTableView.reloadData()
            }
        })
    }
    
    func getCoordinate(_ placeId: String) {
        if placeId == "" {
            Constant.showDialog("Peringatan", message: "Lokasi tidak ditemukan")
            return
        }
        
        placesClient.lookUpPlaceID(placeId, callback: {(result, error) -> Void in
            if let error = error {
                print("Autocomplete error \(error)")
                return
            }
//            Constant.showDialog("LongLat", message: String(describing: result?.coordinate))
            
            //self.selectedLocation = result?.coordinate
            
            self.mapView.camera = GMSCameraPosition(target: (result?.coordinate)!, zoom: self.mapZoomLevel, bearing: 0, viewingAngle: 0)
//            self.marker.position = self.selectedLocation
            
            //self.getAddressFromGeocodeCoordinate(self.selectedLocation)
        })
    }
    
    // MARK: - Button Action
    @IBAction func btnMarkerPressed(_ sender: Any) {
        if selectedLocation != nil && (fabs(selectedLocation.latitude - mapView.camera.target.latitude) <= epsilon && fabs(selectedLocation.longitude - mapView.camera.target.longitude) <= epsilon) {
            print("same location")
        } else {
            self.getAddressFromGeocodeCoordinate(mapView.camera.target)
        }
            
        btnMarkerTeks.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.btnMarkerTeks.transform = .identity
            },
                       completion: nil)
    }
    
    @IBAction func btnChooseLOcationPressed(_ sender: Any) {
        Constant.showDialog("Lokasi kamu", message: lbAddress.text!)
        let res = [
            "address": self.lbAddress.text!,
            "latitude": "\(self.selectedLocation.latitude)",
            "longitude": "\(self.selectedLocation.longitude)"
        ]
        self.blockDone!(res)
        
        //Constant.showDialog("Test", message: res.debugDescription)
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - SearchBar Delegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
        
        self.vwBackgroundSearchResult.isHidden = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        self.vwBackgroundSearchResult.isHidden = true
        self.searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        
        self.fireScheduler()
        
        //self.placeAutocomplete(self.searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.fireScheduler()
        
        //self.startTime = Date().timeIntervalSinceReferenceDate
        //self.placeAutocomplete(self.searchBar.text!)
        /*
        filtered = data.filter({ (text) -> Bool in
            let tmp: NSString = text as NSString
            let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
            return range.location != NSNotFound
        })
        if(filtered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.searchResultTableView.reloadData()
         */
    }
    
    // MARK: - TableView Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = searchResultTableView.dequeueReusableCell(withIdentifier: "SearchResultCell") as! SearchResultCell;
        cell.textLabel?.text = filtered[indexPath.row]
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        Constant.showDialog("kena", message: "!!!")
        
        self.vwBackgroundSearchResult.isHidden = true
        self.searchBar.resignFirstResponder()
        self.searchBar.text = searchResultTableView.cellForRow(at: indexPath)?.textLabel?.text
        
        self.getCoordinate(placeId[(indexPath as IndexPath).row])
 
        //self.lbAddress.text = self.searchBar.text
    }
    
    // MARK: - Keyboard
    func hideKeyboard() {
        self.vwBackgroundSearchResult.isHidden = true
        self.searchBar.resignFirstResponder()
    }
    
    // MARK: - Scheduler
    func fireScheduler() {
        SwiftCounter = 0.0
        SwiftTimer.invalidate()
        SwiftTimer = Timer.scheduledTimer(timeInterval: 0.01, target:self, selector: #selector(GoogleMapViewController.updateCounter), userInfo: nil, repeats: true)
    }
    
    func updateCounter() {
        SwiftCounter += 0.01
        
        if SwiftCounter >= 1.0 {
            self.placeAutocomplete(self.searchBar.text!)
            SwiftTimer.invalidate()
        }
    }
}

// MARK: - CLLocationManagerDelegate
//1
extension GoogleMapViewController: CLLocationManagerDelegate {
    // 2
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 3
        if status == .authorizedWhenInUse {
            
            // 4
            locationManager.startUpdatingLocation()
            
            //5
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    // 6
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            
            // 7
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: mapZoomLevel, bearing: 0, viewingAngle: 0)
//            marker.position = location.coordinate
            
            self.getAddressFromGeocodeCoordinate(location.coordinate)
            
            // 8
            locationManager.stopUpdatingLocation()
        }
    }
    
    // update label location & longlat
    func getAddressFromGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { response , error in
            if response == nil || error != nil {
                Constant.showDialog("Peringatan", message: "Lokasi tidak ditemukan")
                return
            }
            
            //Add this line
            if let address = response!.firstResult() {
                let lines = address.lines! as [String]
                print(lines)
                
                var detailAddress = ""
                for i in 0...lines.count-1 {
                    if lines[i] == "" {
                        continue
                    }
                    
                    detailAddress += lines[i]
                    if i != lines.count-1 {
                        detailAddress += ", "
                    }
                }
                
                self.lbAddress.text = detailAddress
                
                self.selectedLocation = coordinate
            }
        }
    }
}
/*
extension GoogleMapViewController: GMSMapViewDelegate {
//    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
//        marker.position = mapView.camera.target
//        
//        return true
//    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        marker.position = coordinate
        
        self.getAddressFromGeocodeCoordinate(coordinate)
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        self.getAddressFromGeocodeCoordinate(marker.position)
    }
}
*/
class SearchResultCell: UITableViewCell {
    
}
