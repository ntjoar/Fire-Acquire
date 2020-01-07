//
//  ViewController.swift
//  MapKitTutorial
//
//  Created by Nathan on 3/30/19.
//  Copyright © 2019 Nathan Tjoar. All rights reserved.
//
import UIKit
import MapKit
import Foundation
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    // Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Circles
    
    var regions: [String]!
    var latitudes: [Double]!
    var longitudes: [Double]!
    
    // Search
    
    fileprivate var searchController: UISearchController!
    fileprivate var localSearchRequest: MKLocalSearch.Request!
    fileprivate var localSearch: MKLocalSearch!
    fileprivate var localSearchResponse: MKLocalSearch.Response!
    
    // MARK: - Map variables
    
    fileprivate var annotation: MKAnnotation!
    fileprivate var locationManager: CLLocationManager!
    fileprivate var isCurrentLocation: Bool = false
    private var currentLocation: CLLocation?
    private var startApp: Bool = true
    private var latValues = [34.0522, 20.5937, -6.2088, 26.8206, 43.6532, 52.5200, 35.6762, 55.7558, -18.7669, -38.4161] // LA, India, Jakarta, Egypt, Toronto, Berlin, Tokyo, Moscow, Madagascar ,Argentina
    private var longValues = [-118.2437 , 78.9629, 106.8456, 30.8025, -79.3832, 13.4050, 139.6503, 37.6173, 46.8691, -63.6167] // Coordinates in order
    private var mutable = 0.0
    
    // MARK: - Activity Indicator
    
    fileprivate var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - UIViewController's methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        if startApp {
            if (CLLocationManager.locationServicesEnabled()) {
                if locationManager == nil {
                    locationManager = CLLocationManager()
                }
                locationManager?.requestWhenInUseAuthorization()
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestAlwaysAuthorization()
                locationManager.startUpdatingLocation()
                isCurrentLocation = true
            }
            startApp = false
        }
        
        let currentLocationButton = UIBarButtonItem(title: "Current Location", style: UIBarButtonItem.Style.plain, target: self, action: #selector(ViewController.currentLocationButtonAction(_:)))
        self.navigationItem.leftBarButtonItem = currentLocationButton
        
        let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.search, target: self, action: #selector(ViewController.searchButtonAction(_:)))
        self.navigationItem.rightBarButtonItem = searchButton
        
        mapView.delegate = self
        if #available(iOS 9.0, *) {
            mapView.mapType = .hybridFlyover
        } else {
            mapView.mapType = .hybrid
        }
    
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        for i in 0..<latValues.count {
            var count = 1
            var temp_fireindex = 0.0
            var temp_temperature = 0.0
            var temp_humidity = 0.0
            var temp_windspeed = 0.0
            var temp_prec = 0.0
            
            let lat = latValues[i]
            let long = longValues[i]
            
            Fire.forecast(withLocation: "\(lat),\(long)") { (results:[Fire]) in
                for i in 0..<7 {
                    temp_fireindex = Double(temp_fireindex + results[i].fireindex)
                    temp_temperature = Double(temp_temperature + results[i].temp)
                    temp_humidity = Double(temp_humidity + results[i].humid)
                    temp_windspeed = Double(temp_windspeed + results[i].wind)
                    temp_prec = Double(temp_prec + results[i].precip)
                    
                    count = count + 1
                }
                
                let average_fireindex = Double(temp_fireindex)/Double(count-1)
                let average_temp = Double(temp_temperature)/Double(count-1)
                let average_humid = (Double(temp_humidity)/Double(count-1))*100
                let average_wind = Double(temp_windspeed)/Double(count-1)
                let average_prec = Double(temp_prec)/Double(count-1)
                
                let formattedIndex = round(average_fireindex, toDecimalPlaces: 2)
                let formattedTemp = round(average_temp, toDecimalPlaces: 2)
                let formattedHumid = round(average_humid, toDecimalPlaces: 2)
                let formattedWind = round(average_wind, toDecimalPlaces: 2)
                let formattedPrecip = round(average_prec, toDecimalPlaces: 2)
                
                let avg_fire = Fire(humidity: formattedHumid, wind_speed: formattedWind, temperature: formattedTemp, precipitation: formattedPrecip, fireindex: 0.0, avgFireIndex: formattedIndex)
                
                var s: String = ""
                let id = forest_fire_index(humidity: avg_fire.getHumidity(), windspeed: avg_fire.getWind(), temperature: avg_fire.getTemp(), rainfall: avg_fire.getPrecip())
                self.mutable = id
                if id <= 1.0 && id > 0.75 {
                    s = "Extremely dangerous, do not travel!"
                }
                else if id <= 0.75 && id > 0.5 {
                    s = "Moderately dangerous, not safe to travel!"
                }
                else if id <= 0.5 && id >= 0.25 {
                    s = "Slightly dangerous, travel with caution!"
                }
                else if id < 0.25 {
                    s = "Safe to travel!"
                }
                
                let region = 40000.0
                let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let circle = MKCircle(center: center, radius: region)
                
                self.mapView.addOverlay(circle)
                
                let park = Park(title: s, locationName: "Click to view data.", discipline: "2014 Forest Fire", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long), windSpeed: avg_fire.getWind(), humidity: avg_fire.getHumidity(), temperature: avg_fire.getTemp(), precipitation: avg_fire.getPrecip(), recommendation: s)
                
                self.mapView.addAnnotation(park)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        activityIndicator.center = self.view.center
    }
    
    // MARK: - Actions
    
    @objc func currentLocationButtonAction(_ sender: UIBarButtonItem) {
        if (CLLocationManager.locationServicesEnabled()) {
            if locationManager == nil {
                locationManager = CLLocationManager()
            }
            locationManager?.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            isCurrentLocation = true
        }
    }
    
    // MARK: - Zoom to tag
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // get the particular pin that was tapped
        let pinToZoomOn = view.annotation
        
        // optionally you can set your own boundaries of the zoom
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        
        // or use the current map zoom and just center the map
        // let span = mapView.region.span
        
        // now move the map
        let region = MKCoordinateRegion(center: pinToZoomOn!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Search
    
    @objc func searchButtonAction(_ button: UIBarButtonItem) {
        if searchController == nil {
            searchController = UISearchController(searchResultsController: nil)
        }
        searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        if self.mapView.annotations.count != 0 {
            annotation = self.mapView.annotations[0]
            self.mapView.removeAnnotation(annotation)
        }
        
        localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { [weak self] (localSearchResponse, error) -> Void in
            
        if localSearchResponse == nil {
            let alert = UIAlertView(title: nil, message: "Place not found", delegate: self, cancelButtonTitle: "Try again")
            alert.show()
            return
        }
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.title = searchBar.text
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude, longitude: localSearchResponse!.boundingRegion.center.longitude)
        
        let pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
        self!.mapView.centerCoordinate = pointAnnotation.coordinate
        self!.mapView.addAnnotation(pinAnnotationView.annotation!)
        
        // optionally you can set your own boundaries of the zoom
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        
        // now move the map
        let region = MKCoordinateRegion(center: pointAnnotation.coordinate, span: span)
        self?.mapView.setRegion(region, animated: true)
            
        var count = 1
        var temp_fireindex = 0.0
        var temp_temperature = 0.0
        var temp_humidity = 0.0
        var temp_windspeed = 0.0
        var temp_prec = 0.0
        
        let lat = localSearchResponse!.boundingRegion.center.latitude
        let long = localSearchResponse!.boundingRegion.center.longitude
        
        Fire.forecast(withLocation: "\(lat),\(long)") { (results:[Fire]) in
            for i in 0..<7 {
                temp_fireindex = Double(temp_fireindex + results[i].fireindex)
                temp_temperature = Double(temp_temperature + results[i].temp)
                temp_humidity = Double(temp_humidity + results[i].humid)
                temp_windspeed = Double(temp_windspeed + results[i].wind)
                temp_prec = Double(temp_prec + results[i].precip)
                
                count = count + 1
            }
        }
        
        let average_fireindex = Double(temp_fireindex)/Double(count-1)
        let average_temp = Double(temp_temperature)/Double(count-1)
        let average_humid = (Double(temp_humidity)/Double(count-1))*100
        let average_wind = Double(temp_windspeed)/Double(count-1)
        let average_prec = Double(temp_prec)/Double(count-1)
        
        let formattedIndex = round(average_fireindex, toDecimalPlaces: 2)
        let formattedTemp = round(average_temp, toDecimalPlaces: 2)
        let formattedHumid = round(average_humid, toDecimalPlaces: 2)
        let formattedWind = round(average_wind, toDecimalPlaces: 2)
        let formattedPrecip = round(average_prec, toDecimalPlaces: 2)
        
        let avg_fire = Fire(humidity: formattedHumid, wind_speed: formattedWind, temperature: formattedTemp, precipitation: formattedPrecip, fireindex: 0.0, avgFireIndex: formattedIndex)
        
        var s: String = ""
        let id = forest_fire_index(humidity: avg_fire.getHumidity(), windspeed: avg_fire.getWind(), temperature: avg_fire.getTemp(), rainfall: avg_fire.getPrecip())
        self!.mutable = id
        print(id)
        if id <= 1.0 && id > 0.75 {
            s = "Extremely dangerous, do not travel!"
        }
        else if id <= 0.75 && id > 0.5 {
            s = "Moderately dangerous, not safe to travel!"
        }
        else if id <= 0.5 && id >= 0.25 {
            s = "Slightly dangerous, travel with caution!"
        }
        else if id < 0.25 {
            s = "Safe to travel!"
        }
        
        let reg = 40000.0
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let circle = MKCircle(center: center, radius: reg)
        
        self?.mapView.addOverlay(circle)
        
        let park = Park(title: s, locationName: "Click to view data.", discipline: "2014 Forest Fire", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long), windSpeed: avg_fire.getWind(), humidity: avg_fire.getHumidity(), temperature: avg_fire.getTemp(), precipitation: avg_fire.getPrecip(), recommendation: s)
        
        self?.mapView.addAnnotation(park)
    }
}
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last }
        
        if let location = locations.last {
            let span = MKCoordinateSpan(latitudeDelta: 0.00775, longitudeDelta: 0.00775)
            let myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude,location.coordinate.longitude)
            let region = MKCoordinateRegion(center: myLocation, span: span)
            mapView.setRegion(region, animated: true)
        }
        self.mapView.showsUserLocation = true
        manager.stopUpdatingLocation()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        if self.mutable > 0.75 {
            circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.2)
            circleRenderer.strokeColor = UIColor.red
        }
        else if self.mutable <= 0.75 && mutable > 0.5 {
            circleRenderer.fillColor = UIColor.orange.withAlphaComponent(0.2)
            circleRenderer.strokeColor = UIColor.orange
        }
        else if self.mutable <= 0.5 && mutable >= 0.25 {
            circleRenderer.fillColor = UIColor.yellow.withAlphaComponent(0.2)
            circleRenderer.strokeColor = UIColor.yellow
        }
        else if self.mutable < 0.25 {
            circleRenderer.fillColor = UIColor.green.withAlphaComponent(0.2)
            circleRenderer.strokeColor = UIColor.green
        }
        circleRenderer.lineWidth = 1
        return circleRenderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Park else {return nil}
        
        let identifier = "marker"
        var view: MKAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        }
        else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let park = view.annotation as! Park
        let parkSafety = park.safetyInfo
        let recommendation = park.recommendation
        
        let ac = UIAlertController(title: recommendation, message: parkSafety, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

class Park : NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    let windSpeed: Double
    let humidity: Double
    let temperature: Double
    let precipitation: Double
    let safetyInfo: String?
    let recommendation: String?
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D, windSpeed: Double, humidity: Double, temperature: Double, precipitation: Double, recommendation: String) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        self.windSpeed = windSpeed
        self.humidity = humidity
        self.temperature = temperature
        self.precipitation = precipitation
        self.safetyInfo = "Wind Speed: \(windSpeed) mph \n Humidity: \(humidity)% \n Temperature: \(temperature) °F \n Precipitation: \(precipitation) inches"
        self.recommendation = recommendation
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}

