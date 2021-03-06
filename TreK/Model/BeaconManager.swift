//
//  BeaconManager.swift
//  pedometer
//
//  Created by Arjun Maganti on 12/27/20.
//

import Foundation
import CoreLocation
import Combine


struct Sensor: Hashable, Codable, Identifiable {
    var id: Int
    var uuid: String
    var name: String
    var icon: String
    var iconColor: String
    var backgroundImage: String
    var isActive: Bool
    var distance: Double
    var onEnterMessage: String
    var entryAnnounced: Bool
    var entryTime: Date?
    var regionElapseTime: Int?
    var regionElapseMessage: String?
}

class BeaconManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private var locationSensors: [Sensor] = []
    private var calibratedDistance = 3.0

    private var alertManager = Alerts()
  

    
    @Published private (set) var locationPermissionGranted = false
    
   
    @Published var selectedBeacon:Sensor  {
        willSet { objectWillChange.send() }
    }
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
   
    
    @Published var notification = "" {
        willSet { objectWillChange.send() }
    }
    

   
    override init() {
        
        
        self.selectedBeacon = Sensor(id:20201,
              uuid: "cbc59d2a-ca70-44cc-99c2-ca854",
              name:"Unknown",
              icon:"tv",
              iconColor:"gray",
              backgroundImage: "lr",
              isActive: false,
              distance: 30,
              onEnterMessage: "",
              entryAnnounced: false)
        
        
        super.init()
        
        locationManager.delegate = self
  
        alertManager.requestNotifications()
        requestLocationPermission()
      
        loadSensors()

      }
    
    
    
    func loadSensors(){
        
        locationSensors.append(Sensor(id:20201,
                                      uuid: "cbc59d2a-ca70-44cc-99c2-ca85447ad4de",
                                      name:"Living Room",
                                      icon:"tv",
                                      iconColor:"gray",
                                      backgroundImage: "lr",
                                      isActive: false,
                                      distance: 30,
                                      onEnterMessage: "Let's watch some TV",
                                      entryAnnounced: false,
                                      regionElapseTime: 60,
                                      regionElapseMessage: "Lets stop watching TV"))
        locationSensors.append(Sensor(id:20202,
                                      uuid: "821f04d8-92e0-4fec-8b69-0cd710a68dce",
                                      name:"Bedroom",
                                      icon:"bed.double",
                                      iconColor:"gray",
                                      backgroundImage: "br",
                                      isActive: false,
                                      distance: 30,
                                      onEnterMessage: "Let's Relax",
                                      entryAnnounced: false,
                                      regionElapseTime: 120,
                                      regionElapseMessage: "Wake up, let's go for a walk"))
        locationSensors.append(Sensor(id:20203,
                                      uuid: "34fa2185-a252-42bd-a186-3073e2cd0a8c",
                                      name:"Entry Door",
                                      icon:"house",
                                      iconColor:"gray",
                                      backgroundImage: "dr",
                                      isActive: false,
                                      distance: 30,
                                      onEnterMessage: "Let's go for a walk",
                                      entryAnnounced: false))
       locationSensors.append(Sensor(id:20203,
                                      uuid: "a2711288-3d52-4088-895f-4914f8c12646",
                                      name:"Elevator",
                                      icon:"capslock",
                                      iconColor:"gray",
                                      backgroundImage: "el",
                                      isActive: false,
                                      distance: 30,
                                      onEnterMessage: "Let's skip elevator and take stairs",
                                      entryAnnounced: false))
 
        
    }
        
    func requestLocationPermission() {
        self.locationManager.requestAlwaysAuthorization()
    }
        
    func locationManager(_ manager: CLLocationManager,
                             didEnterRegion region: CLRegion){
       
       
            
    }

    func locationManager(_ manager: CLLocationManager,
                         didExitRegion region: CLRegion){
                print ("Exit")

        if let beaconRegion = region as? CLBeaconRegion {
            print("Exit: uuid: \(beaconRegion.uuid.uuidString)")
            if(selectedBeacon.uuid == beaconRegion.uuid.uuidString.lowercased()){
                selectedBeacon.isActive = false
            }
            
        }
  
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
      print("Failed monitoring region: \(error.localizedDescription)")
    }
          
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion){
        guard region is CLBeaconRegion else {return}
                print("Event detected: \(state.rawValue) for \(region.identifier)")
    }
        
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedAlways {
                publish(permissionGranted: true)
                if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                    startMonitoring()
                
                    return
                }
            } else {
                publish(permissionGranted: false)
            }
    }

    func publish(permissionGranted: Bool) {
            DispatchQueue.main.async {
                self.locationPermissionGranted = permissionGranted
            }
    }
        
    func startMonitoring() {
        
        for locationSensor in locationSensors{
            let uuid = UUID(uuidString: locationSensor.uuid)
            let beaconID = "com.cybertron.myBeaconRegion"
            let constraint = CLBeaconIdentityConstraint(uuid: uuid!,
                                                        major: CLBeaconMajorValue(2020),
                                                        minor:  CLBeaconMinorValue(17))
            locationManager.startRangingBeacons(satisfying: constraint)
            
            
            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: beaconID)
            locationManager.startMonitoring(for: beaconRegion)
            
            print ("add for monitoring \(locationSensor.uuid)")
        }
       
                    
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        for beacon in beacons{
            print ("Beacon ID: \(beacon.uuid)")
            print ("Beacon ID: \(beacon.accuracy)")
            
            if(beacon.accuracy == -1.0){
                selectedBeacon.isActive = false
                selectedBeacon.entryAnnounced = false
                selectedBeacon.backgroundImage = "bkg"
                selectedBeacon.name = "Unknown"
            }
            else if((beacon.accuracy>0) && (beacon.accuracy<calibratedDistance)){
                
                
                if let index = locationSensors.firstIndex(where: {$0.uuid == beacon.uuid.uuidString.lowercased()}){
                    if(selectedBeacon.isActive && (selectedBeacon.uuid == locationSensors[index].uuid)){
                        //notifies only once on entry
                        if(!selectedBeacon.entryAnnounced){
                            alertManager.showAlert(title: "TreK",subtitle: selectedBeacon.onEnterMessage)
                            selectedBeacon.entryAnnounced = true
                        }
                        
                        //notifies on elapses time
                        if(selectedBeacon.regionElapseTime != nil){
                            let beaconElapseTime = Int(Date().timeIntervalSince(selectedBeacon.entryTime!))
                            if(beaconElapseTime > selectedBeacon.regionElapseTime!){
                                alertManager.showAlert(title: "TreK",subtitle: selectedBeacon.regionElapseMessage!)
                                selectedBeacon.entryTime = Date()
                            }
                        }
                        
                    }
                    else{
                        selectedBeacon = locationSensors[index]
                        selectedBeacon.isActive = true
                        selectedBeacon.entryTime = Date()
                        selectedBeacon.distance = beacon.accuracy
                        
                        //print ("selected beacon : \(selectedBeacon.name)")
                        //print ("selected beacon status : \(selectedBeacon.isActive)")
                        //print ("moveNotified : \(moveNotified)")
                    }
                }
                
               
            }
            else if((beacon.uuid.uuidString.lowercased() == selectedBeacon.uuid) && (beacon.accuracy>calibratedDistance) && selectedBeacon.isActive){
                
                selectedBeacon.isActive = false
                selectedBeacon.entryAnnounced = false
                selectedBeacon.backgroundImage = "bkg"
                selectedBeacon.name = "Unknown"
                
               
            }
            
                
        }
        
        
        
    }
    
    
    
    
}
