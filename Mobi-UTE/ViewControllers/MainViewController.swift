//
//  ViewController.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 20/12/2014.
//  Copyright (c) 2014 RMIT University. All rights reserved.
//

import UIKit
import SnapKit
import Alamofire
import CoreLocation
import ReachabilitySwift


class MainViewController: UIViewController {

  private let genericUIColor: UIColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0);
  
  override func viewDidLoad() {
      super.viewDidLoad()

      self.setupUI();
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  func setupUI() {
    //let settingsButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.compose, target: self, action: "someAction")
    //navigationItem.rightBarButtonItem = settingsButton
    
    // set background to white color.
    self.view.backgroundColor=UIColor.white;
    
    let superview = self.view;
    
    // label for Mobi-UTE main text.
    let label = UILabel();
    label.textAlignment = NSTextAlignment.center;
    label.lineBreakMode = .byWordWrapping;
    label.numberOfLines = 0;
    label.text = "Mobi-UTE";
    let pointSize = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1).pointSize
    label.font = UIFont(name:"HelveticaNeue-Bold", size: pointSize)
    label.textColor = UIColor(red:0.15, green:0.65, blue:0.60, alpha:1.0)
    superview?.addSubview(label);
    
    let buttonStart = UIButton(frame: CGRect(x: 20, y: 20, width: 300, height: 40))
    //buttonStart.setTranslatesAutoresizingMaskIntoConstraints(false);
    buttonStart.setTitle("NEW EXPERIMENT SESSION", for: .normal)
    buttonStart.alpha=0.6
    buttonStart.layer.borderWidth=0.3
    buttonStart.layer.cornerRadius=2
    buttonStart.contentEdgeInsets = UIEdgeInsetsMake(5,5,5,5)
    buttonStart.addTarget(self, action: #selector(MainViewController.onStartButtonPress(_:)), for: .touchUpInside);
    buttonStart.addTarget(self, action: #selector(MainViewController.onGenericButtonTouchDown(_:)), for: .touchDown)
    buttonStart.addTarget(self, action: #selector(MainViewController.onGenericButtonReset(_:)), for: .touchUpOutside)
    buttonStart.titleLabel!.textAlignment=NSTextAlignment.center
    self.onGenericButtonReset(buttonStart)
    superview?.addSubview(buttonStart)
    buttonStart.snp.makeConstraints { make in
      make.centerX.equalTo((superview?.snp.centerX)!)
      make.centerY.equalTo((superview?.snp.centerY)!)
      make.width.greaterThanOrEqualTo(200)
      make.width.lessThanOrEqualTo(400)
    };
    
    let buttonConnect = UIButton(frame: CGRect(x: 20, y: 20, width: 300, height: 40))
    //buttonStart.setTranslatesAutoresizingMaskIntoConstraints(false);
    buttonConnect.setTitle("CONNECT TO EXPERIMENT SESSION", for: .normal)
    buttonConnect.alpha=0.6
    buttonConnect.layer.borderWidth=0.3
    buttonConnect.layer.cornerRadius=2
    buttonConnect.contentEdgeInsets = UIEdgeInsetsMake(5,5,5,5)
    buttonConnect.addTarget(self, action: #selector(MainViewController.onConnectButtonPress(_:)), for: .touchUpInside)
    buttonConnect.addTarget(self, action: #selector(MainViewController.onGenericButtonTouchDown(_:)), for: .touchDown)
    buttonConnect.addTarget(self, action: #selector(MainViewController.onGenericButtonReset(_:)), for: .touchUpOutside)
    buttonConnect.titleLabel!.textAlignment=NSTextAlignment.center
    self.onGenericButtonReset(buttonConnect)
    superview?.addSubview(buttonConnect)
    buttonConnect.snp.makeConstraints { make in
      make.top.equalTo(buttonStart.snp.bottom).offset(10)
      make.centerX.greaterThanOrEqualTo(buttonStart.snp.centerX).priority(10)
      make.width.greaterThanOrEqualTo(200)
      make.width.lessThanOrEqualTo(400)
    };
    
    // label constraint to be above the start button
    label.snp.makeConstraints { make in
        make.width.lessThanOrEqualTo((superview?.snp.width)!).offset(-20)
        make.bottom.equalTo(buttonStart.snp.top).offset(-30)
        make.centerX.greaterThanOrEqualTo(buttonStart.snp.centerX).priority(10)
    }
    
    // additional buttons
    let settingsButton = UIButton(type: .custom)
    if let image = UIImage(named: "settings") {
      settingsButton.setImage(image, for: .normal)
      settingsButton.addTarget(self, action: #selector(MainViewController.onSettingsButtonPress(_:)), for: .touchUpInside);
    }
    superview?.addSubview(settingsButton)
    
    settingsButton.snp.makeConstraints{ make in
      make.bottom.equalTo(superview!).offset(-10)
      make.right.equalTo(superview!).offset(-10)
      make.width.lessThanOrEqualTo(40)
      make.height.lessThanOrEqualTo(40)
    }
    
    let uploadButton = UIButton(type: .custom)
    if let image = UIImage(named: "upload") {
      uploadButton.setImage(image, for: .normal)
      uploadButton.addTarget(self, action: #selector(MainViewController.onUploadButtonPress(_:)), for: .touchUpInside);
    }
    superview?.addSubview(uploadButton)
    
    uploadButton.snp.makeConstraints{ make in
      make.bottom.equalTo(settingsButton.snp.top).offset(-20)
      make.right.equalTo(superview!).offset(-10)
      make.width.lessThanOrEqualTo(40)
      make.height.lessThanOrEqualTo(40)
    }
    
    if let cachedSessionId = UserSettingsService.sharedInstance.getCurrentSessionId(), let cachedExperimentId = UserSettingsService.sharedInstance.getCurrentExperimentId(), let cachedUniqueId = UserSettingsService.sharedInstance.getCurrentUniqueIdOfRecording() {
      let cachedExperimentAlias = UserSettingsService.sharedInstance.getCurrentExperimentAlias()
      
      var cachedSessionMode = SessionViewController.SessionMode.CONNECT
      if UserSettingsService.sharedInstance.getCurrentSessionIsDeviceInitiator() {
        cachedSessionMode = SessionViewController.SessionMode.START
      }
      
      self.navigateToSessionViewController(uniqueId: cachedUniqueId, experimentId: cachedExperimentId, experimentAlias: cachedExperimentAlias, sessionId: cachedSessionId, cachedSessionMode: cachedSessionMode, immediatelyStart: true) // Parent view controller
      
      SCLAlertView().showTitle(
        "Session", // Title of view
        subTitle: "Resuming last session", // String of view
        duration: 10, // Duration to show before closing automatically, default: 2.0
        completeText: "OK", // Optional button value, default: ""
        style: SCLAlertViewStyle.success // Styles - see below.
      )
    }
  }
  
  func onGenericButtonTouchDown(_ sender: UIButton!){
      sender.backgroundColor=UIColor.white;
      sender.setTitleColor(self.genericUIColor, for: .normal);
      sender.layer.borderColor = self.genericUIColor.cgColor;
  }
  
  func onGenericButtonReset(_ sender: UIButton!){
      sender.backgroundColor=genericUIColor;
      sender.setTitleColor(UIColor.white, for: .normal);
  }
  
  func onStartButtonPress(_ sender: UIButton!){
    self.onGenericButtonReset(sender);
    
    let experimentConnectVC: ExperimentConnectViewController = ExperimentConnectViewController(style: UITableViewStyle.plain);
    experimentConnectVC.setSessionMode(sessionMode: SessionViewController.SessionMode.START)
    if let nc = self.navigationController {
      nc.pushViewController(experimentConnectVC, animated: true);
    }
  }
  
  func onConnectButtonPress(_ sender: UIButton!){
    self.onGenericButtonReset(sender);
    
    let experimentConnectVC: ExperimentConnectViewController = ExperimentConnectViewController(style: UITableViewStyle.plain);
    experimentConnectVC.setSessionMode(sessionMode: SessionViewController.SessionMode.CONNECT)
    if let nc = self.navigationController {
      nc.pushViewController(experimentConnectVC, animated: true);
    }
    //let navigationController: UINavigationController = UINavigationController()
    //navigationController.pushViewController(mainViewController, animated: false)
  }
  
  func navigateToSessionViewController(uniqueId: String, experimentId: String, experimentAlias: String?, sessionId: String, cachedSessionMode: SessionViewController.SessionMode, immediatelyStart: Bool) -> SessionViewController{
    // navigate to session view controller.
    let sessionViewController = SessionViewController();
    sessionViewController.setCurrentSessionId(uniqueId: uniqueId, experimentId: experimentId, experimentAlias: experimentAlias, sessionId: sessionId, sessionMode: cachedSessionMode, immediatelyStart: immediatelyStart);
    self.present(sessionViewController, animated: true, completion: nil);
    return sessionViewController;
  }
  
  func onUploadButtonPress(_ Sender: UIButton!) {
    if NetworkUtilities.isConnectedToNetwork() {
      if let reachability = Reachability() {
        // Move to a background thread to do some long running work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // in a second...
          if reachability.isReachableViaWiFi {
            
            let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            
            // doc dir
            //let directoryPath = documentsPath.appendingPathComponent(path);
            
            
            let fileManager = FileManager.default;
            var error: NSError?;
            /*var success: Bool
            do {
              try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
              success = true
            } catch let error1 as NSError {
              error = error1
              success = false
            };*/
            do {
              let directoryContents = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil, options: [])
              
              let dbfolderPath = documentsPath.appendingPathComponent(UserSettingsService.DB_FOLDER_PATH);
              var folderExists: Bool = false
              var isDir : ObjCBool = false
              if fileManager.fileExists(atPath: dbfolderPath.path, isDirectory: &isDir) {
                if isDir.boolValue {
                  folderExists = true
                }
              }
              
              if folderExists == false {
                var success: Bool = false
                do {
                  try fileManager.createDirectory(at: dbfolderPath, withIntermediateDirectories: true, attributes: nil)
                  success = true
                } catch let error1 as NSError {
                  error = error1
                };
                if (!success) {
                  NSLog("Error creating data path: %@", [error!.localizedDescription]);
                }
              }
              
              var sessionRecordings: [UTESessionRecording] = UserSettingsService.sharedInstance.getSessionRecords()
              /*print("==============================================")
              print("cached session records count: \(sessionRecordings.count)")
              
              let currentPath = fileManager.currentDirectoryPath
              print("==============================================")
              print("Current path: " + currentPath)
              print("==============================================")
              print("Files are: ")
              print(directoryContents)
              print("==============================================")
              print("Enumerate: ")*/
              let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: dbfolderPath.path)!
              while let element = enumerator.nextObject() as? String {
                if element.hasSuffix(".sqlite") { // checks the extension
                  let uniqueId = element.replacingOccurrences(of: ".sqlite", with: "")
                  let exists = (sessionRecordings.filter { $0.unique_id == uniqueId }).isEmpty == false
                  if exists {
                    // The entry exists in the tracked records
                  } else {
                    // delete file that is not being tracked.
                    let dbservice = UTESessionDBService(path: UserSettingsService.DB_FOLDER_PATH, filename: uniqueId + ".sqlite", experimentId: "", sessionId: "");
                    dbservice.destroyDB()
                  }
                }
              }
              
              if sessionRecordings.count > 0 {
                // there is at least 1 recording, navigate to upload list page.
                let uploadlistPage: DataRecordingsToUploadTableViewController = DataRecordingsToUploadTableViewController(style: UITableViewStyle.plain);
                if let nc = self.navigationController {
                  nc.pushViewController(uploadlistPage, animated: true);
                }
              } else {
                let alert = UIAlertController(title: "Upload", message: "No session file to upload", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
              }
              print("==============================================")
            } catch let error as NSError {
              print(error.localizedDescription)
            }
          } else {
            self.displayAlertMustBeConnectedToWiFiForUpload()
          }
        }
      }
    } else {
      self.displayAlertMustBeConnectedToWiFiForUpload()
    }
  }
  
  func onSettingsButtonPress(_ Sender: UIButton!) {
    let storyboard = UIStoryboard(name: "SettingsStoryboard", bundle: nil)
    let settingsVC = storyboard.instantiateInitialViewController() as! SettingsViewController
    //self.present(settingsVC, animated:true, completion: nil)
    
    if let nc = self.navigationController {
      nc.pushViewController(settingsVC, animated: true);
    }
    
    /*let alert = UIAlertController(title: "Alert", message: "Navigating to Settings page.", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    self.present(alert, animated: true, completion: nil)*/
  }
  
  private func displayAlertMustBeConnectedToWiFiForUpload() {
    // must be connected to wifi network.
    let alert = UIAlertController(title: "Upload", message: "To upload recorded session files, please connect through WiFi connection", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
  
  
}

