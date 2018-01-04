//
//  SessionSensorsService.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 2/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import AVFoundation
import CoreBluetooth

public class SessionSensorsService: NSObject, CLLocationManagerDelegate, AVAudioRecorderDelegate, CBCentralManagerDelegate {
  let locManagerService: CLLocationManager = CLLocationManager()
  let motionManager: CMMotionManager = CMMotionManager()
  let altimeter: CMAltimeter = CMAltimeter()
  var recordingSession: AVAudioSession? = nil
  var recorder: AVAudioRecorder? = nil
  var centralManager: CBCentralManager?
  public var MONITOR_INTERVAL: Double = 0;
  
  // magnetism
  private var deviceLocHeading: CLHeading?;
  
  // MARK: public getter and private setter for sensor readings
  public private(set) var accelerometer_acceleration_x: Double?
  public private(set) var accelerometer_acceleration_y: Double?
  public private(set) var accelerometer_acceleration_z: Double?
  public private(set) var motion_gravity_x: Double?
  public private(set) var motion_gravity_y: Double?
  public private(set) var motion_gravity_z: Double?
  public private(set) var motion_user_acceleration_x: Double?
  public private(set) var motion_user_acceleration_y: Double?
  public private(set) var motion_user_acceleration_z: Double?
  public private(set) var motion_attitude_yaw: Double?
  public private(set) var motion_attitude_pitch: Double?
  public private(set) var motion_attitude_roll: Double?
  public private(set) var gyroscope_rotationrate_x: Double?
  public private(set) var gyroscope_rotationrate_y: Double?
  public private(set) var gyroscope_rotationrate_z: Double?
  public private(set) var motion_rotationrate_x: Double?
  public private(set) var motion_rotationrate_y: Double?
  public private(set) var motion_rotationrate_z: Double?
  public private(set) var magnetic_heading_x: Double?
  public private(set) var magnetic_heading_y: Double?
  public private(set) var magnetic_heading_z: Double?
  
  public private(set) var calibrated_magnetic_field_x: Double?
  public private(set) var calibrated_magnetic_field_y: Double?
  public private(set) var calibrated_magnetic_field_z: Double?
  public private(set) var calibrated_magnetic_field_accuracy: Double?
  public private(set) var magnetometer_x: Double?
  public private(set) var magnetometer_y: Double?
  public private(set) var magnetometer_z: Double?
  
  public private(set) var location_current: CLLocation?
  public private(set) var location_latitude: Double?
  public private(set) var location_longitude: Double?
  public private(set) var location_accuracy: Double?
  public private(set) var gps_speed: Double?
  public private(set) var noise_level: Double?
  public private(set) var pressure: Double? // kilopascals
  public private(set) var altitude: Double?
  
  public private(set) var accelerometerEnabled: Bool = false
  public private(set) var gyroscopeEnabled: Bool = false
  public private(set) var magnetometerEnabled: Bool = false
  public private(set) var gpsEnabled: Bool = false
  public private(set) var noiseLevelEnabled: Bool = false
  public private(set) var barometerEnabled: Bool = false
  public private(set) var bluetoothEnabled: Bool = false
  
  
  var levelTimer: Timer?
  var bluetoothTimer: Timer?
  var gpsTimer: Timer?
  
  override convenience init() {
    self.init(intervals: 1.0/10.0);
  }
  
  init(intervals: Double) {
    super.init();

    //self.locManagerService.requestAlwaysAuthorization();
    self.locManagerService.requestAlwaysAuthorization();
    
    self.locManagerService.delegate = self;
    self.locManagerService.distanceFilter = 10;
    self.locManagerService.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locManagerService.activityType = CLActivityType.automotiveNavigation;
    
    self.MONITOR_INTERVAL = intervals;
    self.motionManager.deviceMotionUpdateInterval = intervals;
  }
  
