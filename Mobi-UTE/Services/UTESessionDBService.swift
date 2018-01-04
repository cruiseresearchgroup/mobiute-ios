//
//  UTESessionDBService.swift
//  UTESessionDBService
//
//  Created by Jonathan Liono on 3/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import UIKit

public class UTESessionDBService {
  let VERSION: UInt32 = 1;
  
  private var dbPath: URL;
  private var db: FMDatabase;
  
  private var experimentId: String?;
  private var sessionId: String?;
  
  func getDbPath() -> URL {
    return self.dbPath;
  }
  
  func destroyDB() -> NSError? {
    var error: NSError?;
    let fileManager = FileManager.default;
    var success: Bool
    do {
      try fileManager.removeItem(at: self.dbPath as URL)
      success = true
    } catch let error1 as NSError {
      error = error1
      success = false
    };
    if(!success) {
      NSLog("Error deleting DB: %@", [error!.localizedDescription]);
    }
    return error;
  }
  
  init (path: String, filename: String, experimentId: String, sessionId: String){
    self.experimentId = experimentId;
    self.sessionId = sessionId;
    //var dbPath: NSString = path;
    _ = FileManager.SearchPathDirectory.documentDirectory
    _ = FileManager.SearchPathDomainMask.userDomainMask
    let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    
    // doc dir
    let directoryPath = documentsPath.appendingPathComponent(path);
    self.dbPath = documentsPath.appendingPathComponent(path + filename);
    
    let fileManager = FileManager.default;
    var error: NSError?;
    var success: Bool
    do {
      try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
      success = true
    } catch let error1 as NSError {
      error = error1
      success = false
    };
    if (!success) {
      NSLog("Error creating data path: %@", [error!.localizedDescription]);
    }
    
    if (!fileManager.fileExists(atPath: self.dbPath.path)) {
      //var fromPath = NSBundle.mainBundle().pathForResource("default", ofType: "sqlite");
      let defaultSqliteFileName = "default.sqlite";
      let fromPath: URL = (Bundle.main.resourceURL?.appendingPathComponent(defaultSqliteFileName))!;
      let fromPathExist = fileManager.fileExists(atPath: fromPath.path);
      if fromPathExist {
        var copysuccess: Bool
        do {
          try fileManager.copyItem(at: fromPath as URL, to: self.dbPath as URL)
          copysuccess = true
        } catch let error1 as NSError {
          error = error1
          copysuccess = false
        };
        if(!copysuccess) {
          NSLog("Error copying default SQLite file: %@", [error!.localizedDescription]);
        }
      }
    }

    self.db = FMDatabase(path: dbPath.path);
    let opensuccessfully = self.db.open();
    if (!opensuccessfully) {
      return;
    }
    
    self.runMigration();
    
    self.db.close();
  }
  
  private func runMigration() {
    self.migrate(version: self.currentDbVersion());
  }
  
  private static let SQLITE_TABLE_NAME_SENSOR_INFOS: String = "sensor_infos"
  private static let SQLITE_TABLE_NAME_BLUETOOTH_INFOS: String = "bluetooth_infos"
  private static let SQLITE_TABLE_NAME_SENSOR_INTERVAL_LABELS: String = "sensor_interval_labels"
  
  private static let SQLITE_COLUMN_NAME_SESSIONID_FOR_DB_DEFINITIONS: String = "session_id"
  private static let SQLITE_COLUMN_NAME_EXPERIMENTCODE_FOR_DB_DEFINITIONS: String = "experiment_code"
  
