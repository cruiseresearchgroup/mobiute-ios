//
//  UTESessionRecording.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 23/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation
import SwiftyJSON

public class UTESessionRecording : NSObject {
  public var created_at: Double?
  public var unique_id: String?
  public var experiment_id: String?
  public var experiment_alias: String?
  public var session_id: String?
  public var db_path: String?
  public var is_offline: Bool = false
  public var is_initiator: Bool = false
  public var otp: String?
  
  public static func parseToDict(recordingObjects: [UTESessionRecording]) -> [[String: Any]] {
    var collection = [[String: Any]]()
    
    for recording: UTESessionRecording in recordingObjects {
      var dict: [String: Any] = [String: Any]()
      if let createdAt = recording.created_at{
        dict["created_at"] = createdAt
      }
      
      if let uniqueId = recording.unique_id{
        dict["unique_id"] = uniqueId
      }
      
      if let experimentId = recording.experiment_id {
        dict["experiment_id"] = experimentId
      }
      
      if let experimentAlias = recording.experiment_alias {
        dict["experiment_alias"] = experimentAlias
      }
      
      if let sessionId = recording.session_id {
        dict["session_id"] = sessionId
      }
      
      if let dbPath = recording.db_path {
        dict["db_path"] =  dbPath
      }
      
      dict["is_offline"] = recording.is_offline
      dict["is_initiator"] = recording.is_initiator
      
      if let otp = recording.otp {
        dict["otp"] = otp
      }
      
      collection.append(dict)
    }
    
    return collection
  }
  
  public static func parseFromJson(recordingsJson: SwiftyJSON.JSON) -> [UTESessionRecording] {
    var parsedObject: [UTESessionRecording] = [UTESessionRecording]()
    if let recordingrow = recordingsJson.array {
      for recordingrowDictValue: SwiftyJSON.JSON in recordingrow {
        let recording: UTESessionRecording = UTESessionRecording()
        recording.created_at = recordingrowDictValue["created_at"].double;
        recording.unique_id = recordingrowDictValue["unique_id"].string;
        recording.experiment_id = recordingrowDictValue["experiment_id"].string;
        recording.experiment_alias = recordingrowDictValue["experiment_alias"].string;
        recording.session_id = recordingrowDictValue["session_id"].string;
        recording.db_path = recordingrowDictValue["db_path"].string;
        recording.is_offline = recordingrowDictValue["is_offline"].boolValue
        recording.is_initiator = recordingrowDictValue["is_initiator"].boolValue
        recording.otp = recordingrowDictValue["otp"].string
        
        parsedObject.append(recording)
      }
    }
    
    return parsedObject;
  }
}
