//
//  EmpaticaViewController.swift
//  weatherBot
//
//  Created by Shardul Sapkota on 6/18/19.
//  Copyright © 2019 Enrico Piovesan. All rights reserved.
//

//
//  ViewController.swift
//  E4 tester
//

import UIKit
import CoreData
import Accelerate
import PromiseKit
import AVFoundation


class EmpaticaViewController: UIViewController {
    var ibiList: [Float] = []

    
    static let EMPATICA_API_KEY = "62e322cb9dac410e9041afc08d977669"
    var empaticaStatus: Bool = false
//    var homeVC : HomeViewController = HomeViewController()
    
    
    private var devices: [EmpaticaDeviceManager] = []
    
    var backButton = UIButton()
    let aiService: AIService = AIService()
    
    var speechSynthesizer = AVSpeechSynthesizer()
    var speechUtterance: AVSpeechUtterance = AVSpeechUtterance()
    var speechPaused: Bool = false
    var userFinishedSpeaking: Bool = false

    
    private var allDisconnected : Bool {
        
        return self.devices.reduce(true) { (value, device) -> Bool in
            
            value && device.deviceStatus == kDeviceStatusDisconnected
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
//        initEmpatica()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        //1
//        guard let appDelegate =
//            UIApplication.shared.delegate as? AppDelegate else {
//                return
//        }
//
//        let managedContext =
//            appDelegate.persistentContainer.viewContext
//
//        //2
//        let fetchRequest =
//            NSFetchRequest<NSManagedObject>(entityName: "EmpaticaStatus")
//
//        //3
//        do {
//            empaticaStatus = try managedContext.fetch(fetchRequest) as! [EmpaticaStatus]
//        } catch let error as NSError {
//            print("Could not fetch. \(error), \(error.userInfo)")
//        }
//    }
//
    
    
    func get_devices() -> [EmpaticaDeviceManager]{
        return self.devices
    }
    
    

    
    func initEmpatica(backButton: UIButton){
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            EmpaticaAPI.authenticate(withAPIKey: EmpaticaViewController.EMPATICA_API_KEY) { (status, message) in
                
                if status {
                    
                    // "Authenticated"
                    
                    DispatchQueue.main.async {
                        
                        self.discover()
                        self.backButton = backButton
                    }
                }
            }
        }
    }
    
   private func discover() {
        EmpaticaAPI.discoverDevices(with: self)
    }
    
    private func disconnect(device: EmpaticaDeviceManager) {
        
        if device.deviceStatus == kDeviceStatusConnected {
            
            device.disconnect()
        }
        else if device.deviceStatus == kDeviceStatusConnecting {
            
            device.cancelConnection()
        }
    }
    
    private func connect(device: EmpaticaDeviceManager) {
        device.connect(with: self)
    }
    
//    private func updateValue(device : EmpaticaDeviceManager, string : String = "") {
//
//        if let row = self.devices.index(of: device) {
//
//            DispatchQueue.main.async {
//
//                for cell in self.tableView.visibleCells {
//
//                    if let cell = cell as? DeviceTableViewCell {
//
//                        if cell.device == device {
//
//                            let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0))
//
//                            if !device.allowed {
//
//                                cell?.detailTextLabel?.text = "NOT ALLOWED"
//
//                                cell?.detailTextLabel?.textColor = UIColor.orange
//                            }
//                            else if string.count > 0 {
//
//                                cell?.detailTextLabel?.text = "\(self.deviceStatusDisplay(status: device.deviceStatus)) • \(string)"
//
//                                cell?.detailTextLabel?.textColor = UIColor.gray
//                            }
//                            else {
//
//                                cell?.detailTextLabel?.text = "\(self.deviceStatusDisplay(status: device.deviceStatus))"
//
//                                cell?.detailTextLabel?.textColor = UIColor.gray
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    private func deviceStatusDisplay(status : DeviceStatus) -> String {
        
        switch status {
            
        case kDeviceStatusDisconnected:
            return "Disconnected"
        case kDeviceStatusConnecting:
            return "Connecting..."
        case kDeviceStatusConnected:
            return "Connected"
        case kDeviceStatusFailedToConnect:
            return "Failed to connect"
        case kDeviceStatusDisconnecting:
            return "Disconnecting..."
        default:
            return "Unknown"
        }
    }
    
    func createTimeStamp() -> String{
        let now = Date()
        
        let formatter = DateFormatter()
        
        formatter.timeZone = TimeZone.current
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString = formatter.string(from: now)
        return dateString
    }
    
    private func restartDiscovery() {
        
        print("restartDiscovery")
        
        guard EmpaticaAPI.status() == kBLEStatusReady else { return }
        
        if self.allDisconnected {
            
            print("restartDiscovery • allDisconnected")
            
            self.discover()
        }
    }
}


extension EmpaticaViewController: EmpaticaDelegate {
    