  private func migrate(version: UInt32) {
    switch (version) {
    case 0:
      self.db.executeUpdate("CREATE TABLE IF NOT EXISTS " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INFOS + " (id integer primary key autoincrement, accelerometer_acceleration_x REAL, accelerometer_acceleration_y REAL, accelerometer_acceleration_z REAL, motion_gravity_x REAL, motion_gravity_y REAL, motion_gravity_z REAL, motion_user_acceleration_x REAL, motion_user_acceleration_y REAL, motion_user_acceleration_z REAL, motion_attitude_yaw REAL, motion_attitude_pitch REAL, motion_attitude_roll REAL, gyroscope_rotationrate_x REAL, gyroscope_rotationrate_y REAL, gyroscope_rotationrate_z REAL, motion_rotationrate_x REAL, motion_rotationrate_y REAL, motion_rotationrate_z REAL, magnetic_heading_x REAL, magnetic_heading_y REAL, magnetic_heading_z REAL, calibrated_magnetic_field_x REAL, calibrated_magnetic_field_y REAL, calibrated_magnetic_field_z REAL, calibrated_magnetic_field_accuracy REAL, magnetometer_x REAL, magnetometer_y REAL, magnetometer_z REAL, location_latitude REAL, location_longitude REAL, gps_accuracy REAL, gps_speed REAL, noise_level REAL, pressure REAL, altitude REAL, logged_at REAL DEFAULT CURRENT_TIMESTAMP NOT NULL)", withArgumentsIn:nil)
      self.db.executeUpdate("CREATE TABLE IF NOT EXISTS " + UTESessionDBService.SQLITE_TABLE_NAME_BLUETOOTH_INFOS + " (id integer primary key autoincrement, uuid TEXT, name TEXT, rssi REAL, logged_at REAL DEFAULT CURRENT_TIMESTAMP NOT NULL)", withArgumentsIn:nil)
      self.db.executeUpdate("CREATE TABLE IF NOT EXISTS " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INFOS + " (id integer primary key autoincrement, accelerometer_acceleration_x REAL, accelerometer_acceleration_y REAL, accelerometer_acceleration_z REAL, motion_gravity_x REAL, motion_gravity_y REAL, motion_gravity_z REAL, motion_user_acceleration_x REAL, motion_user_acceleration_y REAL, motion_user_acceleration_z REAL, motion_attitude_yaw REAL, motion_attitude_pitch REAL, motion_attitude_roll REAL, gyroscope_rotationrate_x REAL, gyroscope_rotationrate_y REAL, gyroscope_rotationrate_z REAL, motion_rotationrate_x REAL, motion_rotationrate_y REAL, motion_rotationrate_z REAL, magnetic_heading_x REAL, magnetic_heading_y REAL, magnetic_heading_z REAL, calibrated_magnetic_field_x REAL, calibrated_magnetic_field_y REAL, calibrated_magnetic_field_z REAL, calibrated_magnetic_field_accuracy REAL, magnetometer_x REAL, magnetometer_y REAL, magnetometer_z REAL, location_latitude REAL, location_longitude REAL, gps_accuracy REAL, gps_speed REAL, noise_level REAL, pressure REAL, altitude REAL, logged_at REAL DEFAULT CURRENT_TIMESTAMP NOT NULL)", withArgumentsIn:nil)
      
      self.db.executeUpdate("CREATE INDEX index_logged_at ON " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INFOS + " (logged_at);", withArgumentsIn:nil);
      self.db.executeUpdate("CREATE TABLE IF NOT EXISTS " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INTERVAL_LABELS + "(id integer primary key autoincrement, start_date REAL NOT NULL, end_date REAL NOT NULL, labels TEXT);", withArgumentsIn:nil);
      self.db.executeUpdate("CREATE INDEX index_start_date ON " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INTERVAL_LABELS + " (start_date);", withArgumentsIn:nil);
      
      self.db.executeUpdate("CREATE TABLE IF NOT EXISTS db_definitions (id integer primary key autoincrement, name TEXT, value TEXT, data_type TEXT);", withArgumentsIn:nil);
      
      self.db.executeUpdate("INSERT INTO db_definitions (name, value, data_type) VALUES ('" + UTESessionDBService.SQLITE_COLUMN_NAME_SESSIONID_FOR_DB_DEFINITIONS + "', '" + self.sessionId! + "', 'string');", withArgumentsIn:nil);
      
      self.db.executeUpdate("INSERT INTO db_definitions (name, value, data_type) VALUES ('" + UTESessionDBService.SQLITE_COLUMN_NAME_EXPERIMENTCODE_FOR_DB_DEFINITIONS + "', '" + self.experimentId! + "', 'string');", withArgumentsIn:nil);
      
      // db.lastErrorMessage()
      break;
    default: break;
    }
    
    let updatedVersion = version + 1;
    self.db.setUserVersion(updatedVersion);
    if(updatedVersion < self.VERSION) {
      self.migrate(version: updatedVersion);
    }
  }
  
  private func currentDbVersion() -> UInt32 {
    return self.db.userVersion();
  }
  
  // MARK: visible DB Operation.
  func updateSessionId(sessionId: String) {
    self.sessionId = sessionId
    self.db.open();
    self.db.executeUpdate("UPDATE db_definitions SET value = ? WHERE name = ?;", withArgumentsIn: [
      sessionId,
      UTESessionDBService.SQLITE_COLUMN_NAME_SESSIONID_FOR_DB_DEFINITIONS
    ]);
    self.db.close();
  }
  
