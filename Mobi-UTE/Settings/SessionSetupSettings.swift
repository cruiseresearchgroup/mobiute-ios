//
//  SessionSetupSettings.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 5/06/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation
import SwiftyJSON

public class SessionSetupSettings : NSObject {
  public class SettingsSensor : NSObject {
    public var name: String?
    public var freq: Double?
    public var sec: Double?
  }
  
  public class SettingsLabel : NSObject {
    public var type: String?;
    public var schema: [SettingsLabelInterval]?;
  }
  
  public class SettingsLabelInterval : NSObject {
    public var set: [String]?;
    public var is_nullable: Bool?;
    public var only_can_select_one: Bool?;
  }
  
  public var version: Double?;
  public var maximumRecordingDuration: Int?;
  public var sensors: [SettingsSensor]?;
  public var label: SettingsLabel?;
  
  public func toDict() -> [String: Any] {
    var dict: [String: Any] = [String: Any]()
    
    if let version = self.version {
      dict["version"] = version
    }
    
    if let maximumRecordingDuration = self.maximumRecordingDuration {
      dict["maximumRecordingDuration"] = maximumRecordingDuration
    }
    
    if let sensors: [SettingsSensor] = self.sensors {
      var sensorCollection = [[String: Any]]()
      for sensor in sensors {
        var sensorDict = [String: Any]()
        if let name = sensor.name {
          sensorDict["name"] = name
        }
        
        if let freq = sensor.freq {
          sensorDict["freq"] = freq
        }
        
        if sensorDict.count > 0 {
          sensorCollection.append(sensorDict)
        }
      }
      dict["sensors"] = sensorCollection
    }
    
    if let label = self.label {
      var labelContainer = [String: Any]()
      if let type = label.type {
        labelContainer["type"] = type
      }
      
      if let schema = label.schema {
        var schemaset = [[String: Any]]()
        for item in schema {
          var itemset = [String: Any]()
          var setArray: [String]?
          if let set = item.set {
            setArray = set
          }
          if let setArray = setArray {
            itemset["set"] = setArray
          }
          
          if let isnullable = item.is_nullable {
            itemset["is_nullable"] = isnullable
          }
          
          if let only_can_select_one = item.only_can_select_one {
            itemset["only_can_select_one"] = only_can_select_one
          }
          schemaset.append(itemset)
        }
        
        if schemaset.count > 0 {
          labelContainer["schema"] = schemaset
        }
      }
      
      dict["label"] = labelContainer
    }
    
    return dict
  }
  
  public static func parse(settingsObjectFromDictionary: [String: AnyObject]) -> SessionSetupSettings? {
    if settingsObjectFromDictionary.count == 0 {
      return nil;
    }
    
    let parsedObject: SessionSetupSettings = SessionSetupSettings()
    if let version = settingsObjectFromDictionary["version"] as? Double {
      parsedObject.version = version;
    }
    
    if let maximumRecordingDuration = settingsObjectFromDictionary["maximumRecordingDuration"] as? Int {
      parsedObject.maximumRecordingDuration = maximumRecordingDuration;
    }
    
    if let sensorsDict = settingsObjectFromDictionary["sensors"] as? [[String: AnyObject]] {
      var sensors = [SettingsSensor]()
      for sensorsDictValue: [String: AnyObject] in sensorsDict {
        let sensor = SettingsSensor()
        sensor.name = sensorsDictValue["name"] as? String
        sensor.freq = sensorsDictValue["freq"] as? Double
        sensor.freq = sensorsDictValue["sec"] as? Double
        sensors.append(sensor);
      }
      
      if sensors.count > 0 {
        parsedObject.sensors = sensors
      }
    }
    
    if let labelDict = settingsObjectFromDictionary["label"] as? [String: AnyObject] {
      parsedObject.label = SettingsLabel()
      if let type = labelDict["type"] as? String {
        parsedObject.label!.type = type;
        if type == "interval" {
          if let schemaDict = labelDict["schema"] as? [[String: AnyObject]] {
            parsedObject.label!.schema = [SettingsLabelInterval]()
            for schemaDictValue: [String: AnyObject] in schemaDict {
              let labelInterval = SettingsLabelInterval()
              labelInterval.set = schemaDictValue["set"] as? [String];
              labelInterval.is_nullable = schemaDictValue["is_nullable"] as? Bool;
              labelInterval.only_can_select_one = schemaDictValue["only_can_select_one"] as? Bool;
              parsedObject.label!.schema?.append(labelInterval);
            }
          }
        }
      }
    }
    
    return parsedObject;
  }
  
  public static func parseFromJson(settingsJSON: SwiftyJSON.JSON) -> SessionSetupSettings? {
    
    let parsedObject: SessionSetupSettings = SessionSetupSettings()
    if let version = settingsJSON["version"].double {
      parsedObject.version = version;
    }
    
    if let maximumRecordingDuration = settingsJSON["maximumRecordingDuration"].int {
      parsedObject.maximumRecordingDuration = maximumRecordingDuration;
    }
    
    parsedObject.sensors = [SettingsSensor]()
    if let _ = parsedObject.sensors, let sensorsJSON = settingsJSON["sensors"].array {
      for sensorsDictValue: SwiftyJSON.JSON in sensorsJSON {
        let sensor = SettingsSensor()
        sensor.name = sensorsDictValue["name"].string;
        sensor.freq = sensorsDictValue["freq"].double;
        if sensor.freq == nil {
          // try parse as string then convert to double
          if let freqStringValue = sensorsDictValue["freq"].string {
            if freqStringValue.isEmpty {
              sensor.freq = nil
            } else {
              sensor.freq = Double(freqStringValue)
              if sensor.freq == 0.0 {
                sensor.freq = nil
              }
            }
          } else {
            sensor.freq = nil
          }
        }
        
        sensor.sec = sensorsDictValue["sec"].double;
        if sensor.sec == nil {
          // try parse as string then convert to double
          if let secStringValue = sensorsDictValue["sec"].string {
            if secStringValue.isEmpty {
              sensor.sec = nil
            } else {
              sensor.sec = Double(secStringValue)
              if sensor.sec == 0.0 {
                sensor.sec = nil
              }
            }
          } else {
            sensor.sec = nil
          }
        }
        
        if sensor.freq != nil || sensor.sec != nil {
          parsedObject.sensors!.append(sensor)
        }
      }
    }
    
    parsedObject.label = SettingsLabel()
    if let type = settingsJSON["label"]["type"].string {
      parsedObject.label!.type = type;
      if type == "interval" {
        if let schemaDict: [JSON] = settingsJSON["label"]["schema"].array {
          parsedObject.label!.schema = [SettingsLabelInterval]()
          for schemaDictValue: JSON in schemaDict {
            let labelInterval = SettingsLabelInterval()
            labelInterval.set = schemaDictValue["set"].arrayValue.map { $0.string! };
            labelInterval.is_nullable = schemaDictValue["is_nullable"].bool;
            labelInterval.only_can_select_one = schemaDictValue["only_can_select_one"].bool;
            parsedObject.label!.schema?.append(labelInterval);
          }
        }
      }
    }
    
    return parsedObject;
  }
  
  
}
