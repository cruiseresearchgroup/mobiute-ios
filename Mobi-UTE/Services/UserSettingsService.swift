//
//  UserSettingsService.swift
//  UserSettingsService
//
//  Created by Jonathan Liono on 12/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import SwiftyJSON

class UserSettingsService {
  class var sharedInstance: UserSettingsService {
    struct Singleton {
      static let instance = UserSettingsService()
    }
    
    return Singleton.instance
  }
  
  let defaultUserDefaults: UserDefaults;
  
  static let DB_FOLDER_PATH: String = "/temp/sessions/"
  
  static let RETRIEVAL_LIMIT_FOR_SENDING_INFOSESSION: Int = 1000
  static let RETRIEVAL_LIMIT_FOR_SENDING_BLUETOOTHINFO: Int = 5000
  static let RETRIEVAL_LIMIT_FOR_SENDING_INTERVALLABELS: Int = 1000
  
  private let KEY_SETTINGS_BASE_SERVER_URL: String = "SettingsBaseServerUrl"
  
  private let KEY_CURRENT_UNIQUE_ID_FOR_RECORDING: String = "CurrentUniqueIdForRecording"
  private let KEY_CURRENT_EXPERIMENT_ID: String = "CurrentExperimentId"
  private let KEY_CURRENT_EXPERIMENT_ALIAS: String = "CurrentExperimentAlias"
  private let KEY_CURRENT_SESSION_ID: String = "CurrentSessionId"
  private let KEY_CURRENT_SESSION_ROLE: String = "CurrentSessionRole"
  private let KEY_CURRENT_SESSION_IS_INITIATOR: String = "CurrentSessionDeviceIsInitiator"
  private let KEY_CURRENT_SESSION_SETTINGS: String = "CurrentSessionSettings"
  private let KEY_CURRENT_SESSION_SERVER_START_TIME: String = "SessionServerStartTime"
  private let KEY_CURRENT_SESSION_DEVICE_START_TIME: String = "SessionDeviceStartTime"
  private let KEY_CURRENT_SESSION_SESSION_INFO_CHUNK: String = "SessionInfoChunk"
  private let KEY_CURRENT_SESSION_SESSION_INFO_CHUNK_LAST_SEND: String = "SessionInfoChunkLASTSEND"
  private let KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTLABEL: String = "SessionIntervalLabelsCurrentLabel"
  private let KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTSTARTDATE: String = "SessionIntervalLabelsCurrentStartDate"
  
  private let KEY_SAVED_EXPERIMENT: String = "SavedOfflineExperiments"
  private let KEY_SAVED_RECORDING: String = "SessionSavedRecordings"

  init(){
    self.defaultUserDefaults = UserDefaults.standard;
  }
  