  func insertSessionInfo(sensorInfo: UTEModelSensorInfo) {
    self.db.open();
    
    var params = [String:AnyObject]()
      params["accelerometer_acceleration_x"] = self.convertToNSNumber(value: sensorInfo.accelerometer_acceleration_x)
      params["accelerometer_acceleration_y"] = self.convertToNSNumber(value: sensorInfo.accelerometer_acceleration_y)
      params["accelerometer_acceleration_z"] = self.convertToNSNumber(value: sensorInfo.accelerometer_acceleration_z)
      params["motion_gravity_x"] = self.convertToNSNumber(value: sensorInfo.motion_gravity_x)
      params["motion_gravity_y"] = self.convertToNSNumber(value: sensorInfo.motion_gravity_y)
      params["motion_gravity_z"] = self.convertToNSNumber(value: sensorInfo.motion_gravity_z)
      params["motion_user_acceleration_x"] = self.convertToNSNumber(value: sensorInfo.motion_user_acceleration_x)
      params["motion_user_acceleration_y"] = self.convertToNSNumber(value: sensorInfo.motion_user_acceleration_y)
      params["motion_user_acceleration_z"] = self.convertToNSNumber(value: sensorInfo.motion_user_acceleration_z)
      params["motion_attitude_yaw"] = self.convertToNSNumber(value: sensorInfo.motion_attitude_yaw)
      params["motion_attitude_pitch"] = self.convertToNSNumber(value: sensorInfo.motion_attitude_pitch)
      params["motion_attitude_roll"] = self.convertToNSNumber(value: sensorInfo.motion_attitude_roll)
      params["gyroscope_rotationrate_x"] = self.convertToNSNumber(value: sensorInfo.gyroscope_rotationrate_x)
      params["gyroscope_rotationrate_y"] = self.convertToNSNumber(value: sensorInfo.gyroscope_rotationrate_y)
      params["gyroscope_rotationrate_z"] = self.convertToNSNumber(value: sensorInfo.gyroscope_rotationrate_z)
      params["motion_rotationrate_x"] = self.convertToNSNumber(value: sensorInfo.motion_rotationrate_x)
      params["motion_rotationrate_y"] = self.convertToNSNumber(value: sensorInfo.motion_rotationrate_y)
      params["motion_rotationrate_z"] = self.convertToNSNumber(value: sensorInfo.motion_rotationrate_z)
      params["magnetic_heading_x"] = self.convertToNSNumber(value: sensorInfo.magnetic_heading_x)
      params["magnetic_heading_y"] = self.convertToNSNumber(value: sensorInfo.magnetic_heading_y)
      params["magnetic_heading_z"] = self.convertToNSNumber(value: sensorInfo.magnetic_heading_z)
      params["calibrated_magnetic_field_x"] = self.convertToNSNumber(value: sensorInfo.calibrated_magnetic_field_x)
      params["calibrated_magnetic_field_y"] = self.convertToNSNumber(value: sensorInfo.calibrated_magnetic_field_y)
      params["calibrated_magnetic_field_z"] = self.convertToNSNumber(value: sensorInfo.calibrated_magnetic_field_z)
      params["calibrated_magnetic_field_accuracy"] = self.convertToNSNumber(value: sensorInfo.calibrated_magnetic_field_accuracy)
      params["magnetometer_x"] = self.convertToNSNumber(value: sensorInfo.magnetometer_x)
      params["magnetometer_y"] = self.convertToNSNumber(value: sensorInfo.magnetometer_y)
      params["magnetometer_z"] = self.convertToNSNumber(value: sensorInfo.magnetometer_z)
      params["location_latitude"] = self.convertToNSNumber(value: sensorInfo.location_latitude)
      params["location_longitude"] = self.convertToNSNumber(value: sensorInfo.location_longitude)
      params["gps_accuracy"] = self.convertToNSNumber(value: sensorInfo.location_accuracy)
      params["gps_speed"] = self.convertToNSNumber(value: sensorInfo.gps_speed)
      params["noise_level"] = self.convertToNSNumber(value: sensorInfo.noise_level)
      params["pressure"] = self.convertToNSNumber(value: sensorInfo.pressure)
      params["altitude"] = self.convertToNSNumber(value: sensorInfo.altitude)
      params["logged_at"] = self.convertToNSNumber(value: sensorInfo.timestamp)
    
    self.db.executeUpdate("INSERT INTO sensor_infos (accelerometer_acceleration_x, accelerometer_acceleration_y, accelerometer_acceleration_z, motion_gravity_x, motion_gravity_y, motion_gravity_z, motion_user_acceleration_x, motion_user_acceleration_y, motion_user_acceleration_z, motion_attitude_yaw, motion_attitude_pitch, motion_attitude_roll, gyroscope_rotationrate_x, gyroscope_rotationrate_y, gyroscope_rotationrate_z, motion_rotationrate_x, motion_rotationrate_y, motion_rotationrate_z, magnetic_heading_x, magnetic_heading_y, magnetic_heading_z, calibrated_magnetic_field_x, calibrated_magnetic_field_y, calibrated_magnetic_field_z, calibrated_magnetic_field_accuracy, magnetometer_x, magnetometer_y, magnetometer_z, location_latitude, location_longitude, gps_accuracy, gps_speed, noise_level, pressure, altitude, logged_at) VALUES (:accelerometer_acceleration_x, :accelerometer_acceleration_y, :accelerometer_acceleration_z, :motion_gravity_x, :motion_gravity_y, :motion_gravity_z, :motion_user_acceleration_x, :motion_user_acceleration_y, :motion_user_acceleration_z, :motion_attitude_yaw, :motion_attitude_pitch, :motion_attitude_roll, :gyroscope_rotationrate_x, :gyroscope_rotationrate_y, :gyroscope_rotationrate_z, :motion_rotationrate_x, :motion_rotationrate_y, :motion_rotationrate_z, :magnetic_heading_x, :magnetic_heading_y, :magnetic_heading_z, :calibrated_magnetic_field_x, :calibrated_magnetic_field_y, :calibrated_magnetic_field_z, :calibrated_magnetic_field_accuracy, :magnetometer_x, :magnetometer_y, :magnetometer_z, :location_latitude, :location_longitude, :gps_accuracy, :gps_speed, :noise_level, :pressure, :altitude, :logged_at);", withParameterDictionary: params);
    
    self.db.close();
  }
  
