//
//  ServerSettingsService.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 1/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import UIKit

class ServerSettingsService {
  class var sharedInstance: ServerSettingsService {
    struct Singleton {
      static let instance = ServerSettingsService()
    }
    
    return Singleton.instance
  }
  
  let plist: NSDictionary;
  
  init(){
    let filePath = Bundle.main.path(forResource: "MobiUTE_Settings", ofType:"plist")
    plist = NSDictionary(contentsOfFile:filePath!)!
  }
  
  func baseUrl() -> String {
    return UserSettingsService.sharedInstance.getSettingsBaseServerUrl() ?? self.plist.object(forKey: "BaseServerUrl") as! String
  }
  
  func getDeviceUDID() -> String {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
      let testuuid = self.plist.object(forKey: "TestDeviceUUID") as? String;
      if(testuuid != nil && !testuuid!.isEmpty)
      {
        // example: E6D936C5-3B73-4F41-8CD3-063210A23236
        return testuuid!;
      }
      
      return "069551DB-0921-4FDF-BD73-7AEE584074B4"
    #else
      if let vendorIdentifier = UIDevice.current.identifierForVendor {
        return vendorIdentifier.uuidString
      } else {
        return "069551NO-UUID-0000-BD73-7AEE584074B4"
      }
    #endif
  }
  
  func getDeviceModel() -> String {
    return UIDevice.current.modelName
  }
  
  func enableBatteryMonitoring() {
    UIDevice.current.isBatteryMonitoringEnabled = true
  }
  
  func disableBatteryMonitoring() {
    UIDevice.current.isBatteryMonitoringEnabled = false
  }
  
  func getDeviceBatteryLevel() -> Float {
    return UIDevice.current.batteryLevel
  }
  
  func isBatteryBeingCharged() -> Bool {
    return UIDevice.current.batteryState == UIDeviceBatteryState.charging
  }
}