    func didDiscoverDevices(_ devices: [Any]!) {
        
        print("didDiscoverDevices")
        
        if self.allDisconnected {
            
            print("didDiscoverDevices • allDisconnected")
            
            self.devices.removeAll()
            
            self.devices.append(contentsOf: devices as! [EmpaticaDeviceManager])
            
            DispatchQueue.main.async {
                
                if (!self.devices.isEmpty){
                    self.connect(device: self.devices[0])
                }

                if self.allDisconnected {

                    EmpaticaAPI.discoverDevices(with: self)
                }
                
            }
        }
    }
    
    func didUpdate(_ status: BLEStatus) {
        
        switch status {
        case kBLEStatusReady:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusReady")
            break
        case kBLEStatusScanning:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusScanning")
            break
        case kBLEStatusNotAvailable:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusNotAvailable")
            break
        default:
            print("[didUpdate] status \(status.rawValue)")
        }
    }
}


extension EmpaticaViewController: EmpaticaDeviceDelegate {
    
    func saveToFile(fileName: String, stringToWrite: String){
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create: true)
            let fileURL = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("txt")
            print("File Path: \(fileURL.path)")
            print("WRITING TO FILE")
            //            let stringToWrite = stringToWrite.joined(separator: "\n")
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("FILE NAME ALREADY EXISTS")
                var err:NSError?
                do{
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(Data(stringToWrite.utf8))
                    fileHandle.closeFile()
                    
                    
                } catch{
                    print("Can't open fileHandle \(err)")
                }
            } else {
                try stringToWrite.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            }
            
        } catch {
            print(error)
        }
        
    }
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        print("\(device.serialNumber!) { \(timestamp) }, TEMP { \(temp) }")
    }

    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        
        var rmssd: Float = 0.0
        var sdnn: Float = 0.0
        var ratio: Float = 0.0
        var mean: Float = 0.0
        var ssd: [Float] = []
    
        ibiList.append(ibi)
        

        if ibiList.count > 30 {
            print("IBI LIST COUNT >>>>")

            // Calculate RMSSD
            for i in 0..<(ibiList.count-1) {
                ssd.append(ibiList[i]-ibiList[i+1])
            }
            
            vDSP_rmsqv(ssd, 1, &rmssd, vDSP_Length(ssd.count))
            
            // Calculate SDNN
            vDSP_normalize(ibiList, 1, nil, 1, &mean, &sdnn, vDSP_Length(ibiList.count - 1))
            
            ratio = sdnn/rmssd
            
            ibiList.remove(at: 0)
            
            print(rmssd, sdnn, ratio)
            
            if (ratio < 0.8 && ratio > 0) {
            print("RELAXED")
                
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calm_event"), object: nil)

            }
            
        }
        
        var stringToWrite = "\(device.serialNumber!), { \(timestamp) },  IBI { \(ibi) }"
        
        print(stringToWrite)
        self.saveToFile(fileName: "ibi", stringToWrite: stringToWrite)
        
    }
    