  func setCachedSessionInfo(uniqueId: String, experimentId: String, experimentAlias: String?, sessionId: String, serverStartTimeStamp: Double, settings: String?, role: Int, isInitiator: Bool) {
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_UNIQUE_ID_FOR_RECORDING) == nil {
      self.defaultUserDefaults.set(uniqueId, forKey: KEY_CURRENT_UNIQUE_ID_FOR_RECORDING)
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_EXPERIMENT_ID) == nil {
      self.defaultUserDefaults.set(experimentId, forKey: KEY_CURRENT_EXPERIMENT_ID)
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_EXPERIMENT_ALIAS) == nil {
      if let nonEmptyExperimentAlias = experimentAlias {
        self.defaultUserDefaults.set(nonEmptyExperimentAlias, forKey: KEY_CURRENT_EXPERIMENT_ALIAS)
      }
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_ID) == nil {
      self.defaultUserDefaults.set(sessionId, forKey: KEY_CURRENT_SESSION_ID)
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_SERVER_START_TIME) == nil {
      self.defaultUserDefaults.set(serverStartTimeStamp, forKey: KEY_CURRENT_SESSION_SERVER_START_TIME)
      self.defaultUserDefaults.set(DateTimeUtilities.getCurrentTimeStamp(), forKey: KEY_CURRENT_SESSION_DEVICE_START_TIME)
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_SETTINGS) == nil {
      if let settingsNotNil = settings {
        self.defaultUserDefaults.set(settingsNotNil, forKey: KEY_CURRENT_SESSION_SETTINGS)
      }
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_ROLE) == nil {
      self.defaultUserDefaults.set(role, forKey: KEY_CURRENT_SESSION_ROLE)
    }
    
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_IS_INITIATOR) == nil {
      self.defaultUserDefaults.set(isInitiator, forKey: KEY_CURRENT_SESSION_IS_INITIATOR)
    }
    
    self.defaultUserDefaults.synchronize()
  }
  
  func addSessionRecord(uniqueId: String, experimentId: String, experimentAlias: String?, sessionId: String?, dbpath: String, isOffline: Bool = false, isInitiator: Bool, createdAt: Double) {
    var recordings = self.getSessionRecords()
    let recording = UTESessionRecording()
    recording.unique_id = uniqueId
    recording.experiment_id = experimentId
    recording.experiment_alias = experimentAlias
    recording.session_id = sessionId
    recording.db_path = dbpath
    recording.is_offline = isOffline
    recording.is_initiator = isInitiator
    recording.created_at = createdAt
    recordings.append(recording)
    
    let recordingsDict: [[String: Any]] = UTESessionRecording.parseToDict(recordingObjects: recordings)
    
    do{
      //let data = try JSONSerialization.data(withJSONObject: recordingsDict, options: [])
      
      let recordingsString = SwiftyJSON.JSON(recordingsDict).rawString();
      
      self.defaultUserDefaults.set(recordingsString, forKey: KEY_SAVED_RECORDING)
      
      self.defaultUserDefaults.synchronize()
    } catch {
      // No-op
    }
  }
  
  func getSessionRecords() -> [UTESessionRecording] {
    var recordings = [UTESessionRecording]()
    
    let recordinglist: String? = self.defaultUserDefaults.string(forKey: KEY_SAVED_RECORDING)
    if let recordinglistNotNil = recordinglist {
      if let dataFromString = recordinglistNotNil.data(using: String.Encoding.utf8, allowLossyConversion: false) {
        let json = SwiftyJSON.JSON(data: dataFromString);
        recordings = UTESessionRecording.parseFromJson(recordingsJson: json)
      }
    }

    return recordings
  }
  
  func deleteSessionRecordSynced(uniqueId: String) {
    var recordings = self.getSessionRecords()
    
    recordings = recordings.filter{
      uniqueId.caseInsensitiveCompare($0.unique_id!) != ComparisonResult.orderedSame
    }
    
    let recordingsDict: [[String: Any]] = UTESessionRecording.parseToDict(recordingObjects: recordings)
    let recordingsString = SwiftyJSON.JSON(recordingsDict).rawString();
    
    self.defaultUserDefaults.set(recordingsString, forKey: KEY_SAVED_RECORDING)
    
    self.defaultUserDefaults.synchronize()
  }
  
  func updateSessionRecordSynced(uniqueId: String, sessionIdForUpdate: String) {
    if sessionIdForUpdate.isEmpty {
      return
    }
    
    let recordings = self.getSessionRecords()
    
    for recording in recordings {
      let foundRecording: Bool = uniqueId.caseInsensitiveCompare(recording.unique_id!) == ComparisonResult.orderedSame
      if foundRecording {
        recording.session_id = sessionIdForUpdate
        break
      }
    }
    
    let recordingsDict: [[String: Any]] = UTESessionRecording.parseToDict(recordingObjects: recordings)
    let recordingsString = SwiftyJSON.JSON(recordingsDict).rawString();
    
    self.defaultUserDefaults.set(recordingsString, forKey: KEY_SAVED_RECORDING)
    
    self.defaultUserDefaults.synchronize()
  }
  
  func clearCachedSessionInfo() {
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_UNIQUE_ID_FOR_RECORDING)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_EXPERIMENT_ID)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_EXPERIMENT_ALIAS)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_ID)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_ROLE)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_IS_INITIATOR)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_SETTINGS)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_SERVER_START_TIME)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_DEVICE_START_TIME)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK_LAST_SEND)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTLABEL)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTSTARTDATE)
    self.defaultUserDefaults.synchronize();
  }
  
  func getCurrentUniqueIdOfRecording() -> String? {
    return self.defaultUserDefaults.string(forKey: KEY_CURRENT_UNIQUE_ID_FOR_RECORDING);
  }
  
  func getCurrentExperimentId() -> String? {
    return self.defaultUserDefaults.string(forKey: KEY_CURRENT_EXPERIMENT_ID);
  }
  
  func getCurrentExperimentAlias() -> String? {
    return self.defaultUserDefaults.string(forKey: KEY_CURRENT_EXPERIMENT_ALIAS);
  }
  
  func getCurrentSessionId() -> String? {
    return self.defaultUserDefaults.string(forKey: KEY_CURRENT_SESSION_ID);
  }
  
  func getCurrentSessionSettings() -> SessionSetupSettings? {
    let settingsString: String? = self.defaultUserDefaults.string(forKey: KEY_CURRENT_SESSION_SETTINGS);
    if let settingsStringNotNil = settingsString {
      if let dataFromString = settingsStringNotNil.data(using: String.Encoding.utf8, allowLossyConversion: false) {
        let json = SwiftyJSON.JSON(data: dataFromString);
        return SessionSetupSettings.parseFromJson(settingsJSON: json)
      }
    }
    
    return  nil;
  }
  
  func getCurrentSessionRole() -> Int? {
    return self.defaultUserDefaults.integer(forKey: KEY_CURRENT_SESSION_ROLE)
  }
  
  func getCurrentSessionIsDeviceInitiator() -> Bool {
    return self.defaultUserDefaults.bool(forKey: KEY_CURRENT_SESSION_IS_INITIATOR)
  }
  
  func getCachedStartTimestamp() -> Double? {
    return self.defaultUserDefaults.double(forKey: KEY_CURRENT_SESSION_SERVER_START_TIME)
  }
  
  func setCachedSessionInfoChunk(shouldCache: Bool) {
    if self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK) == nil {
      self.defaultUserDefaults.set(shouldCache, forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK)
    }
    self.defaultUserDefaults.synchronize()
  }
  
  func clearCachedSessionInfoChunk() {
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK)
    self.defaultUserDefaults.synchronize()
  }
  
  func setCachedSessionInfoChunkLastSend(timestamp: Double) {
    self.defaultUserDefaults.set(timestamp, forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK_LAST_SEND);
    self.defaultUserDefaults.synchronize();
  }
  
  func getCachedSessionInfoChunk() -> Bool {
    return self.defaultUserDefaults.bool(forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK);
  }
  
  func getCachedSessionInfoChunkLASTSEND() -> Double? {
    return self.defaultUserDefaults.object(forKey: KEY_CURRENT_SESSION_SESSION_INFO_CHUNK_LAST_SEND) as! Double?;
  }
  
  func setCachedSessionIntervalLabelsCurrentLabel(label: String) {
    self.defaultUserDefaults.set(label, forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTLABEL);
    self.defaultUserDefaults.synchronize();
  }
  
  func getCachedSessionIntervalLabelsCurrentLabel() -> String? {
    return self.defaultUserDefaults.string(forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTLABEL)
  }
  
  func setCachedSessionIntervalLabelsCurrentStartDate(timestamp: Double) {
    self.defaultUserDefaults.set(timestamp, forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTSTARTDATE);
    self.defaultUserDefaults.synchronize();
  }
  
  func getCachedSessionIntervalLabelsCurrentStartDate() -> Double? {
    return self.defaultUserDefaults.double(forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTSTARTDATE)
  }
  
  func clearCachedSessionIntervalLabels() {
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTLABEL)
    self.defaultUserDefaults.removeObject(forKey: KEY_CURRENT_SESSION_INTERVAL_LABELS_CURRENTSTARTDATE)
    self.defaultUserDefaults.synchronize()
  }
  
  func getSynchronizedCurrentTimeStamp() -> Double {
    
    let currentDeviceTimestamp = DateTimeUtilities.getCurrentTimeStamp();
    
    let storedSessionServerTime = defaultUserDefaults.double(forKey: KEY_CURRENT_SESSION_SERVER_START_TIME);
    let storedSessionDeviceTime = defaultUserDefaults.double(forKey: KEY_CURRENT_SESSION_DEVICE_START_TIME);
    if(storedSessionServerTime != 0 && storedSessionDeviceTime != 0) {
      let delta = storedSessionServerTime - storedSessionDeviceTime;
      let currentServerTimestamp = currentDeviceTimestamp + delta;
      return currentServerTimestamp;
    }
    else {
      return currentDeviceTimestamp;
    }
  }
  
  func getSettingsBaseServerUrl() -> String? {
    return self.defaultUserDefaults.string(forKey: KEY_SETTINGS_BASE_SERVER_URL);
  }
  
  func setSettingsBaseServerUrl(baseServerUrl: String?) {
    if let baseServerUrlNotNil = baseServerUrl {
      self.defaultUserDefaults.set(baseServerUrlNotNil, forKey: KEY_SETTINGS_BASE_SERVER_URL)
    } else {
      self.defaultUserDefaults.removeObject(forKey: KEY_SETTINGS_BASE_SERVER_URL)
    }
    
    self.defaultUserDefaults.synchronize()
  }
  
  // MARK: experiment caching
  func getCachedExperiments() -> [UTECachedExperiment] {
    var cachedexperiments = [UTECachedExperiment]()
    var tempexperiments = [UTECachedExperiment]()
    
    let experimentlist: String? = self.defaultUserDefaults.string(forKey: KEY_SAVED_EXPERIMENT)
    if let experimentlistNotNil = experimentlist {
      if let dataFromString = experimentlistNotNil.data(using: String.Encoding.utf8, allowLossyConversion: false) {
        let json = SwiftyJSON.JSON(data: dataFromString);
        tempexperiments = UTECachedExperiment.parseFromJson(cachedExperimentJson: json)
      }
    }
    
    // filter out expired experiments
    for exp in tempexperiments {
      if let expiry = exp.campaign_end_at {
        let currentTime = DateTimeUtilities.getCurrentTimeStamp()
        if expiry > currentTime {
          cachedexperiments.append(exp)
        }
      } else {
        cachedexperiments.append(exp)
      }
    }
    
    return cachedexperiments
  }
  
  func findCachedExperimentById(experimentId: String) -> UTECachedExperiment? {
    var cachedexperiments: [UTECachedExperiment] = self.getCachedExperiments()
    cachedexperiments = cachedexperiments.filter {
      $0.uid != nil &&
        $0.experiment_id != nil &&
        $0.experiment_id == experimentId
    }
    
    if cachedexperiments.count == 1 {
      return cachedexperiments.first
    }
    
    return nil
  }
  
  func cacheExperiment(cache: UTECachedExperiment) -> Bool {
    
    if let experimentId = cache.experiment_id {
      var cachedexperiments = self.getCachedExperiments()
      
      // check if uid already exists in the cache.
      let exists = (cachedexperiments.filter { $0.uid != nil && cache.uid != nil && $0.uid == cache.uid! }).isEmpty == false
      if exists {
        // The entry exists in the cached experiment, remove the old cache
        cachedexperiments = self.uncacheExperimentFromCollection(experimentId: experimentId)
      }
      
      cachedexperiments.append(cache)
      let cachedexperimentsDict: [[String: Any]] = UTECachedExperiment.parseToDict(cachedExperimentsObjects: cachedexperiments)
      
      do{
        let cachedExperimentString = SwiftyJSON.JSON(cachedexperimentsDict).rawString();
        
        self.defaultUserDefaults.set(cachedExperimentString, forKey: KEY_SAVED_EXPERIMENT)
        
        self.defaultUserDefaults.synchronize()
        return true
      } catch {
        // No-op
      }
    }
    
    return false
  }
  
  func uncacheExperimentFromCollection(experimentId: String) -> [UTECachedExperiment] {
    var cachedexperiments = self.getCachedExperiments()
    
    cachedexperiments = cachedexperiments.filter{
      $0.experiment_id != nil &&
        experimentId.caseInsensitiveCompare($0.experiment_id!) != ComparisonResult.orderedSame
    }
    
    return cachedexperiments
  }
  
  func uncacheExperimentSynced(experimentId: String) {
    let cachedexperiments = self.uncacheExperimentFromCollection(experimentId: experimentId)
    let cachedExperimentsDict: [[String: Any]] = UTECachedExperiment.parseToDict(cachedExperimentsObjects: cachedexperiments)
    let cachedExperimentsString = SwiftyJSON.JSON(cachedExperimentsDict).rawString();
    
    self.defaultUserDefaults.set(cachedExperimentsString, forKey: KEY_SAVED_EXPERIMENT)
    
    self.defaultUserDefaults.synchronize()
  }
}
