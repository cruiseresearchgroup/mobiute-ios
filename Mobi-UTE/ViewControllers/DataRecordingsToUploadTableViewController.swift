//
//  DataRecordingsToUploadTableViewController.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 24/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import UIKit
import Alamofire
import ReachabilitySwift

class DataRecordingsToUploadTableViewController: UITableViewController, SessionFinishedHandlerProtocol {

  var sessionRecordings: [UTESessionRecording] = [UTESessionRecording]()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.delegate = self
    
    self.initUI();
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func initUI(){
    self.title = "Data Upload"
    
    reloadData()
  }
  
  func reloadData() {
    self.clearSelectedRowForAction()
    self.sessionRecordings = UserSettingsService.sharedInstance.getSessionRecords()
    self.tableView.reloadData()
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    if(self.sessionRecordings.count > 0) {
      self.tableView.backgroundView = nil;
      return 1;
    }
    else {
      
      // Display a message when the table is empty
      let messageLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height));
      
      messageLabel.text = "No data is currently available. ";
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

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.sessionRecordings.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    //var cell:UITableViewCell? = nil;
    /*let cellIdentifier = "Cell"
    
    var cell:UITableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
    if cell == nil {
      cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
    }*/
    
    //cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
    
    let cellFrame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 80.0)
    let retCell = UITableViewCell(frame: cellFrame)
    
    let textLabel = UILabel(frame: CGRect(x: 10.0, y: 0, width: UIScreen.main.bounds.width - 20.0, height: 70.0 - 4.0))
    textLabel.textColor = UIColor.black
    
    let row = indexPath.row;
    let recording: UTESessionRecording = self.sessionRecordings[row]
    textLabel.lineBreakMode = .byWordWrapping // or NSLineBreakMode.ByWordWrapping
    textLabel.numberOfLines = 0
    textLabel.text = (recording.experiment_alias ?? recording.experiment_id!) //+ "_\(recording.session_id!)]"
    if let sessionId = recording.session_id {
      var sessionToDisplay = sessionId
      if sessionId == "" {
        sessionToDisplay = "Cached Session"
      }
      textLabel.text! += "\nSession: \(sessionToDisplay)"
    }
    if let datetime = recording.created_at {
      let formatter = DateFormatter()
      formatter.dateStyle = DateFormatter.Style.long
      formatter.timeStyle = DateFormatter.Style.medium
      let formatedDisplayForCreatedAt: String = formatter.string(from: Date(timeIntervalSince1970: datetime))
      textLabel.text! += "\n[" + formatedDisplayForCreatedAt + "]"
    }
    retCell.addSubview(textLabel)
    retCell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
    return retCell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
  {
    return 70.0
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  var selectedRowForAction: Int? //let recording: UTESessionRecording = self.sessionRecordings[row]
  var selectedRowDbService: UTESessionDBService?
  var selectedRecording: UTESessionRecording?
  func clearSelectedRowForAction() {
    self.selectedRowForAction = nil
    self.selectedRowDbService = nil
    self.selectedRecording = nil
  }
  
  // MARK: - Action
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let row = indexPath.row;

    let upload = UITableViewRowAction(style: .normal, title: "Upload") { action, index in
      self.selectedRowForAction = row
      self.guardBeforeUpload()
      self.setEditing(false, animated: true)
    }
    upload.backgroundColor = UIColor.blue
    
    let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
      self.selectedRowForAction = row
      // delete
      let recording: UTESessionRecording = self.sessionRecordings[row]
      if let uniqueId = recording.unique_id, let experimentId = recording.experiment_id, let sessionId = recording.session_id {
        
        var sessionDisplay: String = sessionId
        if sessionDisplay.isEmpty {
          sessionDisplay = "Cached Session"
        }
        
        var message = "Are you sure you want to delete this data?\n"
        message += "Experiment: " + (recording.experiment_alias ?? experimentId) + "\n"
        message += "Session: " + sessionDisplay + "\n"
        let filepath = self.getFilePath(uniqueId: uniqueId)
        if FileManager().fileExists(atPath: filepath) {
          let filesize = self.getFileSize(filepath: filepath)
          message += "Size: " + filesize + "\n"
        } else {
          self.handleSuccessfullFinishSession(destroyRecord: true, didUploadData: false, failedApiRequest: false)
          return
        }
        
        if let datetime = recording.created_at {
          let formatter = DateFormatter()
          formatter.dateStyle = DateFormatter.Style.long
          formatter.timeStyle = DateFormatter.Style.medium
          let formatedDisplayForCreatedAt: String = formatter.string(from: Date(timeIntervalSince1970: datetime))
          message += "Created on: " + formatedDisplayForCreatedAt + "\n"
        }
        
        let confirmDeleteAlert = UIAlertController(title: "Delete Session Data", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        confirmDeleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
          // delete file first
          let dbservice = UTESessionDBService(path: UserSettingsService.DB_FOLDER_PATH, filename: uniqueId + ".sqlite", experimentId: experimentId, sessionId: sessionId)
          dbservice.destroyDB()
          
          if sessionId.isEmpty == false {
            // try to close session. 
            var dataUploadService: UTEUploadDataService = UTEUploadDataService(vc: self, handler: self)
            var viewtoDisplayLoadingNotification: UIView = self.view
            if let superview = self.view.superview {
              viewtoDisplayLoadingNotification = superview
            }
            
            dataUploadService.loadingNotification = MBProgressHUD.showAdded(to: viewtoDisplayLoadingNotification, animated: true)
            dataUploadService.loadingNotification?.mode = MBProgressHUDMode.indeterminate
            dataUploadService.loadingNotification?.label.text = "Loading"
            UserSettingsService.sharedInstance.deleteSessionRecordSynced(uniqueId: uniqueId)
            dataUploadService.closeSession(currentExperimentId: experimentId, currentSessionId: sessionId, didUploadData: false)
          } else {
            self.handleSuccessfullFinishSession(destroyRecord: true, didUploadData: false, failedApiRequest: false)
          }
        }))
        
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
          //println("Handle Cancel Logic here")
        }))
        
        self.present(confirmDeleteAlert, animated: true, completion: nil)
      }
      
      
      
    }
    delete.backgroundColor = UIColor.red
    
    return [delete, upload]
  }
  
  func getFilePath(uniqueId: String) -> String {
    let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    let dbfolderPath = documentsPath.appendingPathComponent(UserSettingsService.DB_FOLDER_PATH)
    let dbfilePath = dbfolderPath.appendingPathComponent(uniqueId + ".sqlite")
    return dbfilePath.path
  }
  
  func getFileSize(filepath: String) -> String {
    let fileSize = (try! FileManager.default.attributesOfItem(atPath: filepath)[FileAttributeKey.size] as! NSNumber).uint64Value
    
    var size = fileSize/1024
    if size >= 1024 {
      size = size/1024
      return "\(size) Mb"
    } else {
      return "\(size) Kb"
    }
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    // the cells you would like the actions to appear needs to be editable
    return true
  }
  
  // Override to support editing the table view.
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    /*if editingStyle == .delete {
     // Delete the row from the data source
     //tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     } */
  }
  
  /*func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
    var uploadAction = UITableViewRowAction(style: .Default, title: "Upload",handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
      // self.tableView.setEditing(false, animated: false)
      }
    )
    uploadAction.backgroundColor = UIColor.lightGrayColor()
    
    var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete",
                                            handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
                                              tableView.deleteRows(at: [indexPath], with: .fade)
                                              //self.deleteModelAt(indexPath.row)
                                              //self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic);
      }
    );
    deleteAction.backgroundColor = UIColor.redColor()
    
    return [uploadAction, deleteAction]
  }*/

  /*
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

      // Configure the cell...

      return cell
  }
  */

  /*
  // Override to support conditional editing of the table view.
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
      // Return false if you do not want the specified item to be editable.
      return true
  }
  */
  

  /*
  // Override to support rearranging the table view.
  override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

  }
  */

  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
      // Return false if you do not want the item to be re-orderable.
      return true
  }
  */

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // Get the new view controller using segue.destinationViewController.
      // Pass the selected object to the new view controller.
  }
  */
  
  func guardBeforeUpload() {
    if NetworkUtilities.isConnectedToNetwork() {
      if let reachability = Reachability() {
        // Move to a background thread to do some long running work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // in a second...
          if reachability.isReachableViaWiFi {
            // upload
            if let row = self.selectedRowForAction {
              let recording: UTESessionRecording = self.sessionRecordings[row]
              self.selectedRecording = recording
              if let uniqueId = recording.unique_id, let experimentId = recording.experiment_id, let sessionId = recording.session_id {
                self.selectedRowDbService = UTESessionDBService(path: UserSettingsService.DB_FOLDER_PATH, filename: uniqueId + ".sqlite", experimentId: experimentId, sessionId: sessionId)
                let uploaderService: UTEUploadDataService = UTEUploadDataService(vc: self, handler: self)
                uploaderService.uploadData(uniqueId: uniqueId, experimentId: (self.selectedRecording?.experiment_id)!, sessionId: (self.selectedRecording?.session_id)!, isInitiator: recording.is_initiator, dbService: self.selectedRowDbService!)
              }
            }
          } else {
            self.clearSelectedRowForAction()
            self.displayAlertMustBeConnectedToWiFiForUpload()
          }
        }
      }
    } else {
      self.clearSelectedRowForAction()
      self.displayAlertMustBeConnectedToWiFiForUpload()
    }
  }
  
  func handleSuccessfullFinishSession(destroyRecord: Bool, didUploadData: Bool, failedApiRequest: Bool) {
    print("handled succcess finish session")
    if destroyRecord {
      // destroy local db.
      if let row = self.selectedRowForAction {
        let recording: UTESessionRecording = self.sessionRecordings[row]
        if let uniqueId = recording.unique_id, let experimentId = recording.experiment_id, let sessionId = recording.session_id {
          let dbservice = UTESessionDBService(path: UserSettingsService.DB_FOLDER_PATH, filename: uniqueId + ".sqlite", experimentId: experimentId, sessionId: sessionId);
          dbservice.destroyDB()
          
          UserSettingsService.sharedInstance.deleteSessionRecordSynced(uniqueId: uniqueId)
        }
      }
    }
    
    self.reloadData()
    
    if failedApiRequest == false {
      var message = ""
      if didUploadData {
        message += "File has been successfully uploaded"
      } else {
        message += "File has been successfully removed"
      }
      let alert = UIAlertController(title: "Info", message:message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.present(alert, animated: true){}
    }
  }
  
  private func displayAlertMustBeConnectedToWiFiForUpload() {
    // must be connected to wifi network.
    let alert = UIAlertController(title: "Upload", message: "To upload recorded session files, please connect through WiFi connection", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }

}