  func startSensors(accelerometerEnabled: Bool, gyroscopeEnabled: Bool, magnetometerEnabled:Bool, gpsEnabled:Bool, noiseLevelEnabled: Bool, barometerEnabled: Bool, bluetoothEnabled: Bool, timeIntervalPoll: [String: Int]) -> Bool {
    
    if accelerometerEnabled && gyroscopeEnabled && magnetometerEnabled {
      self.setupDeviceMotion()
    }

    if accelerometerEnabled {
      self.accelerometerEnabled = true
      var timeToUpdate: Double? = nil
      if let acceltime = timeIntervalPoll["accelerometer"] {
        timeToUpdate = TransformerUtilities.convertMillisecToSec(milliseconds: acceltime)
      }
      self.setupAccelerometer(timeInterval: timeToUpdate)
    }
    
    if gyroscopeEnabled {
      self.gyroscopeEnabled = true
      var timeToUpdate: Double? = nil
      if let gyrotime = timeIntervalPoll["gyroscope"] {
        timeToUpdate = TransformerUtilities.convertMillisecToSec(milliseconds: gyrotime)
      }
      self.setupGyroscope(timeInterval: timeToUpdate)
    }
    
    if magnetometerEnabled {
      self.magnetometerEnabled = true
      var timeToUpdate: Double? = nil
      if let magtime = timeIntervalPoll["magnetometer"] {
        timeToUpdate = TransformerUtilities.convertMillisecToSec(milliseconds: magtime)
      }
      self.setupMagnetometer(timeInterval: timeToUpdate)
      
      self.locManagerService.startUpdatingHeading();
    }
    
    if gpsEnabled {
      self.gpsEnabled = true
      self.locManagerService.startUpdatingLocation()
      var timeToUpdate: Double? = nil
      if let gpstime = timeIntervalPoll["gps"] {
        timeToUpdate = TransformerUtilities.convertMillisecToSec(milliseconds: gpstime)
      }
      setupGPS(timeInterval: timeToUpdate)
    }
    
    if noiseLevelEnabled {
      self.noiseLevelEnabled = true
      var timeToUpdate: Double? = nil
      if let noiselvltime = timeIntervalPoll["noise_level"] {
        timeToUpdate = TransformerUtilities.convertMillisecToSec(milliseconds: noiselvltime)
      }
      
      self.setupMicrophone(timeInterval: timeToUpdate)
    }
    
    if barometerEnabled {
      self.barometerEnabled = true
      self.setupBarometer()
    }
    
    if bluetoothEnabled {
      self.bluetoothEnabled = true
      var timeToUpdate: Double? = nil
      if let bluetoothTime = timeIntervalPoll["bluetooth"] {
        timeToUpdate = TransformerUtilities.convertMillisecToSec(milliseconds: bluetoothTime)
      }
      
      self.setupBluetooth(timeInterval: timeToUpdate)
    }
    
    //let sensorIsReady = self.motionManager.isDeviceMotionAvailable && self.motionManager.isGyroAvailable && self.motionManager.isAccelerometerAvailable && CLLocationManager.headingAvailable();
    
    /*if(sensorIsReady == false)
    {
      print("sensor is not ready. ")
      self.stopSensors();
      return false;
    }*/
    
    return true;
  }
  