//    func didReceiveHR(_ hr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
//        
//        var stringToWrite = "\(device.serialNumber!), { \(timestamp) },  HR { \(hr) }\n"
//        
//        print(stringToWrite)
//        self.saveToFile(fileName: "hr", stringToWrite: stringToWrite)
//        
//    }
//    
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        var stringToWrite = "\(device.serialNumber!), { \(timestamp) }, ACC > {x: \(x), y: \(y), z: \(z)}\n"
        
        print(stringToWrite)
        
        self.saveToFile(fileName: "acc", stringToWrite: stringToWrite)
    }
    
    func didReceiveTag(atTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        print("\(device.serialNumber!) TAG received { \(timestamp) }")
    }
    
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        var stringToWrite = "\(device.serialNumber!), { \(timestamp) },  GSR { \(abs(gsr)) }\n"
        
        print(stringToWrite)
        
        self.saveToFile(fileName: "gsr", stringToWrite: stringToWrite)

//        self.updateValue(device: device, string: "\(String(format: "%.2f", abs(gsr))) µS")
    }
 
    
    
//    func saveDeviceStatus(connected: Bool){
//        guard let appDelegate =
//            UIApplication.shared.delegate as? AppDelegate else {
//                return
//        }
//
//        let managedContext =
//            appDelegate.persistentContainer.viewContext
//
//        let entity =
//            NSEntityDescription.entity(forEntityName: "EmpaticaStatus",
//                                       in: managedContext)!
//
//        self.empaticaStatus = EmpaticaStatus(entity: entity,
//                               insertInto: managedContext)
//
//        self.empaticaStatus?.empaticaStatus = connected
//
//        do {
//            try managedContext.save()
//
//        } catch let error as NSError {
//            print("Could not save. \(error), \(error.userInfo)")
//        }
//    }
//
    
    func didUpdate( _ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        

        switch status {
            
        case kDeviceStatusDisconnected:
            
            print("[didUpdate] Disconnected \(device.serialNumber!).")
            
            backButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            empaticaStatus = false
//            saveDeviceStatus(false)
            self.restartDiscovery()
            
            break
            
        case kDeviceStatusConnecting:
            
            print("[didUpdate] Connecting \(device.serialNumber!).")
            break
            
        case kDeviceStatusConnected:
            
            print("[didUpdate] Connected \(device.serialNumber!).")
//            saveDeviceStatus(true)
            empaticaStatus = true
            backButton.backgroundColor = UIColor.green.withAlphaComponent(0.7)
            break
            
        case kDeviceStatusFailedToConnect:
            
            print("[didUpdate] Failed to connect \(device.serialNumber!).")
            
            self.restartDiscovery()
            
            break
            
        case kDeviceStatusDisconnecting:
            
            print("[didUpdate] Disconnecting \(device.serialNumber!).")
            
            break
            
        default:
            break
            
        }
    }
}

//extension EmpaticaViewController {
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        EmpaticaAPI.cancelDiscovery()
//
//        let device = self.devices[indexPath.row]
//
//        if device.deviceStatus == kDeviceStatusConnected || device.deviceStatus == kDeviceStatusConnecting {
//
//            self.disconnect(device: device)
//        }
//        else if !device.isFaulty && device.allowed {
//
//            self.connect(device: device)
//        }
//
////        self.updateValue(device: device)
//    }
//}

//extension EmpaticaViewController {
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//
//        return self.devices.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let device = self.devices[indexPath.row]
//
//        let cell = tableView.dequeueReusableCell(withIdentifier: "device") as? DeviceTableViewCell ?? DeviceTableViewCell(device: device)
//
//        cell.device = device
//
//        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
//
//        cell.textLabel?.text = "E4 \(device.serialNumber!)"
//
//        cell.alpha = device.isFaulty || !device.allowed ? 0.2 : 1.0
//
//        return cell
//    }
//}

class DeviceTableViewCell : UITableViewCell {
    
    
    var device : EmpaticaDeviceManager
    
    
    init(device: EmpaticaDeviceManager) {
        
        self.device = device
        
        super.init(style: UITableViewCellStyle.value1, reuseIdentifier: "device")
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
}
