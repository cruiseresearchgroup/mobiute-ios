//
//  SessionConnectViewController.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 24/12/2014.
//  Copyright (c) 2014 RMIT University. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON

class SessionConnnectViewController: UITableViewController {
  
  var sessionMode: SessionViewController.SessionMode?;
  
  private var sessionIDList: [String] = [];
  
  private var experimentId: String?;
  
  private var experimentAlias: String?;
  
  override func viewDidLoad() {
      super.viewDidLoad()
      
      self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
      
      self.initUI();
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func setCurrentExperimentId(experimentId: String, experimentAlias: String?, sessionMode: SessionViewController.SessionMode) {
    self.experimentId = experimentId;
    self.experimentAlias = experimentAlias
    self.sessionMode = sessionMode;
  }
  
  func initUI(){
    self.title = "Session List"
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
      self.refreshControl?.addTarget(self, action: #selector(SessionConnnectViewController.requestLatestSessionIDList), for: UIControlEvents.valueChanged)
    
    requestLatestSessionIDList();
  }
  
  func onBackButtonPress(sender: UIButton!){
      let navigateBackToMainVC = MainViewController();
      self.present(navigateBackToMainVC, animated: true, completion: nil);
  }
  
  // #pragma mark - Table view data source
  
  func getSessionIDList() -> [String] {
      return self.sessionIDList;
  }
    
  func requestLatestSessionIDList() {
    // check if network connection exist
    if(!NetworkUtilities.isConnectedToNetwork()) {
      self.finishPullToRefresh();
      
      let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.present(alert, animated: true){}
      return;
    }
    
    // request session ID
    let baseurl = ServerSettingsService.sharedInstance.baseUrl()
    if let urlRequest = NSURL(string: baseurl)?.appendingPathComponent("api/session/list") {
      // display loading view before sending HTTP request to create new session
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      let parameters: Parameters = [
        //"did": ServerSettingsService.sharedInstance.getDeviceUDID(),
        //"dtype": "iOS",
        "experiment_id": self.experimentId ?? ""
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
        
        if (response.response == nil) {
          let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
          self.present(alert, animated: true){}
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
            let alert = UIAlertController(title: "Error", message:"Unauthorized request", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
            self.finishPullToRefresh();
            return;
          default:
            let alert = UIAlertController(title: "Error", message:"Error sending request", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true){}
            self.finishPullToRefresh();
            return;
          }
        }
        
        // handle JSON (response)
        if let jsonResponse = response.result.value as? NSDictionary {
          if let sessionIdList = jsonResponse["sessions"] as? [String] {
            self.sessionIDList = [] + sessionIdList;
            self.reloadData();
          }
        }
      }
    }
  }
  
  func reloadData() {
    self.tableView.reloadData();
      
    self.finishPullToRefresh();
  }
  
  func finishPullToRefresh(){
    if let rc = self.refreshControl {
      rc.endRefreshing();
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
      if(self.getSessionIDList().count > 0) {
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
      return self.getSessionIDList().count
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
    
    let row = indexPath.row;
    cell!.textLabel!.text = self.getSessionIDList()[row];
    
    return cell!;
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // check before assigning?
    // http request
    let selectedSessionId: String = self.getSessionIDList()[indexPath.row];
    
    // confirmation to connect to session ID
    let confirmationMessage = String(format: "Are you sure you want to connect to session [%@]?", selectedSessionId)
    let connectAlert = UIAlertController(title: "Connect", message: confirmationMessage, preferredStyle: UIAlertControllerStyle.alert)
    
    connectAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
      self.connectAskForRole(selectedSessionId: selectedSessionId)
    }))
    
    connectAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
    }));
    
    self.present(connectAlert, animated: true, completion: nil);
  }
  
  func connectAskForRole(selectedSessionId: String) {
    let roleSelectionAlert = UIAlertController(title: "Connect - " + selectedSessionId, message: nil, preferredStyle: UIAlertControllerStyle.alert)
    roleSelectionAlert.addAction(UIAlertAction(title: "Sensing", style: .default, handler: { (action: UIAlertAction) in
      self.connectToSession(selectedSessionId: selectedSessionId, role: SessionViewController.SESSION_ROLE_SENSING);
    }))
    
    roleSelectionAlert.addAction(UIAlertAction(title: "Labeling", style: .default, handler: { (action: UIAlertAction) in
      self.connectToSession(selectedSessionId: selectedSessionId, role: SessionViewController.SESSION_ROLE_LABELING);
    }))
    
    roleSelectionAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
    }))
    
    self.present(roleSelectionAlert, animated: true, completion: nil);
  }
  
  func connectToSession(selectedSessionId: String, role: Int) {
    // check if network connection exist
    if(!NetworkUtilities.isConnectedToNetwork()) {
      let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.present(alert, animated: true){}
      return;
    }
    
    // request session ID
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/session/connect") {
      
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
        "session_id": selectedSessionId,
        "experiment_id": self.experimentId ?? ""
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
        if let jsonResponse = response.result.value as? NSDictionary {
          if let status = jsonResponse["status"] as? String {
            if (status == "OK") {
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
              self.handleSuccessfullSessionConnection(selectedSessionId: selectedSessionId, selectedRole: role, serverStartTimestamp: serverStartTime, settings: settings);
            }
          }
        }
      }
    }
  }
  
  func handleSuccessfullSessionConnection(selectedSessionId: String, selectedRole: Int, serverStartTimestamp: Double, settings: [String: AnyObject]?) {
    if let nc = self.navigationController {
      nc.popViewController(animated: false); // move back to experiment list by popping out the current session list view.
      nc.popViewController(animated: false); // move back to main view by popping out the experiment list view.
      
      var settingsString: String? = nil;
      if let settingsDictionary = settings {
        settingsString = SwiftyJSON.JSON(settingsDictionary).rawString();
      }
      
      let uniqueId: String = UUID().uuidString
      
      UserSettingsService.sharedInstance.setCachedSessionInfo(uniqueId: uniqueId, experimentId: self.experimentId ?? "", experimentAlias: experimentAlias, sessionId: selectedSessionId, serverStartTimeStamp: serverStartTimestamp, settings: settingsString, role: selectedRole, isInitiator: false)
      
      UserSettingsService.sharedInstance.addSessionRecord(uniqueId: uniqueId, experimentId: experimentId!, experimentAlias: experimentAlias, sessionId: selectedSessionId, dbpath: uniqueId + ".sqlite", isOffline: false, isInitiator: false, createdAt: DateTimeUtilities.getCurrentTimeStamp())
      let sessionViewController = SessionViewController();
      sessionViewController.setCurrentSessionId(uniqueId: uniqueId, experimentId: self.experimentId ?? "", experimentAlias: experimentAlias, sessionId: selectedSessionId, sessionMode: SessionViewController.SessionMode.CONNECT, immediatelyStart: false);
      nc.viewControllers[nc.viewControllers.count-1].present(sessionViewController, animated: true, completion: nil);
      
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
}
