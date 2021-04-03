//
//  ViewController.swift
//  Verification Task
//
//  Created by Nam on 4/1/21.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    //MARK: -Propeties
    private let locationManager = CLLocationManager()
    
    var workItem1: DispatchWorkItem?
    var workItem2: DispatchWorkItem?
    var workItem3: DispatchWorkItem?

    
    private var batteryLevel: Int {
        return Int(round(UIDevice.current.batteryLevel * 100))*(-1)
    }
    
    private var workItems: [DispatchWorkItem] = []
    private var level = 0
    
    private var percentUsage = 0
    
    private var L : [String] = []
    
    fileprivate let globalBackgroundSyncroizeDataQueue = DispatchQueue(label: "globalBackgroundSyncroizeSharedData")
    
    var LOfFeedItems: [String] {
        set(newValue) {
            globalBackgroundSyncroizeDataQueue.sync {
                self.L = newValue
            }
        }
        get{
            return globalBackgroundSyncroizeDataQueue.sync { L }
        }
    }

    //MARK: -Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ask for authorisation from the User
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            
        }
        // get percent battery usage
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        level = batteryLevel
        
    }

    //MARK: -Methods
    @IBAction func btnStart(_ sender: Any) {

        //MARK: -Thread 1
        workItem1 = DispatchWorkItem {

            while true {
                self.locationManager.startUpdatingLocation()
                sleep(360)
                if ((self.workItem1?.isCancelled) == true) {
                    break
                }
            }
            
        }
        workItems.append(workItem1!)
        
        //MARK: -Thread 2
        workItem2 = DispatchWorkItem {
            while true {
                self.percentUsage = abs(self.level - self.batteryLevel)
                self.LOfFeedItems.append("\(String(self.percentUsage))%")
                self.level = self.batteryLevel
                sleep(540)
                if ((self.workItem2?.isCancelled) == true) {
                    break
                }
            }
        }
        workItems.append(workItem2!)
        
        //MARK: -Thread 3
        workItem3 = DispatchWorkItem {

            while true {
                if ((self.workItem3?.isCancelled) == true) {
                    break
                }
                
                //count items
                if self.LOfFeedItems.count > 5 {
                    
                    var dict = [String:String]()
                    for i in 0..<self.LOfFeedItems.count {
                        dict[String(i)] = self.LOfFeedItems[i]
                    }
//                    send to server
                    let url = URL(string: "http://sigma-solutions.eu/test")!
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    guard let httpBody = try? JSONSerialization.data(withJSONObject: dict, options: []) else {return}
                    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = httpBody
                    urlRequest.timeoutInterval = 20
                    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                        if let response = response {
//                                    print(response)
                                }
                                if let data = data {
                                    do {
                                        let json = try JSONSerialization.jsonObject(with: data, options: [])
//                                        print(json)
                                    } catch {
//                                        print(error)
                                    }
                                }
                    }.resume()
                    self.LOfFeedItems.removeAll()
                    print("workItem3")
                    
                }
                
            }
            
        }
        workItems.append(workItem3!)
        
        for i in 0..<workItems.count {
            DispatchQueue.global().async(execute: workItems[i])
        }
    }
    
    @IBAction func btnStop(_ sender: Any) {
        for i in 0..<workItems.count {
            workItems[i].cancel()
        }
        for i in 0..<workItems.count {
            print(workItems[i].isCancelled)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        let coordinate = "latitude: \(locValue.latitude)   longtitude: \(locValue.longitude)"
        LOfFeedItems.append(coordinate)
        self.locationManager.stopUpdatingLocation()
    }
    


}

