//
//  SessionViewController.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 23/12/2014.
//  Copyright (c) 2014 RMIT University. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import CoreLocation
import Darwin
import ReachabilitySwift

class SessionViewController: UIViewController, SessionFinishedHandlerProtocol {
  
  class ActivateableUIButton: UIButton {
    var activated: Bool = false
    var containedInGroup: [ActivateableUIButton]?
    
    func toggleIntervalLabelActivation() {
      if(self.activated) {
        self.activated = false;
      } else {
        self.activated = true;
      }
    }
  }
  
  public static let SESSION_ROLE_SENSING: Int = 301;
  public static let SESSION_ROLE_LABELING: Int = 302;
  
  enum SessionMode {
      case START;
      case CONNECT;
  }
  
  private let alertUIColor: UIColor = UIColor.red;
  private var genericUIColor: UIColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0);
  private let defaultLabelButtonColor: UIColor = UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
  private let pressedLabelButtonColor: UIColor = UIColor(red:0.15, green:0.65, blue:0.60, alpha:1.0)
  private let audioService: UTEAudioService = UTEAudioService();

  private let STREAM_SEND_INFO_INTERVAL_SECS: Double = 2*60;

  private var experimentAlias: String?
  private var experimentId: String?
  private var sessionId: String?
  private var uniqueId: String?
  private var isOfflineMode: Bool = false
  private var role: Int?
  private var sessionSettings: SessionSetupSettings?
  var sessionMode: SessionMode?
  var db: UTESessionDBService?
  private var hasSensorStartedRecording: Bool = false
  
  private var sessionActivityCheckTimer: Timer?
  private var sessionStreamSendSensorInfosTimer: Timer?
  private var sessionSensorMonitorTimer: Timer?
  private var sessionEventDetectionTimer: Timer?
  
  private var isSessionSensorMonitorTimerPaused: Bool = false;
  
  private var isStoppingSession: Bool = false;
  
  private var lastLat:Double?
  private var lastLong:Double?
  
  var buttonStartStop: UIButton?
  var finishLabelingButton: UIButton?
  
  // for simulation purpose
  static let hasServer = true
  
  private var sensorService: SessionSensorsService?;
  
  var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

    self.setupUI();
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func getCurrentUniqueIdOfRecording() -> String {
    return self.uniqueId ?? "";
  }
  
  func getCurrentSessionId() -> String {       
    return self.sessionId ?? "";
  }
  
  func getCurrentExperimentId() -> String {
    return self.experimentId ?? "";
  }
  
  func setCurrentSessionId(uniqueId: String, experimentId: String, experimentAlias: String?, sessionId: String, sessionMode: SessionMode, immediatelyStart: Bool) {
    self.uniqueId = uniqueId
    self.experimentId = experimentId
    self.experimentAlias = experimentAlias
    self.sessionId = sessionId
    self.sessionMode = sessionMode
    self.role = UserSettingsService.sharedInstance.getCurrentSessionRole()
    self.sessionSettings = UserSettingsService.sharedInstance.getCurrentSessionSettings()
    self.hasSensorStartedRecording = immediatelyStart
  }
  
  func setupDB() {
    if self.db == nil {
      self.db = UTESessionDBService(path: UserSettingsService.DB_FOLDER_PATH, filename: self.uniqueId! + ".sqlite", experimentId: self.experimentId!, sessionId: self.sessionId!)
    }
  }
  
  func setupUI() {
    // set background to white color.
    self.view.backgroundColor=UIColor.white;
    
    if let superview = self.view {
      // construct UI based on the role.
      if let role = self.role {
        switch role {
        case SessionViewController.SESSION_ROLE_LABELING:
          self.setupUIForLabelingRole(superview: superview)
          self.setupDB()
          break
        case SessionViewController.SESSION_ROLE_SENSING:
          self.setupUIForSensingRole(superview: superview)
          break
        default:
          self.setupUIForSensingRole(superview: superview)
        }
      }
    }
    
    if self.hasSensorStartedRecording {
      self.startRecording();
    }
  }
  
  func setupUIForSensingRole(superview: UIView) {
    let label = UILabel()
    label.textAlignment = NSTextAlignment.center
    label.lineBreakMode = .byWordWrapping
    label.numberOfLines = 0
    label.text = "Experiment:"
    superview.addSubview(label)
    
    let explabel = UILabel();
    explabel.textAlignment = NSTextAlignment.center
    explabel.lineBreakMode = .byWordWrapping
    explabel.numberOfLines = 0
    if self.experimentAlias != nil && self.experimentAlias!.isEmpty == false {
      explabel.text = self.experimentAlias
    } else {
      explabel.text = self.experimentId
    }
    
    superview.addSubview(explabel)
    
    let sessionlabel: UILabel = UILabel()
    sessionlabel.textAlignment = NSTextAlignment.center
    sessionlabel.lineBreakMode = .byWordWrapping
    sessionlabel.numberOfLines = 0
    sessionlabel.text = "Session:"
    superview.addSubview(sessionlabel)
    
    let seslabel: UILabel = UILabel()
    seslabel.textAlignment = NSTextAlignment.center
    seslabel.lineBreakMode = .byWordWrapping
    seslabel.numberOfLines = 0
    seslabel.text = self.sessionId
    superview.addSubview(seslabel)
    
    // check if it is cached experiment mode
    if self.sessionId == "" {
      self.isOfflineMode = true
      seslabel.text = "Cached Session"
    }
    
    buttonStartStop = UIButton(frame: CGRect(x: 20, y: 20, width: 280, height: 40));
    //self.buttonStart!.setTranslatesAutoresizingMaskIntoConstraints(false);
    var buttonStopLabel: String = "";
    if hasSensorStartedRecording {
      buttonStopLabel = "STOP"
    } else {
      buttonStopLabel = "START"
    }
    
    buttonStartStop?.setTitle(buttonStopLabel, for: .normal)
    buttonStartStop?.alpha=0.6
    buttonStartStop?.layer.borderWidth=0.3
    buttonStartStop?.layer.cornerRadius=2
    buttonStartStop?.addTarget(self, action: #selector(SessionViewController.onStartStopButtonPress(_:)), for: .touchUpInside);
    buttonStartStop?.addTarget(self, action: #selector(SessionViewController.onStartStopButtonTouchDown(_:)), for: .touchDown);
    buttonStartStop?.addTarget(self, action: #selector(SessionViewController.onStartStopButtonReset(_:)), for: .touchUpOutside);
    buttonStartStop?.titleLabel!.textAlignment=NSTextAlignment.center
    if self.hasSensorStartedRecording {
      self.genericUIColor = alertUIColor
    }
    self.onStartStopButtonReset(buttonStartStop)
    superview.addSubview(buttonStartStop!)
    buttonStartStop?.snp.makeConstraints { make in
      make.centerX.equalTo(superview.snp.centerX)
      make.centerY.equalTo(superview.snp.centerY)
      make.width.greaterThanOrEqualTo(200)
      make.width.lessThanOrEqualTo(400)
    };
    
    seslabel.snp.makeConstraints { make in
      make.width.lessThanOrEqualTo((superview.snp.width)).offset(-20)
      make.bottom.equalTo(buttonStartStop!.snp.top).offset(-10)
      make.centerX.greaterThanOrEqualTo(buttonStartStop!.snp.centerX).priority(10)
    }
    
    sessionlabel.snp.makeConstraints { make in
      make.width.lessThanOrEqualTo((superview.snp.width)).offset(-20)
      make.bottom.equalTo(seslabel.snp.top).offset(-10)
      make.centerX.greaterThanOrEqualTo(seslabel.snp.centerX).priority(10)
    }
    
    explabel.snp.makeConstraints { make in
      make.width.lessThanOrEqualTo((superview.snp.width)).offset(-20)
      make.bottom.equalTo(sessionlabel.snp.top).offset(-10)
      make.centerX.greaterThanOrEqualTo(sessionlabel.snp.centerX).priority(10)
    }
    
    label.snp.makeConstraints { make in
      make.width.lessThanOrEqualTo((superview.snp.width)).offset(-20);
      make.bottom.equalTo(explabel.snp.top).offset(-10);
      make.centerX.greaterThanOrEqualTo(explabel.snp.centerX).priority(10);
    }
  }
  
  func getSmallestIntervalMillisSeconds() -> Int {
    var INTERVAL_MILLIS: Int = 0
    
    var smallestMillisec: Double = DBL_MAX
    
    let sensors: [String: Int] = self.getSettings()
    for sensormill in sensors {
      let sensormillisec = Double(sensormill.value)
      if sensormillisec < smallestMillisec {
        smallestMillisec = sensormillisec
      }
    }
    
    if(smallestMillisec != DBL_MAX) {
      INTERVAL_MILLIS = Int(smallestMillisec)
    }
    
    if INTERVAL_MILLIS == 0 {
      return -1
    }
    
    return INTERVAL_MILLIS;
  }
  
  func getSettings() -> [String: Int] {
    var settings = [String: Int]()
    if let sessionSettings = self.sessionSettings {
      if let sensors = sessionSettings.sensors {
        for sensor in sensors {
          if let name = sensor.name {
            if let freq = sensor.freq {
              settings[name] = TransformerUtilities.convertHzToMillisec(hz: freq)
            } else if let sec: Double = sensor.sec {
              settings[name] = Int(sec * 1000)
            }
          }
        }
      }
    }
    
    return settings
  }
  
  func startRecording() {
    self.setupDB()
    
    // set recording based on the role. 
    if let role = self.role {
      switch role {
      case SessionViewController.SESSION_ROLE_LABELING:
        break
      case SessionViewController.SESSION_ROLE_SENSING:
        self.startRecordingForSensing()
        break
      default:
        self.startRecordingForSensing()
      }
    }
  }
  
  func startRecordingForSensing() {
    // create service for sensors and start them.
    self.sensorService = SessionSensorsService();
    print("about to start sensor service")
    // get settings
    var settings = self.getSettings()
    let sensorRecordingStarted: Bool = self.sensorService!.startSensors(
      accelerometerEnabled: settings["accelerometer"] != nil,
      gyroscopeEnabled: settings["gyroscope"] != nil,
      magnetometerEnabled: settings["magnetometer"] != nil,
      gpsEnabled: settings["gps"] != nil,
      noiseLevelEnabled: settings["noise_level"] != nil,
      barometerEnabled: settings["barometer"] != nil,
      bluetoothEnabled: settings["bluetooth"] != nil,
      timeIntervalPoll: settings
    )
    print("finish setting up sensor reading service")
    if sensorRecordingStarted {
      // set up nstimer for actively tracking and recording the sensors
      let smallestInterval = self.getSmallestIntervalMillisSeconds();
      if smallestInterval != -1
      {
        let intervalSeconds: Double = Double(smallestInterval) / Double(1000)
        self.sessionSensorMonitorTimer = Timer.scheduledTimer(timeInterval: intervalSeconds, target: self, selector: #selector(SessionViewController.readSensors(_:)), userInfo: nil, repeats: true)
        registerBackgroundTask()
      }
      
      // play start session sound
      //self.audioService.playAudioStartSession();
    } else {
      ThreadUtilities.delay(10){
        self.startRecording()
      }
    }
  }
  
  func readSensors(_ timer: Timer) {
    if(self.isSessionSensorMonitorTimerPaused) {
      return;
    }
    
    if let sensors = self.sensorService {
      if(!sensors.readSensorData()) {
        return;
      }
      if(self.db == nil) {
        return;
      }
      
      let sensorInfo: UTEModelSensorInfo = sensors.getSensorInfos()
      
      /*dispatch_async(dispatch_get_main_queue()) {
        if let useracc_z = sensorInfo.motion_user_acceleration_z {
          //self.detectionService.addDataPoint([useracc_z], pointTime: sensorInfo.timestamp!)
        }
      }*/
      
      self.db!.insertSessionInfo(sensorInfo: sensorInfo);
      
      if let locationlatitude = sensorInfo.location_latitude, let locationlongitude = sensorInfo.location_longitude {
        if(self.lastLat != locationlatitude && self.lastLong != locationlongitude) {
          self.lastLat = sensorInfo.location_latitude
          self.lastLong = sensorInfo.location_longitude
        }
      }
      
      let bluetoothInfos: [UTEModelBluetoothInfo] = sensors.getBluetoothInfos()
      if bluetoothInfos.count > 0 {
        for eachblutoothinfo in bluetoothInfos {
          self.db!.insertBluetoothInfo(bluetoothInfo: eachblutoothinfo)
        }
      }
    }
  }
  
  func onStartStopButtonTouchDown(_ sender: UIButton!){
      sender.backgroundColor=UIColor.white;
      sender.setTitleColor(self.genericUIColor, for: .normal);
      sender.layer.borderColor = self.genericUIColor.cgColor;
  }
  
  func onStartStopButtonReset(_ sender: UIButton!){
    sender.backgroundColor=genericUIColor;
    sender.setTitleColor(UIColor.white, for: .normal)
  }
  
  func onStartStopButtonPress(_ sender: UIButton!){
    self.onStartStopButtonReset(sender);
    
    if hasSensorStartedRecording {
      var message = "Are you sure you want to finish this session?"
      if let experimentId = self.experimentId {
        message += "\nExperiment: "
        if self.experimentAlias != nil && self.experimentAlias!.isEmpty == false {
          message += self.experimentAlias!
        } else {
          message += experimentId
        }
      }
      if let sessionId = self.sessionId {
        var sessionToDisplay = sessionId
        if sessionId == "" {
          sessionToDisplay = "Cached Session"
        }
        message += "\nSession: \(sessionToDisplay)"
      }
      
      let confirmFinishAlert = UIAlertController(title: "Finish", message: message, preferredStyle: UIAlertControllerStyle.alert)
      
      confirmFinishAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
        self.buttonStartStop?.isEnabled = false
        
        if self.backgroundTask != UIBackgroundTaskInvalid {
          self.endBackgroundTask()
        }
        
        if let currentSessionId = self.sessionId {
          self.pauseSensorReadings();
          self.finishSessionAskForUpload(currentSessionId: currentSessionId);
        }
      }))
      
      confirmFinishAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
        //println("Handle Cancel Logic here")
      }))
      
      present(confirmFinishAlert, animated: true, completion: nil)
    } else {
      self.genericUIColor = alertUIColor;
      sender.setTitle("STOP", for: .normal);
      self.onStartStopButtonReset(sender);
      self.startRecording();
      hasSensorStartedRecording = true;
      
    }
  }
  
  func onFinishLabelingButtonPress(_ sender: UIButton!) {
    self.onStartStopButtonReset(sender);
    
    var message = "Are you sure you want to finish this session?"
    
    if let experimentId = self.experimentId {
      message += "\nExperiment: "
      if self.experimentAlias != nil && self.experimentAlias!.isEmpty == false {
        message += self.experimentAlias!
      } else {
        message += experimentId
      }
    }
    
    if let sessionId = self.sessionId {
      var sessionToDisplay = sessionId
      if sessionId == "" {
        sessionToDisplay = "Cached Session"
      }
      message += "\nSession: \(sessionToDisplay)"
    }
    
    let confirmFinishAlert = UIAlertController(title: "Finish", message: message, preferredStyle: UIAlertControllerStyle.alert)
    
    confirmFinishAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
      self.finishLabelingButton?.isEnabled = false
      
      if let currentSessionId = self.sessionId {
        self.logicForLabelChanges(label: nil)
        self.finishSessionAskForUpload(currentSessionId: currentSessionId);
      }
    }))
    
    confirmFinishAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
      //println("Handle Cancel Logic here")
    }))
    
    present(confirmFinishAlert, animated: true, completion: nil);
  }
  
  private func pauseSensorReadings() {
    if let _ = self.sessionSensorMonitorTimer {
      self.isSessionSensorMonitorTimerPaused = true;
    }
  }
  
  private func resumeSensorReadings() {
    if let _ = self.sessionSensorMonitorTimer {
      self.isSessionSensorMonitorTimerPaused = false;
    }
  }
  
  private func stopSensorReadings() {
    if let streamSendTimer = self.sessionStreamSendSensorInfosTimer {
      streamSendTimer.invalidate();
    }
    
    if let eventDetectionTimer = self.sessionEventDetectionTimer {
      eventDetectionTimer.invalidate()
    }
    
    if let timer = self.sessionSensorMonitorTimer {
      if let sensors = self.sensorService {
        timer.invalidate();
        sensors.stopSensors();
      }
    }
  }
  
  func urlRequestWithComponents(urlString:String, parameters:Dictionary<String, String>, imageData:NSData) throws -> (URLRequestConvertible, NSData) {
    // create url request to send
    var mutableURLRequest = URLRequest(url: URL(string: urlString)!)
    mutableURLRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
    let boundaryConstant = "RTBoundary495204347";
    let contentType = "multipart/form-data;boundary="+boundaryConstant
    mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    
    // create upload data to send
    let uploadData = NSMutableData()
    
    // add image
    uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
    uploadData.append("Content-Disposition: form-data; name=\"file\"; filename=\"file.png\"\r\n".data(using: String.Encoding.utf8)!)
    uploadData.append("Content-Type: image/png\r\n\r\n".data(using: String.Encoding.utf8)!)
    uploadData.append(imageData as Data)
    
    // add parameters
    for (key, value) in parameters {
      uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
      uploadData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
    }
    uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: String.Encoding.utf8)!)
    
    
    
    // return URLRequestConvertible and NSData
    let encodedURLRequest =  try URLEncoding.queryString.encode(mutableURLRequest, with: nil)
    return (encodedURLRequest, uploadData)
  }
  
  func finishSessionAskForUpload(currentSessionId: String) {
    self.isStoppingSession = true;
    
    if NetworkUtilities.isConnectedToNetwork() {
      if let reachability = Reachability() {
        // Move to a background thread to do some long running work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // in a second...
          if reachability.isReachableViaWiFi {
            // ask for upload. 
            let confirmUploadAlert = UIAlertController(title: "Session Finished", message: "Do you want to upload the data now?", preferredStyle: UIAlertControllerStyle.alert)
            
            confirmUploadAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
              self.finishCurrentSession(currentSessionid: currentSessionId)
            }))
            
            confirmUploadAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
              // finish current session and navigate back to main menu.
              self.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: false, failedApiRequest: false)
            }))
            
            self.present(confirmUploadAlert, animated: true, completion: nil);
          } else {
            // finish current session and navigate back to main menu.
            self.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: false, failedApiRequest: false)
          }
        }
      }
    } else {
      // finish current session and navigate back to main menu.
      self.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: false, failedApiRequest: false)
    }
  }
  
  /*var loadingNotification: MBProgressHUD?*/
  
  func finishCurrentSession(currentSessionid: String) {
    self.isStoppingSession = true;
    
    if let dbservice = self.db {
      print("uploading data")
      let dataUploadService: UTEUploadDataService = UTEUploadDataService(vc: self, handler: self)
      dataUploadService.uploadData(uniqueId: self.uniqueId!, experimentId: self.getCurrentExperimentId(), sessionId: self.getCurrentSessionId(), isInitiator: self.sessionMode == SessionViewController.SessionMode.START,dbService: dbservice)
    }
  }
  
  func handleSuccessfullFinishSession(destroyRecord: Bool, didUploadData: Bool, failedApiRequest: Bool) {
    if failedApiRequest == false {
      self.stopSensorReadings();
    }
    
    // remove current cached session id.
    UserSettingsService.sharedInstance.clearCachedSessionInfo();
    
    if destroyRecord {
      // destroy local db.
      if let dbservice = self.db {
        dbservice.destroyDB();
      }
      
      UserSettingsService.sharedInstance.deleteSessionRecordSynced(uniqueId: self.uniqueId!)
    }
    
    // create new alert view then navigate back to main view controller.
    // dismiss current view controller (go back to root view controller)
    self.dismiss(animated: true, completion: nil);
    
    // play finish session sound
    //self.audioService.playAudioFinishSession();
    
    // finish session alert view.
    if let pvc = self.presentingViewController as? UINavigationController  {
      //(pvc.viewControllers[0] as! MainViewController).view.makeToast(message: "Session recording has finished.")
      
      let alert = UIAlertController(title: "Info", message:"Session recording has finished.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      (pvc.viewControllers[0] as! MainViewController).present(alert, animated: true){}
    }
  }
  
  // MARK: labeling action
  
  var intervalLabelsCurrentLabel: String?;
  var intervalLabelsStartDate: Double = 0.0;
  
  func setupUIForLabelingRole(superview: UIView) {
    self.intervalLabelsCurrentLabel = UserSettingsService.sharedInstance.getCachedSessionIntervalLabelsCurrentLabel()
    self.intervalLabelsStartDate = UserSettingsService.sharedInstance.getCachedSessionIntervalLabelsCurrentStartDate() ?? 0
    
    let scrollableView: UIScrollView = UIScrollView()
    superview.addSubview(scrollableView)
    scrollableView.snp.makeConstraints { make in
      make.top.equalTo(superview.snp.top).offset(90)
      make.width.equalTo(superview.snp.width)
      make.height.equalTo(superview.snp.height).offset(-90)
    }
    
    let labelContainerUIView: UIView = UIView()
    scrollableView.addSubview(labelContainerUIView)
    labelContainerUIView.snp.makeConstraints { make in
      make.left.equalTo(0)
      make.top.equalTo(0)
      make.width.equalTo(scrollableView.snp.width)
      make.bottom.equalTo(0)
    }
    
    if let settings = self.sessionSettings {
      if let labelsettings = settings.label {
        if labelsettings.type == "interval" { // currently only support time-interval based labeling
          if let schema = labelsettings.schema {
            if schema.count > 0 {
              // currently only support 1 label set.
              let firstLabelSchema = schema[0]
              // construct label buttons.
              if let firstlabelset: [String] = firstLabelSchema.set {
                var buttonList: [ActivateableUIButton] = [ActivateableUIButton]()
                var previousButton: ActivateableUIButton? = nil
                firstlabelset.enumerated().forEach { index, value in
                  let labelButton = ActivateableUIButton()
                  labelButton.setTitle(value, for: .normal)
                  labelButton.alpha=0.6;
                  labelButton.layer.borderWidth=0.3;
                  labelButton.layer.cornerRadius=0;
                  labelButton.titleLabel!.textAlignment=NSTextAlignment.center;
                  
                  labelContainerUIView.addSubview(labelButton)
                  labelButton.snp.makeConstraints { make in
                    if previousButton == nil {
                      make.top.equalTo(labelContainerUIView.snp.top).offset(50);
                    } else {
                      make.top.equalTo(previousButton!.snp.bottom).offset(40);
                      if index == firstlabelset.count - 1 {
                        make.bottom.equalTo(labelContainerUIView.snp.bottom).offset(-40)
                      }
                    }
                    
                    make.width.greaterThanOrEqualTo(250)
                    make.centerX.equalTo(labelContainerUIView.snp.centerX)
                  }
                  self.onLabelButtonReset(labelButton);
                  labelButton.contentEdgeInsets = UIEdgeInsetsMake(12,12,12,12)
                  
                  labelButton.addTarget(self, action: #selector(SessionViewController.onLabelButtonPress(_:)), for: .touchUpInside);
                  buttonList.append(labelButton)
                  
                  // if match with current label #ONLY SUPPORT one label
                  if labelButton.title(for: .normal) == self.intervalLabelsCurrentLabel {
                    self.triggerIntervalLabelButtonActivation(intervalLabelButton: labelButton)
                  }
                  
                  previousButton = labelButton
                }
                
                for value:ActivateableUIButton in buttonList {
                  value.containedInGroup = buttonList
                }
              }
            }
          }
        }
      }
    }
    
    //scrollableView.contentSize = CGSize(width: superview.bounds.width, height: labelContainerUIView)
    
    // construct finishbutton
    finishLabelingButton = UIButton();
    
    if let finishLabelingButton = finishLabelingButton {
      let finislabelingButtonContainer:UIView = UIView()
      finislabelingButtonContainer.backgroundColor = UIColor.white
      superview.addSubview(finislabelingButtonContainer)
      finislabelingButtonContainer.snp.makeConstraints { make in
        make.top.equalTo(superview.snp.top)
        make.width.greaterThanOrEqualTo(superview.snp.width)
        make.width.lessThanOrEqualTo(superview.snp.width)
        make.height.equalTo(60)
      };
      
      finishLabelingButton.setTitle("FINISH LABELING", for: .normal);
      finishLabelingButton.alpha=0.6;
      finishLabelingButton.layer.borderWidth=0.3;
      finishLabelingButton.layer.cornerRadius=0;
      finishLabelingButton.addTarget(self, action: #selector(SessionViewController.onFinishLabelingButtonPress(_:)), for: .touchUpInside);
      finishLabelingButton.titleLabel!.textAlignment=NSTextAlignment.center;
      
      self.genericUIColor = alertUIColor;
      self.onStartStopButtonReset(finishLabelingButton);
      
      finislabelingButtonContainer.addSubview(finishLabelingButton);
      finishLabelingButton.snp.makeConstraints { make in
        make.top.equalTo(finislabelingButtonContainer.snp.top).offset(30)
        make.size.equalTo(finislabelingButtonContainer)
      };
    }
  }
  
  func onLabelButtonReset(_ sender: ActivateableUIButton!) {
    if sender.activated == false {
      sender.backgroundColor = defaultLabelButtonColor
      sender.setTitleColor(UIColor.white, for: .normal)
    } else {
      sender.backgroundColor = pressedLabelButtonColor
      sender.setTitleColor(UIColor.white, for: .normal)
    }
    
    sender.layer.borderColor = sender.backgroundColor?.cgColor
  }
  
  func onLabelButtonPress(_ sender: ActivateableUIButton!) {
    // check if any of other button in the group is activated beside this button
    print("button pressed for: " + sender.title(for: .normal)!)
    if let groupButtons: [ActivateableUIButton] = sender.containedInGroup {
      // any other activated button
      var otherActivatedButton: ActivateableUIButton?
      for eachbutton in groupButtons {
        if eachbutton == sender {
          continue
        } else if eachbutton.activated {
          otherActivatedButton = eachbutton
          break
        }
      }
      
      if let otherActivatedButton = otherActivatedButton {
        triggerIntervalLabelButtonActivation(intervalLabelButton: otherActivatedButton)
      }
      
      triggerIntervalLabelButtonActivation(intervalLabelButton: sender)
      logicForLabelChanges(label: self.getActiveLabels(labellist: groupButtons))
    }
  }
  
  func triggerIntervalLabelButtonActivation(intervalLabelButton: ActivateableUIButton) {
    intervalLabelButton.toggleIntervalLabelActivation()
    self.onLabelButtonReset(intervalLabelButton)
  }
  
  func getActiveLabels(labellist: [ActivateableUIButton]) -> String? {
    var labels: String?
    for eachbutton in labellist {
      if eachbutton.activated {
        if labels == nil {
          labels = eachbutton.title(for: .normal)
        } else {
          labels! += eachbutton.title(for: .normal)!
        }
      }
    }
    
    return labels
  }
  
  func logicForLabelChanges(label: String?) {
    if intervalLabelsCurrentLabel == label {
      return
    } else if intervalLabelsCurrentLabel != nil && intervalLabelsCurrentLabel == label {
      return
    }
    
    if intervalLabelsCurrentLabel != label && intervalLabelsCurrentLabel != nil && intervalLabelsCurrentLabel!.isEmpty == false && intervalLabelsStartDate != 0 {
      let intervalLabel = UTEModelIntervalLabels()
      intervalLabel.start_date = intervalLabelsStartDate
      intervalLabel.end_date = UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp()
      intervalLabel.labels = intervalLabelsCurrentLabel
      // insert to db
      if let dbservice = self.db {
        dbservice.insertSensorIntervalLabel(intervalLabels: intervalLabel)
      }
      // clear cached session interval labels.
      UserSettingsService.sharedInstance.clearCachedSessionIntervalLabels();
    }
    
    intervalLabelsCurrentLabel = label;
    
    if label == nil || (label?.isEmpty)! {
      intervalLabelsStartDate = 0
    } else {
      intervalLabelsStartDate = UserSettingsService.sharedInstance.getSynchronizedCurrentTimeStamp()
      UserSettingsService.sharedInstance.setCachedSessionIntervalLabelsCurrentLabel(label: label!);
      UserSettingsService.sharedInstance.setCachedSessionIntervalLabelsCurrentStartDate(timestamp: intervalLabelsStartDate);
    }
  }
  
  func registerBackgroundTask() {
    backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.endBackgroundTask()
    }
    assert(backgroundTask != UIBackgroundTaskInvalid)
  }
  
  func endBackgroundTask() {
    print("Background task ended.")
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = UIBackgroundTaskInvalid
  }
  
  func reinstateBackgroundTask() {
    if self.sessionSensorMonitorTimer != nil && (backgroundTask == UIBackgroundTaskInvalid) {
      registerBackgroundTask()
    }
  }
}
