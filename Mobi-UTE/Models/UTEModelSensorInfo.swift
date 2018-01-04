//
//  UTEModelSensorInfo.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 3/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation

public class UTEModelSensorInfo : NSObject {
  public var accelerometer_acceleration_x: Double?
  public var accelerometer_acceleration_y: Double?
  public var accelerometer_acceleration_z: Double?
  public var motion_gravity_x: Double?
  public var motion_gravity_y: Double?
  public var motion_gravity_z: Double?
  public var motion_user_acceleration_x: Double?
  public var motion_user_acceleration_y: Double?
  public var motion_user_acceleration_z: Double?
  public var motion_attitude_yaw: Double?
  public var motion_attitude_pitch: Double?
  public var motion_attitude_roll: Double?
  public var gyroscope_rotationrate_x: Double?
  public var gyroscope_rotationrate_y: Double?
  public var gyroscope_rotationrate_z: Double?
  public var motion_rotationrate_x: Double?
  public var motion_rotationrate_y: Double?
  public var motion_rotationrate_z: Double?
  public var magnetic_heading_x: Double?
  public var magnetic_heading_y: Double?
  public var magnetic_heading_z: Double?
  public var calibrated_magnetic_field_x: Double?
  public var calibrated_magnetic_field_y: Double?
  public var calibrated_magnetic_field_z: Double?
  public var calibrated_magnetic_field_accuracy: Double?
  public var magnetometer_x: Double?
  public var magnetometer_y: Double?
  public var magnetometer_z: Double?
  public var location_latitude: Double?
  public var location_longitude: Double?
  public var location_accuracy: Double?
  public var gps_speed: Double?
  public var noise_level: Double?
  public var pressure: Double?
  public var altitude: Double?
  public var timestamp: Double?
  
  public func toJson() -> Dictionary<String, AnyObject> {
    var dict: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>();
    dict["aa_x"] = (self.accelerometer_acceleration_x != nil) ? self.accelerometer_acceleration_x! as AnyObject : NSNull();
    dict["aa_y"] = (self.accelerometer_acceleration_y != nil) ? self.accelerometer_acceleration_y! as AnyObject : NSNull();
    dict["aa_z"] = (self.accelerometer_acceleration_z != nil) ? self.accelerometer_acceleration_z! as AnyObject : NSNull();
    dict["mg_x"] = (self.motion_gravity_x != nil) ? self.motion_gravity_x! as AnyObject : NSNull();
    dict["mg_y"] = (self.motion_gravity_y != nil) ? self.motion_gravity_y! as AnyObject : NSNull();
    dict["mg_z"] = (self.motion_gravity_z != nil) ? self.motion_gravity_z! as AnyObject : NSNull();
    dict["mua_x"] = (self.motion_user_acceleration_x != nil) ? self.motion_user_acceleration_x! as AnyObject : NSNull();
    dict["mua_y"] = (self.motion_user_acceleration_y != nil) ? self.motion_user_acceleration_y! as AnyObject : NSNull();
    dict["mua_z"] = (self.motion_user_acceleration_z != nil) ? self.motion_user_acceleration_z! as AnyObject : NSNull();
    dict["ma_y"] = (self.motion_attitude_yaw != nil) ? self.motion_attitude_yaw! as AnyObject : NSNull();
    dict["ma_p"] = (self.motion_attitude_pitch != nil) ? self.motion_attitude_pitch! as AnyObject : NSNull();
    dict["ma_r"] = (self.motion_attitude_roll != nil) ? self.motion_attitude_roll! as AnyObject : NSNull();
    
    dict["grr_x"] = (self.gyroscope_rotationrate_x != nil) ? self.gyroscope_rotationrate_x! as AnyObject : NSNull();
    dict["grr_y"] = (self.gyroscope_rotationrate_y != nil) ? self.gyroscope_rotationrate_y! as AnyObject : NSNull();
    dict["grr_z"] = (self.gyroscope_rotationrate_z != nil) ? self.gyroscope_rotationrate_z! as AnyObject : NSNull();
    
    dict["mrr_x"] = (self.motion_rotationrate_x != nil) ? self.motion_rotationrate_x! as AnyObject : NSNull();
    dict["mrr_y"] = (self.motion_rotationrate_y != nil) ? self.motion_rotationrate_y! as AnyObject : NSNull();
    dict["mrr_z"] = (self.motion_rotationrate_z != nil) ? self.motion_rotationrate_z! as AnyObject : NSNull();
    
    dict["mh_x"] = (self.magnetic_heading_x != nil) ? self.magnetic_heading_x! as AnyObject : NSNull();
    dict["mh_y"] = (self.magnetic_heading_y != nil) ? self.magnetic_heading_y! as AnyObject : NSNull();
    dict["mh_z"] = (self.magnetic_heading_z != nil) ? self.magnetic_heading_z! as AnyObject : NSNull();
    
    dict["cmf_x"] = (self.calibrated_magnetic_field_x != nil) ? self.calibrated_magnetic_field_x! as AnyObject : NSNull();
    dict["cmf_y"] = (self.calibrated_magnetic_field_y != nil) ? self.calibrated_magnetic_field_y! as AnyObject : NSNull();
    dict["cmf_z"] = (self.calibrated_magnetic_field_z != nil) ? self.calibrated_magnetic_field_z! as AnyObject : NSNull();
    dict["cmf_a"] = (self.calibrated_magnetic_field_accuracy != nil) ? self.calibrated_magnetic_field_accuracy! as AnyObject : NSNull();
    
    dict["mm_x"] = (self.magnetic_heading_x != nil) ? self.magnetic_heading_x! as AnyObject : NSNull();
    dict["mm_y"] = (self.magnetic_heading_y != nil) ? self.magnetic_heading_y! as AnyObject : NSNull();
    dict["mm_z"] = (self.magnetic_heading_z != nil) ? self.magnetic_heading_z! as AnyObject : NSNull();
    
    dict["lat"] = (self.location_latitude != nil) ? self.location_latitude! as AnyObject : NSNull();
    dict["lon"] = (self.location_longitude != nil) ? self.location_longitude! as AnyObject : NSNull();
    dict["gps_a"] = (self.location_accuracy != nil) ? self.location_accuracy! as AnyObject : NSNull();
    dict["gps_s"] = (self.gps_speed != nil) ? self.gps_speed! as AnyObject : NSNull();
    
    dict["n_l"] = (self.noise_level != nil) ? self.noise_level! as AnyObject : NSNull();
    
    dict["pres"] = (self.pressure != nil) ? self.pressure! as AnyObject : NSNull();
    dict["alt"] = (self.altitude != nil) ? self.altitude! as AnyObject : NSNull();
    
    dict["t"] = (self.timestamp != nil) ? self.timestamp! as AnyObject : NSNull();
    
    return dict;
  }
}