  func insertBluetoothInfo(bluetoothInfo: UTEModelBluetoothInfo) {
    self.db.open();
    
    var params = [String:AnyObject]()
    params["uuid"] = bluetoothInfo.uuid as AnyObject?
    params["name"] = bluetoothInfo.name as AnyObject?
    params["rssi"] = self.convertToNSNumber(value: bluetoothInfo.rssi)
    params["logged_at"] = self.convertToNSNumber(value: bluetoothInfo.timestamp)
    
    self.db.executeUpdate("INSERT INTO bluetooth_infos (uuid, name, rssi, logged_at) VALUES (:uuid, :name, :rssi, :logged_at);", withParameterDictionary: params);
    
    self.db.close();
  }
  
  func insertSensorIntervalLabel(intervalLabels: UTEModelIntervalLabels) {
    self.db.open();
    
    var params = [String:AnyObject]()
    params["start_date"] = self.convertToNSNumber(value: intervalLabels.start_date)
    params["end_date"] = self.convertToNSNumber(value: intervalLabels.end_date)
    params["labels"] = intervalLabels.labels as AnyObject?? ?? NSNull()
    
    self.db.executeUpdate("INSERT INTO " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INTERVAL_LABELS + " (start_date, end_date, labels) VALUES (:start_date, :end_date, :labels);", withParameterDictionary: params);
    
    self.db.close();
  }
  