  func setupDeviceMotion()  {
    if self.motionManager.isDeviceMotionAvailable {
      self.motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: OperationQueue.current!, withHandler:{
        motionData, error in
        
        if let motiondata = motionData
        {
          self.motion_attitude_yaw = motiondata.attitude.yaw
          self.motion_attitude_pitch = motiondata.attitude.pitch
          self.motion_attitude_roll = motiondata.attitude.roll
          
          self.motion_gravity_x = motiondata.gravity.x
          self.motion_gravity_y = motiondata.gravity.y
          self.motion_gravity_z = motiondata.gravity.z
          
          self.motion_user_acceleration_x = motiondata.userAcceleration.x
          self.motion_user_acceleration_y = motiondata.userAcceleration.y
          self.motion_user_acceleration_z = motiondata.userAcceleration.z
          
          self.motion_rotationrate_x = motiondata.rotationRate.x
          self.motion_rotationrate_y = motiondata.rotationRate.y
          self.motion_rotationrate_z = motiondata.rotationRate.z
          
          self.calibrated_magnetic_field_x = motiondata.magneticField.field.x;
          self.calibrated_magnetic_field_y = motiondata.magneticField.field.y;
          self.calibrated_magnetic_field_z = motiondata.magneticField.field.z;
          self.calibrated_magnetic_field_accuracy = Double(motiondata.magneticField.accuracy.rawValue);
        }
        else {
          self.motion_attitude_yaw = nil;
          self.motion_attitude_pitch = nil;
          self.motion_attitude_roll = nil;
          
          self.motion_gravity_x = nil;
          self.motion_gravity_y = nil;
          self.motion_gravity_z = nil;
          
          self.motion_user_acceleration_x = nil;
          self.motion_user_acceleration_y = nil;
          self.motion_user_acceleration_z = nil;
          
          self.motion_rotationrate_x = nil;
          self.motion_rotationrate_y = nil;
          self.motion_rotationrate_z = nil;
          
          self.calibrated_magnetic_field_x = nil;
          self.calibrated_magnetic_field_y = nil;
          self.calibrated_magnetic_field_z = nil;
          self.calibrated_magnetic_field_accuracy = nil;
        }
      })
    }
  }
  
  func setupAccelerometer(timeInterval: TimeInterval?)  {
    if timeInterval == nil {
      return
    }
    
    // device acceleration
    if self.motionManager.isAccelerometerAvailable {
      self.motionManager.accelerometerUpdateInterval = timeInterval!
      self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler:{
        accelerometerData, error in
        if let accelData = accelerometerData {
          self.accelerometer_acceleration_x = accelData.acceleration.x;
          self.accelerometer_acceleration_y = accelData.acceleration.y;
          self.accelerometer_acceleration_z = accelData.acceleration.z;
        } else {
          self.accelerometer_acceleration_x = nil;
          self.accelerometer_acceleration_y = nil;
          self.accelerometer_acceleration_z = nil;
        }
      })
    }
  }
  
  func setupGyroscope(timeInterval: TimeInterval?)  {
    if timeInterval == nil {
      return
    }
    
    if self.motionManager.isGyroAvailable {
      self.motionManager.gyroUpdateInterval = timeInterval!
      self.motionManager.startGyroUpdates(to: OperationQueue.current!, withHandler:{
        gyroscopeData, error in
        if let gyroData = gyroscopeData {
          // device rotation rate
          self.gyroscope_rotationrate_x = gyroData.rotationRate.x;
          self.gyroscope_rotationrate_y = gyroData.rotationRate.y;
          self.gyroscope_rotationrate_z = gyroData.rotationRate.z;
        } else {
          self.gyroscope_rotationrate_x = nil;
          self.gyroscope_rotationrate_y = nil;
          self.gyroscope_rotationrate_z = nil;
        }
      })
    }
  }
  
  func setupMagnetometer(timeInterval: TimeInterval?)  {
    if timeInterval == nil {
      return
    }
    
    if self.motionManager.isMagnetometerAvailable {
      self.motionManager.magnetometerUpdateInterval = timeInterval!
      self.motionManager.startMagnetometerUpdates(to: OperationQueue.current!, withHandler:{
        magnetometerData, error in
        
        if let devicemagnetometerdata = magnetometerData {
          self.magnetometer_x = devicemagnetometerdata.magneticField.x;
          self.magnetometer_y = devicemagnetometerdata.magneticField.y;
          self.magnetometer_z = devicemagnetometerdata.magneticField.z;
        }
        else {
          self.magnetometer_x = nil;
          self.magnetometer_y = nil;
          self.magnetometer_z = nil;
        }
        
        // update heading
        self.deviceLocHeading = self.locManagerService.heading;
        
        if let devicelocationheading = self.deviceLocHeading {
          self.magnetic_heading_x = devicelocationheading.x;
          self.magnetic_heading_y = devicelocationheading.y;
          self.magnetic_heading_z = devicelocationheading.x;
        }
        else {
          self.magnetic_heading_x = nil;
          self.magnetic_heading_y = nil;
          self.magnetic_heading_z = nil;
        }
      })
    }
  }
  
  func setupMicrophone(timeInterval: TimeInterval?) {
    if timeInterval == nil {
      return
    }
    
    recordingSession = AVAudioSession.sharedInstance()
    
    do {
      if let recordingSession = self.recordingSession {
        try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try recordingSession.setActive(true)
        recordingSession.requestRecordPermission() { [unowned self] allowed in
          DispatchQueue.main.async {
            if allowed {
              let url = NSURL.fileURL(withPath: "dev/null")
              //numbers are automatically wrapped into NSNumber objects, so I simplified that to [NSString : NSNumber]
              let settings = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey : 320000,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey : 44100.0
                /*AVFormatIDKey:kAudioFormatAppleIMA4,
                 AVSampleRateKey:44100.0,
                 AVNumberOfChannelsKey:2,AVEncoderBitRateKey:12800,
                 AVLinearPCMBitDepthKey:16,
                 AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue*/
                ] as [String : Any]
              
              do {
                self.recorder = try AVAudioRecorder(url: url, settings: settings)
                if let recorder = self.recorder {
                  recorder.delegate = self
                  recorder.prepareToRecord()
                  recorder.isMeteringEnabled = true
                  recorder.record()
                  self.levelTimer = Timer.scheduledTimer(timeInterval: timeInterval!, target: self, selector: #selector(SessionSensorsService.levelTimerCallback), userInfo: nil, repeats: true)
                }
                
              } catch {
                NSLog("%@", "Error");
              }
            } else {
              // failed to record!
            }
          }
        }
      }
    } catch {
      // failed to record!
    }
  }
  
  public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    if let error = error {
      print("\(error.localizedDescription)")
    }
  }
  
  func levelTimerCallback() {
    if let levelTimer = self.levelTimer, let recorder = self.recorder {
      recorder.updateMeters()
      var noiseLevel = Double(recorder.peakPower(forChannel: 0))
      self.noise_level = noiseLevel
    }
  }
  
  func setupBarometer() {
    // device altimeter
    if CMAltimeter.isRelativeAltitudeAvailable() {
      self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.current!, withHandler:{
        altimeterData, error in
        if let altiData = altimeterData {
          self.pressure = altiData.pressure.doubleValue
        } else {
          self.pressure = nil;
        }
      })
    }
  }
  
  var cachedPeripherals: [UTEModelBluetoothInfo] = [UTEModelBluetoothInfo]()
  var peripherals: [UTEModelBluetoothInfo] = [UTEModelBluetoothInfo]()
  var bluetoothLastread: Double = 0
  let BLUETOOTH_LAST_READ_THRESHOLD: Double = 5 * 60
  
  func setupBluetooth(timeInterval: TimeInterval?) {
    if timeInterval == nil {
      return
    }
    
    centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    self.bluetoothTimer = Timer.scheduledTimer(timeInterval: timeInterval!, target: self, selector: #selector(SessionSensorsService.bluetoothTimerCallback), userInfo: nil, repeats: true)
  }
  
  func bluetoothTimerCallback() {
    if let bluetoothTimer = self.bluetoothTimer, let centralManager = self.centralManager {
      self.scanNearbyBluetoothDevices()
    }
  }
  
  //CoreBluetooth methods
  public func centralManagerDidUpdateState(_ central: CBCentralManager)
  {
    if (central.state == CBManagerState.poweredOn)
    {
      self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    else
    {
      // do something like alert the user that ble is not on
    }
  }
  
  public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    let bluetoothInfo = UTEModelBluetoothInfo()
    bluetoothInfo.uuid = peripheral.identifier.uuidString
    bluetoothInfo.name = peripheral.name
    bluetoothInfo.rssi = RSSI as Double
    self.bluetoothLastread = UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp()
    
    peripherals.append(bluetoothInfo)
  }
  
  func scanNearbyBluetoothDevices() {
    if let manager = centralManager {
      if (manager.state == CBManagerState.poweredOn)
      {
        self.centralManager?.stopScan()
        self.cachedPeripherals = self.peripherals
        self.peripherals = [UTEModelBluetoothInfo]()
        self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
      }
    }
  }
  
  func setupGPS(timeInterval: TimeInterval?) {
    if timeInterval == nil {
      return
    }
    
    self.gpsTimer = Timer.scheduledTimer(timeInterval: timeInterval!, target: self, selector: #selector(SessionSensorsService.gpsTimerCallback), userInfo: nil, repeats: true)
  }
  
  func gpsTimerCallback() {
    if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
      CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
      let currentLocation = self.locManagerService.location;
      if let currentLocation = currentLocation {
        self.location_current = currentLocation;
        self.location_latitude = currentLocation.coordinate.latitude
        self.location_longitude = currentLocation.coordinate.longitude
        self.location_accuracy = currentLocation.horizontalAccuracy
        self.gps_speed = currentLocation.speed
        if barometerEnabled {
          self.altitude = currentLocation.altitude
        }
      }
    }
  }
  
  func stopSensors() {
    if accelerometerEnabled {
      self.motionManager.stopAccelerometerUpdates()
    }
    
    if gyroscopeEnabled {
      self.motionManager.stopGyroUpdates()
    }
    
    if magnetometerEnabled {
      self.motionManager.stopMagnetometerUpdates()
      self.locManagerService.stopUpdatingHeading()
    }
    
    if accelerometerEnabled && gyroscopeEnabled && magnetometerEnabled {
      self.motionManager.stopDeviceMotionUpdates()
    }
    
    if gpsEnabled {
      gpsTimer!.invalidate()
      gpsTimer = nil
      self.locManagerService.stopUpdatingLocation()
    }
    
    if levelTimer != nil && recorder != nil && noiseLevelEnabled {
      levelTimer!.invalidate()
      levelTimer = nil
      recorder!.stop()
      recorder = nil
      do {
        let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let url =  documents.appendingPathComponent("dev/null")
        try FileManager.default.removeItem(at: url)
      } catch let error1 as NSError {
      };
    }
    
    if barometerEnabled {
      self.altimeter.stopRelativeAltitudeUpdates()
    }
    
    if bluetoothTimer != nil && self.centralManager != nil && bluetoothEnabled {
      bluetoothTimer!.invalidate()
      bluetoothTimer = nil
      self.centralManager?.stopScan()
      self.centralManager = nil
    }
  }
  
  func readSensorData() -> Bool {
    
    return true;
    
    /*
    reads the sensor data
    There are 21 channels in total.
    1-3    : raw acceleration x,y,z
    4-6    : gravity x,y,z
    7-9    : user acceleration x,y,z
    10-12  : yaw, pitch, roll x,y,z
    13-15  : raw rotation rate x,y,z
    16-18  : unbiased rotation rate x,y,z
    19-21  : magnetic heading x,y,z
    
    */
    // Note here the index starts at 0
    /*att0 = deviceRawAccel.x;
    att1 = deviceRawAccel.y;
    att2 = deviceRawAccel.z;
    att3 = deviceGravity.x;
    att4 = deviceGravity.y;
    att5 = deviceGravity.z;
    att6 = deviceMotionAcceleration.x;
    att7 = deviceMotionAcceleration.y;
    att8 = deviceMotionAcceleration.z;
    att9 = deviceAttitude.yaw;
    att10 = deviceAttitude.pitch;
    att11 = deviceAttitude.roll;
    att12 = deviceGyroRotationRate.x;
    att13 = deviceGyroRotationRate.y;
    att14 = deviceGyroRotationRate.z;
    att15 = deviceMotionRotationRate.x;
    att16 = deviceMotionRotationRate.y;
    att17 = deviceMotionRotationRate.z;
    att18 = locationHeading.x;
    att19 = locationHeading.y;
    att20 = locationHeading.z;*/
  }
  
  func getSensorInfos() -> UTEModelSensorInfo {
    let sensorInfo: UTEModelSensorInfo = UTEModelSensorInfo();
    sensorInfo.accelerometer_acceleration_x = self.accelerometer_acceleration_x
    sensorInfo.accelerometer_acceleration_y = self.accelerometer_acceleration_y
    sensorInfo.accelerometer_acceleration_z = self.accelerometer_acceleration_z
    sensorInfo.motion_gravity_x = self.motion_gravity_x
    sensorInfo.motion_gravity_y = self.motion_gravity_y
    sensorInfo.motion_gravity_z = self.motion_gravity_z
    sensorInfo.motion_user_acceleration_x = self.motion_user_acceleration_x
    sensorInfo.motion_user_acceleration_y = self.motion_user_acceleration_y
    sensorInfo.motion_user_acceleration_z = self.motion_user_acceleration_z
    sensorInfo.motion_attitude_yaw = self.motion_attitude_yaw
    sensorInfo.motion_attitude_pitch = self.motion_attitude_pitch
    sensorInfo.motion_attitude_roll = self.motion_attitude_roll
    sensorInfo.gyroscope_rotationrate_x = self.gyroscope_rotationrate_x
    sensorInfo.gyroscope_rotationrate_y = self.gyroscope_rotationrate_y
    sensorInfo.gyroscope_rotationrate_z = self.gyroscope_rotationrate_z
    sensorInfo.motion_rotationrate_x = self.motion_rotationrate_x
    sensorInfo.motion_rotationrate_y = self.motion_rotationrate_y
    sensorInfo.motion_rotationrate_z = self.motion_rotationrate_z
    sensorInfo.magnetic_heading_x = self.magnetic_heading_x
    sensorInfo.magnetic_heading_y = self.magnetic_heading_y
    sensorInfo.magnetic_heading_z = self.magnetic_heading_z
    sensorInfo.calibrated_magnetic_field_x = self.calibrated_magnetic_field_x
    sensorInfo.calibrated_magnetic_field_y = self.calibrated_magnetic_field_y
    sensorInfo.calibrated_magnetic_field_z = self.calibrated_magnetic_field_z
    sensorInfo.calibrated_magnetic_field_accuracy = self.calibrated_magnetic_field_accuracy
    sensorInfo.magnetometer_x = self.magnetometer_x
    sensorInfo.magnetometer_y = self.magnetometer_y
    sensorInfo.magnetometer_z = self.magnetometer_z
    sensorInfo.location_latitude = self.location_latitude
    sensorInfo.location_longitude = self.location_longitude
    sensorInfo.location_accuracy = self.location_accuracy
    sensorInfo.gps_speed = self.gps_speed
    sensorInfo.noise_level = self.noise_level
    sensorInfo.pressure = self.pressure
    sensorInfo.altitude = self.altitude
    sensorInfo.timestamp = UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp()
    return sensorInfo
  }
  
  func getBluetoothInfos() -> [UTEModelBluetoothInfo] {
    if bluetoothEnabled == false {
      return [UTEModelBluetoothInfo]()
    }
    
    if self.peripherals.count > 0 || bluetoothLastread < UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp() - BLUETOOTH_LAST_READ_THRESHOLD  {
      for (i,eachperi) in self.peripherals.enumerated().reversed() {
        if eachperi.timestamp == nil {
          eachperi.timestamp = UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp()
        } else {
          self.peripherals.remove(at: i)
        }
      }
      
      return self.peripherals
    } else {
      for (i,eachperi) in self.cachedPeripherals.enumerated().reversed() {
        if eachperi.timestamp == nil {
          eachperi.timestamp = UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp()
        } else {
          self.cachedPeripherals.remove(at: i)
        }
      }
      
      return self.cachedPeripherals
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
    if locations.count > 0 {
      let latestLocation = locations[locations.count-1]
      if let previousLocation = self.location_current {
        let timeSince: TimeInterval = fabs(previousLocation.timestamp.timeIntervalSinceNow);
        if(timeSince > 1) {
          self.location_current = latestLocation
          self.location_latitude = latestLocation.coordinate.latitude
          self.location_longitude = latestLocation.coordinate.longitude
          self.location_accuracy = latestLocation.horizontalAccuracy
          self.gps_speed = latestLocation.speed
          if barometerEnabled {
            let latestLocationAlt = latestLocation.altitude
            self.altitude = latestLocationAlt
          }
        }
      }
    }
  }
}
