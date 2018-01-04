//
//  UTEModelBluetoothInfo.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 18/11/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation

class UTEModelBluetoothInfo: NSObject {
  public var id: UInt64?
  public var uuid: String?
  public var name: String?
  public var rssi: Double?
  public var timestamp: Double?
  
  public func toJson() -> [String: AnyObject] {
    var dict: [String: AnyObject] = [String: AnyObject]()
    dict["id"] = (self.id != nil) ? self.id! as AnyObject : NSNull()
    dict["uuid"] = (self.uuid != nil) ? self.uuid! as AnyObject : NSNull()
    dict["name"] = (self.name != nil) ? self.name! as AnyObject : NSNull()
    dict["rssi"] = (self.rssi != nil) ? self.rssi! as AnyObject : NSNull()
    dict["t"] = (self.timestamp != nil) ? self.timestamp! as AnyObject : NSNull()
    
    return dict;
  }
}