struct Fire {
    let humid:Double
    let wind:Double
    let temp:Double
    let precip:Double
    var fireindex:Double
    var avgFireIndex:Double
    
    
    enum SerializationError:Error {
        case missing(String)
        case invalid(String, Any)
    }
    
    
    init(json:[String:Any]) throws {
        guard let humidity = json["humidity"] as? Double else {throw SerializationError.missing("humidity is missing")}
        
        guard let windspeed = json["windSpeed"] as? Double else {throw SerializationError.missing("windspeed is missing")}
        
        guard let temperature = json["temperatureMax"] as? Double else {throw SerializationError.missing("temp is missing")}
        guard let precipitation = json["precipIntensityMax"] as? Double else {throw SerializationError.missing("precipiation is missing")}
        
        self.humid = humidity
        self.wind = windspeed
        self.temp = temperature
        self.precip = precipitation
        
        self.fireindex = 0.00
        self.avgFireIndex = 0.00
    }
    
    init(humidity:Double, wind_speed:Double, temperature:Double, precipitation:Double, fireindex:Double, avgFireIndex:Double) {
        self.humid = humidity
        self.wind = wind_speed
        self.temp = temperature
        self.precip = precipitation
        self.fireindex = fireindex
        self.avgFireIndex = avgFireIndex
    }
    