  func fetchSessionInfos<T:AnyObject>(type: T.Type) -> [T] {
    var results: [T] = [];
    self.db.open();
    let rs: FMResultSet? = self.db.executeQuery("SELECT * FROM sensor_infos ORDER BY logged_at", withArgumentsIn: []);
    if(rs == nil) {
      return results;
    }
    
    while (rs!.next()) {
      let sensorInfo = UTEModelSensorInfo();
      sensorInfo.accelerometer_acceleration_x = rs!.columnIsNull("accelerometer_acceleration_x") ? nil : rs!.double(forColumn: "accelerometer_acceleration_x");
      sensorInfo.accelerometer_acceleration_y = rs!.columnIsNull("accelerometer_acceleration_y") ? nil : rs!.double(forColumn: "accelerometer_acceleration_y");
      sensorInfo.accelerometer_acceleration_z = rs!.columnIsNull("accelerometer_acceleration_z") ? nil : rs!.double(forColumn: "accelerometer_acceleration_z");
      sensorInfo.motion_gravity_x = rs!.columnIsNull("motion_gravity_x") ? nil : rs!.double(forColumn: "motion_gravity_x");
      sensorInfo.motion_gravity_y = rs!.columnIsNull("motion_gravity_y") ? nil : rs!.double(forColumn: "motion_gravity_y");
      sensorInfo.motion_gravity_z = rs!.columnIsNull("motion_gravity_z") ? nil : rs!.double(forColumn: "motion_gravity_z");
      sensorInfo.motion_user_acceleration_x = rs!.columnIsNull("motion_user_acceleration_x") ? nil : rs!.double(forColumn: "motion_user_acceleration_x");
      sensorInfo.motion_user_acceleration_y = rs!.columnIsNull("motion_user_acceleration_y") ? nil : rs!.double(forColumn: "motion_user_acceleration_y");
      sensorInfo.motion_user_acceleration_z = rs!.columnIsNull("motion_user_acceleration_z") ? nil : rs!.double(forColumn: "motion_user_acceleration_z");
      sensorInfo.motion_attitude_yaw = rs!.columnIsNull("motion_attitude_yaw") ? nil : rs!.double(forColumn: "motion_attitude_yaw");
      sensorInfo.motion_attitude_pitch = rs!.columnIsNull("motion_attitude_pitch") ? nil : rs!.double(forColumn: "motion_attitude_pitch");
      sensorInfo.motion_attitude_roll = rs!.columnIsNull("motion_attitude_roll") ? nil : rs!.double(forColumn: "motion_attitude_roll");
      sensorInfo.gyroscope_rotationrate_x = rs!.columnIsNull("gyroscope_rotationrate_x") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_x");
      sensorInfo.gyroscope_rotationrate_y = rs!.columnIsNull("gyroscope_rotationrate_y") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_y");
      sensorInfo.gyroscope_rotationrate_z = rs!.columnIsNull("gyroscope_rotationrate_z") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_z");
      sensorInfo.motion_rotationrate_x = rs!.columnIsNull("motion_rotationrate_x") ? nil : rs!.double(forColumn: "motion_rotationrate_x");
      sensorInfo.motion_rotationrate_y = rs!.columnIsNull("motion_rotationrate_y") ? nil : rs!.double(forColumn: "motion_rotationrate_y");
      sensorInfo.motion_rotationrate_z = rs!.columnIsNull("motion_rotationrate_z") ? nil : rs!.double(forColumn: "motion_rotationrate_z");
      sensorInfo.magnetic_heading_x = rs!.columnIsNull("magnetic_heading_x") ? nil : rs!.double(forColumn: "magnetic_heading_x");
      sensorInfo.magnetic_heading_y = rs!.columnIsNull("magnetic_heading_y") ? nil : rs!.double(forColumn: "magnetic_heading_y");
      sensorInfo.magnetic_heading_z = rs!.columnIsNull("magnetic_heading_z") ? nil : rs!.double(forColumn: "magnetic_heading_z");
      sensorInfo.calibrated_magnetic_field_x = rs!.columnIsNull("calibrated_magnetic_field_x") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_x");
      sensorInfo.calibrated_magnetic_field_y = rs!.columnIsNull("calibrated_magnetic_field_y") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_y");
      sensorInfo.calibrated_magnetic_field_z = rs!.columnIsNull("calibrated_magnetic_field_z") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_z");
      sensorInfo.calibrated_magnetic_field_accuracy = rs!.columnIsNull("calibrated_magnetic_field_accuracy") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_accuracy");
      sensorInfo.magnetometer_x = rs!.columnIsNull("magnetometer_x") ? nil : rs!.double(forColumn: "magnetometer_x");
      sensorInfo.magnetometer_y = rs!.columnIsNull("magnetometer_y") ? nil : rs!.double(forColumn: "magnetometer_y");
      sensorInfo.magnetometer_z = rs!.columnIsNull("magnetometer_z") ? nil : rs!.double(forColumn: "magnetometer_z");
      sensorInfo.location_latitude = rs!.columnIsNull("location_latitude") ? nil : rs!.double(forColumn: "location_latitude");
      sensorInfo.location_longitude = rs!.columnIsNull("location_longitude") ? nil : rs!.double(forColumn: "location_longitude");
      sensorInfo.location_accuracy = rs!.columnIsNull("gps_accuracy") ? nil : rs!.double(forColumn: "gps_accuracy")
      sensorInfo.gps_speed = rs!.columnIsNull("gps_speed") ? nil : rs!.double(forColumn: "gps_speed");
      sensorInfo.noise_level = rs!.columnIsNull("noise_level") ? nil : rs!.double(forColumn: "noise_level")
      sensorInfo.pressure = rs!.columnIsNull("pressure") ? nil : rs!.double(forColumn: "pressure")
      sensorInfo.altitude = rs!.columnIsNull("altitude") ? nil : rs!.double(forColumn: "altitude")
      sensorInfo.timestamp = rs!.double(forColumn: "logged_at");
      //let isDictionaryType = T.self.isKindOfClass(NSDictionary.Type);
      let userRequestedType = NSStringFromClass(type);
      let nsdictType = NSStringFromClass(NSDictionary.self);
      let isDictionaryType = userRequestedType == nsdictType;
      if (isDictionaryType)
      {
        let jsonobject: [String: AnyObject] = sensorInfo.toJson()
        results.append(jsonobject as! T);
      }
      else{
        results.append(sensorInfo as! T);
      }
    }
    
    self.db.close();
    
    return results;
    
    /*var results: [T] = [];
    return results;*/
  }
  
