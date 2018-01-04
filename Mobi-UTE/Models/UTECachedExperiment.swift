//
//  UTECachedExperiment.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 3/11/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation
import SwiftyJSON

public class UTECachedExperiment: NSObject {
  public var experiment_id: String?
  public var experiment_alias: String?
  public var title:String?
  public var desc: String?
  public var uid: String?
  public var server_time: Double?
  public var campaign_end_at: Double?
  public var settings: SessionSetupSettings?
  
  // settings: [String: AnyObject]
  public func toDict() -> [String: Any] {
    var dict: [String: Any] = [String: Any]()
    if let experimentId = self.experiment_id {
      dict["experiment_id"] = experimentId
    }
    
    if let experimentAlias = self.experiment_alias{
      dict["experiment_alias"] = experimentAlias
    }
    
    if let title = self.title {
      dict["title"] = title
    }
    
    if let desc = self.desc {
      dict["desc"] = desc
    }
    
    if let uid = self.uid {
      dict["uid"] = uid
    }
    
    if let server_time = self.server_time {
      dict["server_time"] =  server_time
    }
    
    if let campaign_end_at = self.campaign_end_at {
      dict["campaign_end_at"] = campaign_end_at
    }
    
    if let settings = self.settings {
      dict["settings"] = settings.toDict()
    }
    
    return dict
  }
  
  public static func parseFromJson(cachedExperimentJson: SwiftyJSON.JSON) -> [UTECachedExperiment] {
    var parsedObject: [UTECachedExperiment] = [UTECachedExperiment]()
    if let cachedExperimentRow = cachedExperimentJson.array {
      for cachedExperimentRowDictValue: SwiftyJSON.JSON in cachedExperimentRow {
        let cachedExperiment: UTECachedExperiment = UTECachedExperiment()
        cachedExperiment.experiment_id = cachedExperimentRowDictValue["experiment_id"].string;
        cachedExperiment.experiment_alias = cachedExperimentRowDictValue["experiment_alias"].string;
        cachedExperiment.title = cachedExperimentRowDictValue["title"].string;
        cachedExperiment.desc = cachedExperimentRowDictValue["desc"].string;
        cachedExperiment.uid = cachedExperimentRowDictValue["uid"].string;
        cachedExperiment.server_time = cachedExperimentRowDictValue["server_time"].double
        cachedExperiment.campaign_end_at = cachedExperimentRowDictValue["campaign_end_at"].double
        
        // settings
        var cachedExperimentSettings: SwiftyJSON.JSON = cachedExperimentRowDictValue["settings"]
        if let settingsDict: SwiftyJSON.JSON = cachedExperimentSettings {
          cachedExperiment.settings = SessionSetupSettings.parseFromJson(settingsJSON: settingsDict)
        }
        
        parsedObject.append(cachedExperiment)
      }
    }
    
    return parsedObject;
  }
  
  public static func parseToDict(cachedExperimentsObjects: [UTECachedExperiment]) -> [[String: Any]] {
    var collection = [[String: Any]]()
    
    for cachedExperimentObject: UTECachedExperiment in cachedExperimentsObjects {
      collection.append(cachedExperimentObject.toDict())
    }
    
    return collection
  }
}