    static let basePath = "https://api.darksky.net/forecast/ee5ef44bfbfdf5a233a6c7e2c4c4151d/"
    
    static func forecast (withLocation location:String, completion: @escaping ([Fire]) -> ()) {
        
        let url = basePath + location
        
        let request = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            
            var fireForecastArray:[Fire] = []
            
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                        if let dailyForecasts = json["daily"] as? [String:Any] {
                            if let dailyData = dailyForecasts["data"] as? [[String:Any]] {
                                for dataPoint in dailyData {
                                    if var fireObject = try? Fire(json: dataPoint) {
                                        fireObject.fireindex = forest_fire_index(humidity: fireObject.humid, windspeed: fireObject.wind, temperature: fireObject.temp, rainfall: fireObject.precip)
                                        fireForecastArray.append(fireObject)
                                    }
                                }
                            }
                        }
                        
                    }
                }catch {
                    print(error.localizedDescription)
                }
                completion(fireForecastArray)
            }
        }
        
        task.resume()
        
    }
    
    func getHumidity() -> Double {
        return humid
    }
    
    func getWind() -> Double {
        return wind
    }
    
    func getTemp() -> Double {
        return temp
    }
    
    func getPrecip() -> Double {
        return precip
    }
    
    func getAvgFireIndex() -> Double {
        return avgFireIndex
    }

}

func forest_fire_index(humidity: Double, windspeed: Double, temperature: Double, rainfall: Double)->Double {
    if humidity<0.15 {
        return 1.0
    } else if temperature > 95 {
        return 1.0
    } else if temperature > 90 {
        return 0.75
    } else if temperature > 30 {
        return 0.5
    }
    else {
        return 0.25
    }
}

func round(_ value: Double, toDecimalPlaces places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return round(value * divisor) / divisor
}