  func fetchSessionInfosBefore(thetime: Double) -> [Dictionary<String, AnyObject>] {
    var results: [Dictionary<String, AnyObject>] = [];
    self.db.open();
    let rs: FMResultSet? = self.db.executeQuery("SELECT * FROM sensor_infos WHERE logged_at < ? ORDER BY logged_at", withArgumentsIn: [thetime]);
    if(rs == nil) {
      return results;
    }
    
    while (rs!.next()) {
      let sensorInfo = UTEModelSensorInfo();
      sensorInfo.accelerometer_acceleration_x = rs!.columnIsNull("accelerometer_acceleration_x") ? nil : rs!.double(forColumn: "accelerometer_acceleration_x");
      sensorInfo.accelerometer_acceleration_y = rs!.columnIsNull("accelerometer_acceleration_y") ? nil : rs!.double(forColumn: "accelerometer_acceleration_y");
      sensorInfo.accelerometer_acceleration_z = rs!.columnIsNull("accelerometer_acceleration_z") ? nil : rs!.double(forColumn: "accelerometer_acceleration_z");
      sensorInfo.motion_gravity_x = rs!.columnIsNull("motion_gravity_x") ? nil : rs!.double(forColumn: "motion_gravity_x");
      sensorInfo.motion_gravity_y = rs!.columnIsNull("motion_gravity_y") ? nil : rs!.double(forColumn: "motion_gravity_y");
      sensorInfo.motion_gravity_z = rs!.columnIsNull("motion_gravity_z") ? nil : rs!.double(forColumn: "motion_gravity_z");
      sensorInfo.motion_user_acceleration_x = rs!.columnIsNull("motion_user_acceleration_x") ? nil : rs!.double(forColumn: "motion_user_acceleration_x");
      sensorInfo.motion_user_acceleration_y = rs!.columnIsNull("motion_user_acceleration_y") ? nil : rs!.double(forColumn: "motion_user_acceleration_y");
      sensorInfo.motion_user_acceleration_z = rs!.columnIsNull("motion_user_acceleration_z") ? nil : rs!.double(forColumn: "motion_user_acceleration_z");
      sensorInfo.motion_attitude_yaw = rs!.columnIsNull("motion_attitude_yaw") ? nil : rs!.double(forColumn: "motion_attitude_yaw");
      sensorInfo.motion_attitude_pitch = rs!.columnIsNull("motion_attitude_pitch") ? nil : rs!.double(forColumn: "motion_attitude_pitch");
      sensorInfo.motion_attitude_roll = rs!.columnIsNull("motion_attitude_roll") ? nil : rs!.double(forColumn: "motion_attitude_roll");
      sensorInfo.gyroscope_rotationrate_x = rs!.columnIsNull("gyroscope_rotationrate_x") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_x");
      sensorInfo.gyroscope_rotationrate_y = rs!.columnIsNull("gyroscope_rotationrate_y") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_y");
      sensorInfo.gyroscope_rotationrate_z = rs!.columnIsNull("gyroscope_rotationrate_z") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_z");
      sensorInfo.motion_rotationrate_x = rs!.columnIsNull("motion_rotationrate_x") ? nil : rs!.double(forColumn: "motion_rotationrate_x");
      sensorInfo.motion_rotationrate_y = rs!.columnIsNull("motion_rotationrate_y") ? nil : rs!.double(forColumn: "motion_rotationrate_y");
      sensorInfo.motion_rotationrate_z = rs!.columnIsNull("motion_rotationrate_z") ? nil : rs!.double(forColumn: "motion_rotationrate_z");
      sensorInfo.magnetic_heading_x = rs!.columnIsNull("magnetic_heading_x") ? nil : rs!.double(forColumn: "magnetic_heading_x");
      sensorInfo.magnetic_heading_y = rs!.columnIsNull("magnetic_heading_y") ? nil : rs!.double(forColumn: "magnetic_heading_y");
      sensorInfo.magnetic_heading_z = rs!.columnIsNull("magnetic_heading_z") ? nil : rs!.double(forColumn: "magnetic_heading_z");
      sensorInfo.calibrated_magnetic_field_x = rs!.columnIsNull("calibrated_magnetic_field_x") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_x");
      sensorInfo.calibrated_magnetic_field_y = rs!.columnIsNull("calibrated_magnetic_field_y") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_y");
      sensorInfo.calibrated_magnetic_field_z = rs!.columnIsNull("calibrated_magnetic_field_z") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_z");
      sensorInfo.calibrated_magnetic_field_accuracy = rs!.columnIsNull("calibrated_magnetic_field_accuracy") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_accuracy");
      sensorInfo.magnetometer_x = rs!.columnIsNull("magnetometer_x") ? nil : rs!.double(forColumn: "magnetometer_x");
      sensorInfo.magnetometer_y = rs!.columnIsNull("magnetometer_y") ? nil : rs!.double(forColumn: "magnetometer_y");
      sensorInfo.magnetometer_z = rs!.columnIsNull("magnetometer_z") ? nil : rs!.double(forColumn: "magnetometer_z");
      sensorInfo.location_latitude = rs!.columnIsNull("location_latitude") ? nil : rs!.double(forColumn: "location_latitude");
      sensorInfo.location_longitude = rs!.columnIsNull("location_longitude") ? nil : rs!.double(forColumn: "location_longitude");
      sensorInfo.location_accuracy = rs!.columnIsNull("gps_accuracy") ? nil : rs!.double(forColumn: "gps_accuracy")
      sensorInfo.gps_speed = rs!.columnIsNull("gps_speed") ? nil : rs!.double(forColumn: "gps_speed");
      sensorInfo.noise_level = rs!.columnIsNull("noise_level") ? nil : rs!.double(forColumn: "noise_level")
      sensorInfo.pressure = rs!.columnIsNull("pressure") ? nil : rs!.double(forColumn: "pressure")
      sensorInfo.altitude = rs!.columnIsNull("altitude") ? nil : rs!.double(forColumn: "altitude")
      sensorInfo.timestamp = rs!.double(forColumn: "logged_at");
      
      results.append(sensorInfo.toJson());
    }
    
    self.db.close();
    
    return results;
  }
  
