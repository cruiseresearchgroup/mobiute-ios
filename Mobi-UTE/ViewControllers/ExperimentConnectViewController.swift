//
//  ExperimentConnectViewController.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 3/06/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON

class ExperimentConnectViewController: UITableViewController {
  
  
  
  private var experimentList: [[String:AnyObject]] = []
  private var tempExperimentList: [[String:AnyObject]] = []
  var sessionMode: SessionViewController.SessionMode?;
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    
    self.initUI();
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func setSessionMode(sessionMode: SessionViewController.SessionMode) {
    self.sessionMode = sessionMode;
  }
  
  var statusButton: UIBarButtonItem?
  
  func setStatusBarButtonOffline() {
    if let statButton = self.statusButton {
      statButton.title = "Offline"
      statButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.red], for: .normal)
    }
  }
  
  func setStatusBarButtonOnline() {
    if let statButton = self.statusButton {
      statButton.title = "Online"
      statButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.green], for: .normal)
    }
  }
  
  func initUI(){
    self.statusButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.plain, target: nil, action: nil)
    navigationItem.rightBarButtonItem = statusButton
    self.setStatusBarButtonOffline()
    self.title = "Experiment List"
    
    /*let headerView: UIView = UIView();
    self.tableView.tableHeaderView = headerView;
    headerView.snp_makeConstraints { make in
    make.width.equalTo(self.tableView.snp_width);
    make.height.equalTo(60);
    }
    
    let backButton: UIButton = UIButton();
    backButton.setTitle("<< Back", forState: .Normal);
    backButton.backgroundColor=UIColor.purpleColor();
    backButton.titleLabel!.textAlignment=NSTextAlignment.Center;
    backButton.addTarget(self, action: "onBackButtonPress:", forControlEvents: .TouchUpInside);
    headerView.addSubview(backButton);
    backButton.snp_makeConstraints { make in
    make.width.equalTo(headerView.snp_width);
    make.height.equalTo(40);
    make.top.equalTo(headerView.snp_top).with.offset(20);
    }
    
    // reassign table header.
    self.tableView.tableHeaderView!.frame.size.height = 60;
    self.tableView.tableHeaderView = headerView;*/
    
    self.refreshControl = UIRefreshControl();
    self.refreshControl!.backgroundColor = UIColor.gray;
    self.refreshControl!.tintColor = UIColor.white;
    self.refreshControl?.addTarget(self, action: #selector(ExperimentConnectViewController.requestLatestExperimentIDList), for: UIControlEvents.valueChanged)
    
    requestLatestExperimentIDList();
  }
  
  func onBackButtonPress(sender: UIButton!){
    let navigateBackToMainVC = MainViewController();
    self.present(navigateBackToMainVC, animated: true, completion: nil);
  }
  
  // #pragma mark - Table view data source
  
  func getExperimentIDList() -> [String] {
    var list: [String] = []
    if self.experimentList.count > 0 {
      for (index, value) in self.experimentList.enumerated() {
        var valueToDisplay: String = "NONE"
        if let alias = value["talias"] as? String {
          if alias.isEmpty == false {
            valueToDisplay = alias
          }
        }
        
        if valueToDisplay == "NONE" {
          valueToDisplay = value["experiment_id"] as! String
        }
        
        list.append(valueToDisplay)
      }
    }
    
    return list
  }
  
  func loadCachedExperiments() {
    self.tempExperimentList = []
    
    // load from cached experiment
    let cachedExperiments = UserSettingsService.sharedInstance.getCachedExperiments()
    for cachedExperiment in cachedExperiments {
      if let expId = cachedExperiment.experiment_id, let uid = cachedExperiment.uid {
        var dict: [String: AnyObject] = [String: AnyObject]()
        dict["experiment_id"] = expId as AnyObject?
        dict["uid"] = uid as AnyObject?
        if let alias = cachedExperiment.experiment_alias {
          dict["talias"] = alias as AnyObject?
        }
        
        if let title = cachedExperiment.title {
          dict["title"] = title as AnyObject?
        }
        
        if let desc = cachedExperiment.desc {
          dict["description"] = desc as AnyObject?
        }
        
        dict["cached"] = true as AnyObject?
        
        tempExperimentList.append(dict)
      }
    }
  }
  
  func requestLatestExperimentIDList() {
    self.loadCachedExperiments()
    
    if self.experimentList.count == 0 {
      self.reloadData()
    }
    
    // check if network connection exist
    if(!NetworkUtilities.isConnectedToNetwork()) {
      self.setStatusBarButtonOffline();
      self.finishPullToRefresh();
      if self.tempExperimentList.count == 0 {
        let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        self.present(alert, animated: true){}
      }
      
      return;
    }
    
    let url = ServerSettingsService.sharedInstance.baseUrl()
    if let urlRequest = URL(string: url)?.appendingPathComponent("api/experiment/list") {
      
      // display loading view before sending HTTP request to create new session
      /*var mutableURLRequest = URLRequest(url: urlRequest)
      let headers: [String: String]? = [
        "Accept": "application/json"
      ]*/
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
      
      urlRequest.timeoutInterval = 5 * 60
      
      Alamofire.request(urlRequest)
        //.validate(contentType: ["application/json"])
        .responseJSON {
        
        response in
        
        if (response.response == nil) {
          self.setStatusBarButtonOffline();
          if self.tempExperimentList.count == 0 {
            let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
          }
          self.finishPullToRefresh();
          return;
        }
        
        if let alamoResponse = response.response as HTTPURLResponse!{
          if(alamoResponse.statusCode != 200) {
            self.finishPullToRefresh();
          }
          
          switch alamoResponse.statusCode {
          case 200: break;
          case 401:
            self.setStatusBarButtonOffline();
            if self.tempExperimentList.count == 0 {
              let alert = UIAlertController(title: "Error", message:"Unauthorized request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
            }
            return;
          default:
            self.setStatusBarButtonOffline();
            if self.tempExperimentList.count == 0 {
              let alert = UIAlertController(title: "Error", message:"Error sending request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
            }
            return;
          }
        }
        
        // handle JSON (response)
        self.setStatusBarButtonOnline();
        if let jsonResponse = response.result.value as? [String: AnyObject] {
          if let experimentListFromServer = jsonResponse["experiments"] as? [[String: AnyObject]] {
            for experiment: [String: AnyObject] in experimentListFromServer {
              let results = self.tempExperimentList.filter {
                ($0["experiment_id"] as? String) == (experiment["experiment_id"] as? String)
              }
              if results.isEmpty == false { // entry already exists in cached list
                continue
              }
              self.tempExperimentList.append(experiment)
            }
            self.reloadData()
          }
        }
      }
    }
  }
  
  func reloadData() {
    self.experimentList = tempExperimentList
    self.tableView.reloadData()
    
    self.finishPullToRefresh()
  }
  
  func finishPullToRefresh(){
    if let rc = self.refreshControl {
      rc.endRefreshing();
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int{
    if(self.getExperimentIDList().count > 0) {
      self.tableView.backgroundView = nil;
      return 1;
    }
    else {
      
      // Display a message when the table is empty
      let messageLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height));
      
      messageLabel.text = "No data is currently available. Please pull down to refresh.";
      messageLabel.textColor = UIColor.gray;
      messageLabel.numberOfLines = 0;
      messageLabel.textAlignment = NSTextAlignment.center;
      messageLabel.font = UIFont(name: "Palatino-Italic", size:20);
      messageLabel.sizeToFit();
      self.tableView.backgroundView = messageLabel;
      self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
    }
    
    return 0;
  }
  
  /*override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
  return 10
  }*/
  
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.getExperimentIDList().count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    //var cell:UITableViewCell? = nil;
    let cellIdentifier = "Cell"
    
    var cell:UITableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
    if cell == nil {
      cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
    }
    
    //cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
    
    let row = indexPath.row
    print("rownumber:")
    print(row)
    cell!.textLabel!.text = self.getExperimentIDList()[row]
    
    return cell!
  }
  
  var otpcachingField: UITextField!
  
  func cachingOTPConfiguration(textField: UITextField!)
  {
    textField.placeholder = "OTP for caching"
    otpcachingField = textField
  }
  
  // MARK: - Action
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let row = indexPath.row;
    var arraySwipeButtons: [UITableViewRowAction] = [UITableViewRowAction]()
    
    let experimentItem = self.experimentList[row]
    if (experimentItem["cached"] as? Bool) != nil {
      let uncache: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "Uncache") { action, index in
        let uncacheConfirmationAlert = UIAlertController(title: "Uncaching Experiment", message: "Are you sure you want to uncache this experiment?", preferredStyle: UIAlertControllerStyle.alert)
        
        uncacheConfirmationAlert.addAction(UIAlertAction(title: "Uncache", style: .default, handler: { (action: UIAlertAction) in
          if let experimentId = experimentItem["experiment_id"] as? String, let uid = experimentItem["uid"] as? String {
            tableView.setEditing(false, animated: true)
            self.requestToUncacheExperiment(experimentId: experimentId, uid: uid)
          }
        }))
        
        uncacheConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
          tableView.setEditing(false, animated: true)
        }));
        
        self.present(uncacheConfirmationAlert, animated: true, completion: nil);
      }
      uncache.backgroundColor = UIColor.red
      arraySwipeButtons.append(uncache)
    } else {
      let isCacheable = experimentItem["is_cacheable"] as? Bool
      if isCacheable != nil && isCacheable == true {
        let cache: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "Cache") { action, index in
          let cacheAlert = UIAlertController(title: "Caching Experiment", message: "To cache this experiment, please provide the OTP", preferredStyle: UIAlertControllerStyle.alert)
          cacheAlert.addTextField(configurationHandler: self.cachingOTPConfiguration)
          
          cacheAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
            print("OTP to submit: \(self.otpcachingField.text)")
            tableView.setEditing(false, animated: true)
            
            // get details of experiment
            let cache: UTECachedExperiment = UTECachedExperiment()
            cache.experiment_id = self.experimentList[row]["experiment_id"] as! String?
            cache.experiment_alias = self.experimentList[row]["talias"] as! String?
            cache.title = self.experimentList[row]["title"] as! String?
            cache.desc = self.experimentList[row]["description"] as! String?
            self.requestToCacheExperiment(otp: self.otpcachingField.text!, cache: cache)
          }))
          cacheAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
          }));
          
          self.present(cacheAlert, animated: true, completion: nil);
        }
        
        cache.backgroundColor = UIColor.blue
        arraySwipeButtons.append(cache)
      } else {
        let cache: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "Cache") { action, index in
          
        }
        
        cache.backgroundColor = UIColor.gray
        arraySwipeButtons.append(cache)
      }
    }
    
    return arraySwipeButtons.isEmpty ? nil : arraySwipeButtons
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // check before assigning?
    // http request
    if let selectedExperiment: [String:AnyObject] = experimentList[indexPath.row] {
      let selectedExperimentId: String = selectedExperiment["experiment_id"] as! String;
      var selectedExperimentAlias: String? = nil
      if let alias = selectedExperiment["talias"] as? String {
        selectedExperimentAlias = alias
      }
      
      var cached = false
      if (selectedExperiment["cached"] as? Bool) != nil {
        cached = true
      }
      
      // confirmation to connect to experiment ID
      var titleToDisplay = self.sessionMode == SessionViewController.SessionMode.START ? "Create " : "Connect "
      if(cached) {
        titleToDisplay += "[Cached] "
        if self.sessionMode == SessionViewController.SessionMode.START {
          titleToDisplay += "[Initiator] "
        }
      }
      
      var formattedMessage = "Are you sure you want to %@ to this experiment?\n"
      if let title = selectedExperiment["title"] as? String {
        formattedMessage += "\nAbout: " + title + "\n"
      }
      
      if let description = selectedExperiment["description"] as? String {
        formattedMessage += "\nDetails: \n" + description
      }
      
      let connectMessage = self.sessionMode == SessionViewController.SessionMode.START ? "create new sensing session": "connect";
      let confirmationMessage = String(format: formattedMessage,
                                       connectMessage)
      let connectAlert = UIAlertController(title: titleToDisplay, message: "", preferredStyle: UIAlertControllerStyle.alert)
      
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = NSTextAlignment.left
      
      let messageText = NSMutableAttributedString(
        string: confirmationMessage,
        attributes: [
          NSParagraphStyleAttributeName: paragraphStyle,
          NSFontAttributeName : UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote),
          NSForegroundColorAttributeName : UIColor.black
        ]
      )
      
      connectAlert.setValue(messageText, forKey: "attributedMessage")
      
      connectAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
        if(self.sessionMode == SessionViewController.SessionMode.START || cached) {
          // create session
          self.createNewSession(selectedExperimentId: selectedExperimentId, experimentAlias: selectedExperimentAlias, cached: cached)
        } else if (self.sessionMode == SessionViewController.SessionMode.CONNECT) {
          // navigate to connect
          let sessionConnectVC: SessionConnnectViewController = SessionConnnectViewController(style: UITableViewStyle.plain);
          sessionConnectVC.setCurrentExperimentId(experimentId: selectedExperimentId, experimentAlias: selectedExperimentAlias, sessionMode: SessionViewController.SessionMode.CONNECT);
          if let nc = self.navigationController {
            nc.pushViewController(sessionConnectVC, animated: true);
          }
        }
      }))
      
      connectAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
      }));
      
      present(connectAlert, animated: true, completion: nil);
    }
  }
  
  func createNewSession(selectedExperimentId: String, experimentAlias: String? = nil, cached: Bool) {
    if self.sessionMode == SessionViewController.SessionMode.START && !cached {
      self.requestToCreateNewSession(selectedExperimentId: selectedExperimentId, experimentAlias: experimentAlias)
    } else if cached {
      // handleSuccessfullSessionCreation
      if let cachedExperiment: UTECachedExperiment = UserSettingsService.sharedInstance.findCachedExperimentById(experimentId: selectedExperimentId) {
        if self.sessionMode == SessionViewController.SessionMode.START {
          self.handleSuccessfullSessionCreation(selectedExperimentId: cachedExperiment.experiment_id!, experimentAlias: cachedExperiment.experiment_alias, createdSessionId: "", serverStartTimestamp: DateTimeUtilities.getCurrentTimeStamp(), settings: cachedExperiment.settings?.toDict() as [String : AnyObject]?, sessionMode: self.sessionMode!, role: SessionViewController.SESSION_ROLE_SENSING)
        } else if self.sessionMode == SessionViewController.SessionMode.CONNECT {
          let roleSelectionAlert = UIAlertController(title: "Role selection", message: nil, preferredStyle: UIAlertControllerStyle.alert)
          roleSelectionAlert.addAction(UIAlertAction(title: "Sensing", style: .default, handler: { (action: UIAlertAction) in
            self.handleSuccessfullSessionCreation(selectedExperimentId: cachedExperiment.experiment_id!, experimentAlias: cachedExperiment.experiment_alias, createdSessionId: "", serverStartTimestamp: DateTimeUtilities.getCurrentTimeStamp(), settings: cachedExperiment.settings?.toDict() as [String : AnyObject]?, sessionMode: self.sessionMode!, role: SessionViewController.SESSION_ROLE_SENSING)
          }))
          
          roleSelectionAlert.addAction(UIAlertAction(title: "Labeling", style: .default, handler: { (action: UIAlertAction) in
            self.handleSuccessfullSessionCreation(selectedExperimentId: cachedExperiment.experiment_id!, experimentAlias: cachedExperiment.experiment_alias, createdSessionId: "", serverStartTimestamp: DateTimeUtilities.getCurrentTimeStamp(), settings: cachedExperiment.settings?.toDict() as [String : AnyObject]?, sessionMode: self.sessionMode!, role: SessionViewController.SESSION_ROLE_LABELING)
          }))
          
          roleSelectionAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
          }))
          
          self.present(roleSelectionAlert, animated: true, completion: nil);
        }
      }
      
      
    }
  }
  
  func requestToCreateNewSession(selectedExperimentId: String, experimentAlias: String? = nil) {
    // check if network connection exist
    if(!NetworkUtilities.isConnectedToNetwork()) {
      let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.present(alert, animated: true){}
      return;
    }
    
    // request session ID
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/session/create") {
      
      // display loading view before sending HTTP request to create new session
      let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
      loadingNotification.mode = MBProgressHUDMode.indeterminate
      loadingNotification.label.text = "Connecting..."
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      let parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID(),
        "model": ServerSettingsService.sharedInstance.getDeviceModel(),
        "dtype": "iOS",
        "experiment_id": selectedExperimentId
      ]
      
      do {
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
      } catch {
        // No-op
      }
      
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
      
      urlRequest.timeoutInterval = 5 * 60
      
      Alamofire.request(urlRequest)
        .validate(contentType: ["application/json"])
        .responseJSON {
          
          response in
          
          // dismiss the animated loading pop up.
          loadingNotification.hide(animated: true)
          
          if (response.response == nil) {
            let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
            return;
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              let alert = UIAlertController(title: "Error", message:"Unauthorized request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
              return;
            default:
              let alert = UIAlertController(title: "Error", message:"Error sending request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
              return;
            }
          }
          
          // handle JSON (response)
          if let jsonResponse = response.result.value as? [String: AnyObject] {
            if let status = jsonResponse["status"] as? String {
              if (status == "OK") {
                let createdSessionId = jsonResponse["sessionId"] as? String
                let serverStartTime = (jsonResponse["created_at"] as? Double) ?? 0;
                // parse settings
                var settings: [String: AnyObject]? = nil;
                if jsonResponse["settings"] != nil {
                  // validate
                  /*if let settings = jsonResponse["settings"] as? [String: AnyObject] {
                   SessionSetupSettings.parse(settings)
                   let jsonvalue = JSON(jsonResponse)
                   jsonvalue.rawString()
                   }*/
                  settings = jsonResponse["settings"] as? [String: AnyObject]
                }
                
                self.handleSuccessfullSessionCreation(selectedExperimentId: selectedExperimentId, experimentAlias: experimentAlias, createdSessionId: createdSessionId ?? "", serverStartTimestamp: serverStartTime, settings: settings, sessionMode: SessionViewController.SessionMode.START, role: SessionViewController.SESSION_ROLE_SENSING);
              }
            }
          }
      }
    }
  }
  
  func handleSuccessfullSessionCreation(selectedExperimentId: String, experimentAlias: String? = nil, createdSessionId: String, serverStartTimestamp: Double, settings: [String: AnyObject]?, sessionMode: SessionViewController.SessionMode, role: Int)
  {
    if let nc = self.navigationController {
      nc.popViewController(animated: false);
      
      var settingsString: String? = nil;
      if let settingsDictionary = settings {
        settingsString = SwiftyJSON.JSON(settingsDictionary).rawString()
      }
      
      let uniqueId: String = UUID().uuidString
      var isInitiator = false
      if sessionMode == SessionViewController.SessionMode.START {
        isInitiator = true
      }
      
      UserSettingsService.sharedInstance.setCachedSessionInfo(uniqueId: uniqueId, experimentId: selectedExperimentId, experimentAlias: experimentAlias, sessionId: createdSessionId, serverStartTimeStamp: serverStartTimestamp, settings: settingsString, role: role, isInitiator: isInitiator);
      
      UserSettingsService.sharedInstance.addSessionRecord(uniqueId: uniqueId, experimentId: selectedExperimentId, experimentAlias: experimentAlias, sessionId: createdSessionId, dbpath: uniqueId + ".sqlite", isOffline: createdSessionId.isEmpty ?? true, isInitiator: isInitiator, createdAt: DateTimeUtilities.getCurrentTimeStamp())
      
      let sessionViewController = SessionViewController()
      sessionViewController.setCurrentSessionId(uniqueId: uniqueId, experimentId: selectedExperimentId, experimentAlias: experimentAlias, sessionId: createdSessionId, sessionMode: sessionMode, immediatelyStart: false)
      nc.viewControllers[nc.viewControllers.count-1].present(sessionViewController, animated: true, completion: nil)
    };
  }
  
  // attempt to make tableview header static/ absolute on the top.
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if(self.tableView.tableHeaderView != nil){
      var rect: CGRect = self.tableView.tableHeaderView!.frame;
      rect.origin.y = min(0, scrollView.contentOffset.y);
      self.tableView.tableHeaderView!.frame = rect;
    }
  }
  
  func requestToCacheExperiment(otp: String, cache: UTECachedExperiment) {
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/pairdevice") {
      
      // display loading view before sending HTTP request to create new session
      let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
      loadingNotification.mode = MBProgressHUDMode.indeterminate
      loadingNotification.label.text = "Requesting to cache..."
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      let parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID(),
        "model": ServerSettingsService.sharedInstance.getDeviceModel(),
        "dtype": "iOS",
        "experiment_id": cache.experiment_id!,
        "otp": otp
      ]
      
      do {
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
      } catch {
        // No-op
      }
      
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
      
      urlRequest.timeoutInterval = 5 * 60
      
      Alamofire.request(urlRequest)
        .validate(contentType: ["application/json"])
        .responseJSON {
          
          response in
          
          // dismiss the animated loading pop up.
          loadingNotification.hide(animated: true)
          
          if (response.response == nil) {
            let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
            return;
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              let alert = UIAlertController(title: "Error", message:"Unauthorized request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
              return;
            default:
              let alert = UIAlertController(title: "Error", message:"Error sending request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
              return;
            }
          }
          
          // handle JSON (response)
          if let jsonResponse = response.result.value as? [String: AnyObject] {
            if let status = jsonResponse["status"] as? String {
              if (status == "OK") {
                // parse settings
                var settings: [String: AnyObject]? = nil;
                if jsonResponse["settings"] != nil {
                  settings = jsonResponse["settings"] as? [String: AnyObject]
                  if let settingsNotNil = settings {
                    cache.settings = SessionSetupSettings.parseFromJson(settingsJSON: SwiftyJSON.JSON(settingsNotNil))
                  }
                }
                
                if let campaignEndAt: Double = jsonResponse["campaign_end_at"] as? Double {
                  cache.campaign_end_at = campaignEndAt
                }
                
                if let uid = jsonResponse["uid"] as? String, let serverTime = jsonResponse["server_time"] as? Double {
                  cache.uid = uid
                  cache.server_time = serverTime
                  
                  self.handleSuccessfullCacheRequest(cache: cache);
                } else {
                  let alert = UIAlertController(title: "Error", message:"Invalid request. ", preferredStyle: .alert)
                  alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
                  self.present(alert, animated: true){}
                }
              }
            }
          } else {
            let alert = UIAlertController(title: "Error", message:"Unable to cache this experiment", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
          }
      }
    }
  }
  
  func handleSuccessfullCacheRequest(cache: UTECachedExperiment) {
    let isCached = UserSettingsService.sharedInstance.cacheExperiment(cache: cache)
    if isCached {
      let alert = UIAlertController(title: "Experiment Caching", message:"The experiment has been cached successfully.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.present(alert, animated: true){}
      self.requestLatestExperimentIDList()
    } else {
      let alert = UIAlertController(title: "Error", message:"Unable to cache this experiment", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.present(alert, animated: true){}
    }
  }
  
  func requestToUncacheExperiment(experimentId: String, uid: String) {
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/unpairdevice") {
      
      // display loading view before sending HTTP request to create new session
      let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
      loadingNotification.mode = MBProgressHUDMode.indeterminate
      loadingNotification.label.text = "Requesting to uncache..."
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      let parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID(),
        "model": ServerSettingsService.sharedInstance.getDeviceModel(),
        "dtype": "iOS",
        "experiment_id": experimentId,
        "uid": uid
      ]
      
      do {
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
      } catch {
        // No-op
      }
      
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
      
      urlRequest.timeoutInterval = 5 * 60
      
      Alamofire.request(urlRequest)
        .validate(contentType: ["application/json"])
        .responseJSON {
          
          response in
          
          // dismiss the animated loading pop up.
          loadingNotification.hide(animated: true)
          
          if (response.response == nil) {
            let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
            return;
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              let alert = UIAlertController(title: "Error", message:"Unauthorized request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
              return;
            default:
              let alert = UIAlertController(title: "Error", message:"Error sending request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
              self.present(alert, animated: true){}
              return;
            }
          }
          
          // handle JSON (response)
          if let jsonResponse = response.result.value as? [String: AnyObject] {
            if let status = jsonResponse["status"] as? String {
              if (status == "OK") {
                self.handleSuccessfullUncacheRequest(experimentId: experimentId)
              }
            }
          } else {
            let alert = UIAlertController(title: "Error", message:"Unable to uncache this experiment", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
          }
      }
    }
  }
  
  func handleSuccessfullUncacheRequest(experimentId: String) {
    UserSettingsService.sharedInstance.uncacheExperimentSynced(experimentId: experimentId)
    let alert = UIAlertController(title: "Uncache Experiment", message:"The experiment has been uncached successfully.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
    self.present(alert, animated: true){}
    self.requestLatestExperimentIDList()
  }
}