  func fetchSessionInfosByLimit(recordlimit: Int) -> [Dictionary<String, AnyObject>] {
    var results: [Dictionary<String, AnyObject>] = [];
    self.db.open();
    let rs: FMResultSet? = self.db.executeQuery("SELECT * FROM sensor_infos ORDER BY logged_at LIMIT ?", withArgumentsIn: [recordlimit]);
    if(rs == nil) {
      return results;
    }
    
    while (rs!.next()) {
      let sensorInfo = UTEModelSensorInfo();
      sensorInfo.accelerometer_acceleration_x = rs!.columnIsNull("accelerometer_acceleration_x") ? nil : rs!.double(forColumn: "accelerometer_acceleration_x");
      sensorInfo.accelerometer_acceleration_y = rs!.columnIsNull("accelerometer_acceleration_y") ? nil : rs!.double(forColumn: "accelerometer_acceleration_y");
      sensorInfo.accelerometer_acceleration_z = rs!.columnIsNull("accelerometer_acceleration_z") ? nil : rs!.double(forColumn: "accelerometer_acceleration_z");
      sensorInfo.motion_gravity_x = rs!.columnIsNull("motion_gravity_x") ? nil : rs!.double(forColumn: "motion_gravity_x");
      sensorInfo.motion_gravity_y = rs!.columnIsNull("motion_gravity_y") ? nil : rs!.double(forColumn: "motion_gravity_y");
      sensorInfo.motion_gravity_z = rs!.columnIsNull("motion_gravity_z") ? nil : rs!.double(forColumn: "motion_gravity_z");
      sensorInfo.motion_user_acceleration_x = rs!.columnIsNull("motion_user_acceleration_x") ? nil : rs!.double(forColumn: "motion_user_acceleration_x");
      sensorInfo.motion_user_acceleration_y = rs!.columnIsNull("motion_user_acceleration_y") ? nil : rs!.double(forColumn: "motion_user_acceleration_y");
      sensorInfo.motion_user_acceleration_z = rs!.columnIsNull("motion_user_acceleration_z") ? nil : rs!.double(forColumn: "motion_user_acceleration_z");
      sensorInfo.motion_attitude_yaw = rs!.columnIsNull("motion_attitude_yaw") ? nil : rs!.double(forColumn: "motion_attitude_yaw");
      sensorInfo.motion_attitude_pitch = rs!.columnIsNull("motion_attitude_pitch") ? nil : rs!.double(forColumn: "motion_attitude_pitch");
      sensorInfo.motion_attitude_roll = rs!.columnIsNull("motion_attitude_roll") ? nil : rs!.double(forColumn: "motion_attitude_roll");
      sensorInfo.gyroscope_rotationrate_x = rs!.columnIsNull("gyroscope_rotationrate_x") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_x");
      sensorInfo.gyroscope_rotationrate_y = rs!.columnIsNull("gyroscope_rotationrate_y") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_y");
      sensorInfo.gyroscope_rotationrate_z = rs!.columnIsNull("gyroscope_rotationrate_z") ? nil : rs!.double(forColumn: "gyroscope_rotationrate_z");
      sensorInfo.motion_rotationrate_x = rs!.columnIsNull("motion_rotationrate_x") ? nil : rs!.double(forColumn: "motion_rotationrate_x");
      sensorInfo.motion_rotationrate_y = rs!.columnIsNull("motion_rotationrate_y") ? nil : rs!.double(forColumn: "motion_rotationrate_y");
      sensorInfo.motion_rotationrate_z = rs!.columnIsNull("motion_rotationrate_z") ? nil : rs!.double(forColumn: "motion_rotationrate_z");
      sensorInfo.magnetic_heading_x = rs!.columnIsNull("magnetic_heading_x") ? nil : rs!.double(forColumn: "magnetic_heading_x");
      sensorInfo.magnetic_heading_y = rs!.columnIsNull("magnetic_heading_y") ? nil : rs!.double(forColumn: "magnetic_heading_y");
      sensorInfo.magnetic_heading_z = rs!.columnIsNull("magnetic_heading_z") ? nil : rs!.double(forColumn: "magnetic_heading_z");
      sensorInfo.calibrated_magnetic_field_x = rs!.columnIsNull("calibrated_magnetic_field_x") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_x");
      sensorInfo.calibrated_magnetic_field_y = rs!.columnIsNull("calibrated_magnetic_field_y") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_y");
      sensorInfo.calibrated_magnetic_field_z = rs!.columnIsNull("calibrated_magnetic_field_z") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_z");
      sensorInfo.calibrated_magnetic_field_accuracy = rs!.columnIsNull("calibrated_magnetic_field_accuracy") ? nil : rs!.double(forColumn: "calibrated_magnetic_field_accuracy");
      sensorInfo.magnetometer_x = rs!.columnIsNull("magnetometer_x") ? nil : rs!.double(forColumn: "magnetometer_x");
      sensorInfo.magnetometer_y = rs!.columnIsNull("magnetometer_y") ? nil : rs!.double(forColumn: "magnetometer_y");
      sensorInfo.magnetometer_z = rs!.columnIsNull("magnetometer_z") ? nil : rs!.double(forColumn: "magnetometer_z");
      sensorInfo.location_latitude = rs!.columnIsNull("location_latitude") ? nil : rs!.double(forColumn: "location_latitude");
      sensorInfo.location_longitude = rs!.columnIsNull("location_longitude") ? nil : rs!.double(forColumn: "location_longitude");
      sensorInfo.location_accuracy = rs!.columnIsNull("gps_accuracy") ? nil : rs!.double(forColumn: "gps_accuracy")
      sensorInfo.gps_speed = rs!.columnIsNull("gps_speed") ? nil : rs!.double(forColumn: "gps_speed");
      sensorInfo.noise_level = rs!.columnIsNull("noise_level") ? nil : rs!.double(forColumn: "noise_level")
      sensorInfo.pressure = rs!.columnIsNull("pressure") ? nil : rs!.double(forColumn: "pressure")
      sensorInfo.altitude = rs!.columnIsNull("altitude") ? nil : rs!.double(forColumn: "altitude")
      sensorInfo.timestamp = rs!.double(forColumn: "logged_at");
      
      results.append(sensorInfo.toJson());
    }
    
    self.db.close();
    
    return results;
  }
  
  func fetchBluetoothInfosByLimit(recordlimit: Int) -> [Dictionary<String, AnyObject>] {
    var results: [Dictionary<String, AnyObject>] = [];
    self.db.open();
    let rs: FMResultSet? = self.db.executeQuery("SELECT * FROM " + UTESessionDBService.SQLITE_TABLE_NAME_BLUETOOTH_INFOS + " ORDER BY id, logged_at LIMIT ?", withArgumentsIn: [recordlimit]);
    if(rs == nil) {
      return results;
    }
    
    while (rs!.next()) {
      let bluetoothInfo = UTEModelBluetoothInfo()
      bluetoothInfo.id = rs!.columnIsNull("id") ? nil : rs!.unsignedLongLongInt(forColumn: "id")
      bluetoothInfo.uuid = rs!.columnIsNull("uuid") ? nil : rs!.string(forColumn: "uuid")
      bluetoothInfo.name = rs!.columnIsNull("name") ? nil : rs!.string(forColumn: "name")
      bluetoothInfo.rssi = rs!.columnIsNull("rssi") ? nil : rs!.double(forColumn: "rssi")
      bluetoothInfo.timestamp = rs!.double(forColumn: "logged_at")
      
      results.append(bluetoothInfo.toJson());
    }
    
    self.db.close();
    
    return results;
  }
  
  func fetchSessionIntervalLabelsByLimit(recordlimit: Int) -> [Dictionary<String, AnyObject>] {
    var results: [Dictionary<String, AnyObject>] = [];
    self.db.open();
    let rs: FMResultSet? = self.db.executeQuery("SELECT * FROM " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INTERVAL_LABELS + " ORDER BY start_date LIMIT ?", withArgumentsIn: [recordlimit]);
    if(rs == nil) {
      return results;
    }
    
    while (rs!.next()) {
      let intervalLabels = UTEModelIntervalLabels();
      intervalLabels.start_date = rs!.double(forColumn: "start_date");
      intervalLabels.end_date = rs!.double(forColumn: "end_date");
      intervalLabels.labels = rs!.string(forColumn: "labels")
      
      results.append(intervalLabels.toJson());
    }
    
    self.db.close();
    
    return results;
  }
  
  func deleteSessionInfosBefore(thetime: Double) {
    self.db.open();
    
    let params: Dictionary<String, AnyObject> = [
      "thetime": thetime as AnyObject,
    ];
    
    self.db.executeUpdate("DELETE FROM sensor_infos WHERE logged_at <= :thetime;", withParameterDictionary: params);
    
    self.db.close();
  }
  
  func deleteBluetoothInfosBefore(thetime: Double, lastIdToDelete: UInt64) {
    self.db.open();
    
    let params: Dictionary<String, AnyObject> = [
      "thetime": thetime as AnyObject,
      "lastIdToDelete": lastIdToDelete as AnyObject
      ];
    
    self.db.executeUpdate("DELETE FROM " + UTESessionDBService.SQLITE_TABLE_NAME_BLUETOOTH_INFOS + " WHERE logged_at <= :thetime AND id <= :lastIdToDelete;", withParameterDictionary: params);
    
    self.db.close();
  }
  
  func deleteSessionIntervalLabelsBefore(thetime: Double) {
    self.db.open();
    
    let params: Dictionary<String, AnyObject> = [
      "thetime": thetime as AnyObject,
      ];
    
    self.db.executeUpdate("DELETE FROM " + UTESessionDBService.SQLITE_TABLE_NAME_SENSOR_INTERVAL_LABELS + " WHERE start_date <= :thetime;", withParameterDictionary: params);
    
    self.db.close();
  }
  
  private func convertToNSNumber(value: Double?) -> AnyObject {
    if (value == nil) {
      return NSNull();
    }
    
    return NSNumber(value: value!);
  }
}
