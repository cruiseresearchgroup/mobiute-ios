//
//  UTEUploadDataService.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 30/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation
import Alamofire

public class UTEUploadDataService {
  private var isSendingData: Bool = false;
  var loadingNotification: MBProgressHUD?
  var uniqueId: String?
  var experimentId: String?
  var sessionId: String?
  var isInitiator: Bool = false
  var dbService: UTESessionDBService?
  var handler: SessionFinishedHandlerProtocol
  
  var vc:UIViewController
  init(vc: UIViewController, handler: SessionFinishedHandlerProtocol) {
    self.vc = vc
    self.handler = handler
  }
  
  func setNotSendingData() {
    self.isSendingData = false;
  }
  
  func uploadData(uniqueId: String, experimentId: String, sessionId: String?, isInitiator: Bool, dbService: UTESessionDBService) {
    self.uniqueId = uniqueId
    self.experimentId = experimentId
    self.sessionId = sessionId
    self.isInitiator = isInitiator
    self.dbService = dbService
    self.sendChunkSensorInfosGeneric(isRecursive: true); // unsuccessful connection will display alert view.
  }
  
  // MARK: Send Session Sensor Infos
  
  func sendChunkSensorInfosGeneric(isRecursive: Bool = false) {
    // display loading view before sending HTTP request to finish the session
    var viewtoDisplayLoadingNotification: UIView = self.vc.view
    if let superview = self.vc.view.superview {
      viewtoDisplayLoadingNotification = superview
    }
    
    loadingNotification = MBProgressHUD.showAdded(to: viewtoDisplayLoadingNotification, animated: true)
    loadingNotification?.mode = MBProgressHUDMode.indeterminate
    loadingNotification?.label.text = "Loading"
    
    self.isSendingData = true;
    if(self.dbService == nil) {
      self.setNotSendingData()
      return;
    }
    
    let result: AnyObject? = self.dbService!.fetchSessionInfosByLimit(recordlimit: UserSettingsService.RETRIEVAL_LIMIT_FOR_SENDING_INFOSESSION) as AnyObject?;
    
    if(isRecursive) {
      if(result!.count == 0) {
        // proceed to label data upload.
        self.dismissLoadingMessage()
        self.setNotSendingData();
        print("start sending interval labels")
        self.sendChunkBluetoothInfosGeneric(isRecursive: true); // unsuccessful connection will display alert view.
        return;
      }
    }
    
    self.sendStreamSessionInfos(infosToSend: result as! [Dictionary<String, AnyObject>], attempt: 1, needUserFeedBack: isRecursive, isRecursive: isRecursive);
  }
  
  func sendStreamSessionInfos(infosToSend: [Dictionary<String, AnyObject>], attempt: Int, needUserFeedBack: Bool = true, isRecursive: Bool = false) {
    if (attempt == 6) {
      self.setNotSendingData();
      if(isRecursive) {
        self.sendStreamSessionInfos(infosToSend: infosToSend, attempt: 1, isRecursive: isRecursive);
      }
      return;
    }
    
    if(!NetworkUtilities.isConnectedToNetwork()) {
      self.setNotSendingData();
      if (needUserFeedBack)
      {
        let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
          // finish session
          self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
        })
        self.vc.present(alert, animated: true){}
      } else {
        // finish session
        self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
      }
      
      return;
    }
    
    let isOfflineMode = self.sessionId == nil || (self.sessionId?.isEmpty)!
    
    print("sending chunk session sensors info")
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/session/sensors/submit") {
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      var parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID() as AnyObject,
        "model": ServerSettingsService.sharedInstance.getDeviceModel() as AnyObject,
        "dtype": "iOS" as AnyObject,
        "experiment_id": self.experimentId! as AnyObject,
        "sensor_infos": infosToSend as AnyObject
      ]
      
      if isOfflineMode {
        if let cached: UTECachedExperiment = UserSettingsService.sharedInstance.findCachedExperimentById(experimentId: self.experimentId!) {
          parameters["uid"] = cached.uid! as AnyObject
          parameters["is_initiator"] = self.isInitiator
        }
      } else {
        // session is created through online mode.
        parameters["session_id"] = self.sessionId! as AnyObject
      }
      
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
          self.dismissLoadingMessage()
          
          if (response.response == nil) {
            self.setNotSendingData();
            if needUserFeedBack {
              let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              })
              self.vc.present(alert, animated: true){}
            } else {
              // finish session
              self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
            }
            
            return
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              // finish session
              self.setNotSendingData();
              if needUserFeedBack {
                let alert = UIAlertController(title: "Error", message:"Unauthorized access. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            case 500:
              self.setNotSendingData();
              if needUserFeedBack {
                let alert = UIAlertController(title: "Server Error", message:"Server error. Please contact the administrator. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            default:
              self.setNotSendingData();
              if needUserFeedBack {
                let title = "Error [Code:" + String(alamoResponse.statusCode) + "]"
                var message = "Error sending request."
                switch response.result {
                  case .failure(let error):
                    message = error as! String
                    break
                  default: break
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            }
          }
          
          print("finished sending chunk sensors info")
          
          if let jsonResponse = response.result.value as? [String: AnyObject] {
            // check the status response from server
            if let status = jsonResponse["status"] as? String {
              if (status == "OK") {
                let thelastEntryTimestamp = infosToSend[infosToSend.count - 1]["t"] as! Double
                self.dbService!.deleteSessionInfosBefore(thetime: thelastEntryTimestamp);
                
                UserSettingsService.sharedInstance.clearCachedSessionInfoChunk();
                
                if isOfflineMode {
                  if let sessionId = jsonResponse["session_id"] as? String {
                    self.sessionId = sessionId
                    self.dbService!.updateSessionId(sessionId: sessionId)
                    UserSettingsService.sharedInstance.updateSessionRecordSynced(uniqueId: self.uniqueId!, sessionIdForUpdate: sessionId)
                  }
                }
                
                self.setNotSendingData();
                
                if(isRecursive) {
                  ThreadUtilities.delay(0.01) {
                    self.sendChunkSensorInfosGeneric(isRecursive: true); // unsuccessful connection will display alert view.
                  }
                }
              } else {
                if (jsonResponse["code"] as? Int) == 404 {
                  if needUserFeedBack {
                    let alert = UIAlertController(title: "Error", message: "Initiator session has not been uploaded yet. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                      // finish session
                      self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                    })
                    self.vc.present(alert, animated: true){}
                  } else {
                    // finish session
                    self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                  }
                } else {
                  if needUserFeedBack {
                    let alert = UIAlertController(title: "Error", message: "Error in submitting data. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                      // finish session
                      self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                    })
                    self.vc.present(alert, animated: true){}
                  } else {
                    // finish session
                    self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                  }
                }
              }
            }
          }
      }
    }
  }
  
  // MARK: Bluetooth Upload
  
  func sendChunkBluetoothInfosGeneric(isRecursive: Bool = false) {
    // display loading view before sending HTTP request to finish the session
    var viewtoDisplayLoadingNotification: UIView = self.vc.view
    if let superview = self.vc.view.superview {
      viewtoDisplayLoadingNotification = superview
    }
    
    loadingNotification = MBProgressHUD.showAdded(to: viewtoDisplayLoadingNotification, animated: true)
    loadingNotification?.mode = MBProgressHUDMode.indeterminate
    loadingNotification?.label.text = "Loading"
    
    self.isSendingData = true;
    if(self.dbService == nil) {
      self.setNotSendingData()
      return;
    }
    
    let result: AnyObject? = self.dbService!.fetchBluetoothInfosByLimit(recordlimit: UserSettingsService.RETRIEVAL_LIMIT_FOR_SENDING_BLUETOOTHINFO) as AnyObject?;
    
    if(isRecursive) {
      if(result!.count == 0) {
        // proceed to label data upload.
        self.dismissLoadingMessage()
        self.setNotSendingData();
        print("start sending interval labels")
        self.sendChunkIntervalLabelsGeneric(isRecursive: true); // unsuccessful connection will display alert view.
        return;
      }
    }
    
    self.sendStreamBluetoothInfos(infosToSend: result as! [Dictionary<String, AnyObject>], attempt: 1, needUserFeedBack: isRecursive, isRecursive: isRecursive);
  }
  
  func sendStreamBluetoothInfos(infosToSend: [Dictionary<String, AnyObject>], attempt: Int, needUserFeedBack: Bool = true, isRecursive: Bool = false) {
    if (attempt == 6) {
      self.setNotSendingData();
      if(isRecursive) {
        self.sendStreamBluetoothInfos(infosToSend: infosToSend, attempt: 1, isRecursive: isRecursive);
      }
      return;
    }
    
    if(!NetworkUtilities.isConnectedToNetwork()) {
      self.setNotSendingData();
      if (needUserFeedBack)
      {
        let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
          // finish session
          self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
        })
        self.vc.present(alert, animated: true){}
      } else {
        // finish session
        self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
      }
      
      return;
    }
    
    let isOfflineMode = self.sessionId == nil || (self.sessionId?.isEmpty)!
    
    print("sending chunk session bluetooth info")
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/session/bluetooths/submit") {
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      var parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID() as AnyObject,
        "model": ServerSettingsService.sharedInstance.getDeviceModel() as AnyObject,
        "dtype": "iOS" as AnyObject,
        "experiment_id": self.experimentId! as AnyObject,
        "bluetooth_infos": infosToSend as AnyObject
      ]
      
      if isOfflineMode {
        if let cached: UTECachedExperiment = UserSettingsService.sharedInstance.findCachedExperimentById(experimentId: self.experimentId!) {
          parameters["uid"] = cached.uid! as AnyObject
          parameters["is_initiator"] = self.isInitiator
        }
      } else {
        // session is created through online mode.
        parameters["session_id"] = self.sessionId! as AnyObject
      }
      
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
          self.dismissLoadingMessage()
          
          if (response.response == nil) {
            self.setNotSendingData();
            if needUserFeedBack {
              let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              })
              self.vc.present(alert, animated: true){}
            } else {
              // finish session
              self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
            }
            
            return
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              // finish session
              self.setNotSendingData();
              if needUserFeedBack {
                let alert = UIAlertController(title: "Error", message:"Unauthorized access. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            case 500:
              self.setNotSendingData();
              if needUserFeedBack {
                let alert = UIAlertController(title: "Server Error", message:"Server error. Please contact the administrator. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            default:
              self.setNotSendingData();
              if needUserFeedBack {
                let title = "Error [Code:" + String(alamoResponse.statusCode) + "]"
                var message = "Error sending request."
                switch response.result {
                case .failure(let error):
                  message = error as! String
                  break
                default: break
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            }
          }
          
          print("finished sending chunk bluetooth info")
          
          if let jsonResponse = response.result.value as? [String: AnyObject] {
            // check the status response from server
            if let status = jsonResponse["status"] as? String {
              if (status == "OK") {
                let thelastEntryTimestamp = infosToSend[infosToSend.count - 1]["t"] as! Double
                self.dbService!.deleteBluetoothInfosBefore(thetime: thelastEntryTimestamp, lastIdToDelete: infosToSend[infosToSend.count - 1]["id"] as! UInt64)
                
                if isOfflineMode {
                  if let sessionId = jsonResponse["session_id"] as? String {
                    self.sessionId = sessionId
                    self.dbService!.updateSessionId(sessionId: sessionId)
                    UserSettingsService.sharedInstance.updateSessionRecordSynced(uniqueId: self.uniqueId!, sessionIdForUpdate: sessionId)
                  }
                }
                
                self.setNotSendingData();
                
                if(isRecursive) {
                  ThreadUtilities.delay(0.01) {
                    self.sendChunkBluetoothInfosGeneric(isRecursive: true); // unsuccessful connection will display alert view.
                  }
                }
              } else {
                if (jsonResponse["code"] as? Int) == 404 {
                  if needUserFeedBack {
                    let alert = UIAlertController(title: "Error", message: "Initiator session has not been uploaded yet. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                      // finish session
                      self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                    })
                    self.vc.present(alert, animated: true){}
                  } else {
                    // finish session
                    self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                  }
                } else {
                  if needUserFeedBack {
                    let alert = UIAlertController(title: "Error", message: "Error in submitting data. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                      // finish session
                      self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                    })
                    self.vc.present(alert, animated: true){}
                  } else {
                    // finish session
                    self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                  }
                }
              }
            }
          }
      }
    }
  }
  
  // MARK: Interval Label Upload
  
  func sendChunkIntervalLabelsGeneric(isRecursive: Bool = false) {
    // display loading view before sending HTTP request to finish the session
    var viewtoDisplayLoadingNotification: UIView = self.vc.view
    if let superview = self.vc.view.superview {
      viewtoDisplayLoadingNotification = superview
    }
    
    loadingNotification = MBProgressHUD.showAdded(to: viewtoDisplayLoadingNotification, animated: true)
    loadingNotification?.mode = MBProgressHUDMode.indeterminate
    loadingNotification?.label.text = "Loading"
    
    self.isSendingData = true;
    if(self.dbService == nil) {
      self.setNotSendingData()
      return;
    }
    
    let result: AnyObject? = self.dbService!.fetchSessionIntervalLabelsByLimit(recordlimit: UserSettingsService.RETRIEVAL_LIMIT_FOR_SENDING_INTERVALLABELS) as AnyObject?;
    
    if(isRecursive) {
      if(result!.count == 0) {
        // send the session stop request
        self.dismissLoadingMessage()
        self.setNotSendingData()
        print("closing session")
        self.closeSession(currentExperimentId: self.experimentId!, currentSessionId: self.sessionId!, didUploadData: true);
        return;
      }
    }
    
    self.sendStreamIntervalLabels(intervalLabelsToSend: result as! [Dictionary<String, AnyObject>], attempt: 1, needUserFeedBack: isRecursive, isRecursive: isRecursive);
  }
  
  func sendStreamIntervalLabels(intervalLabelsToSend: [Dictionary<String, AnyObject>], attempt: Int, needUserFeedBack: Bool = true, isRecursive: Bool = false) {
    if (attempt == 6) {
      self.setNotSendingData();
      if(isRecursive) {
        self.sendStreamIntervalLabels(intervalLabelsToSend: intervalLabelsToSend, attempt: 1, isRecursive: isRecursive);
      }
      return;
    }
    
    if(!NetworkUtilities.isConnectedToNetwork()) {
      self.setNotSendingData()
      if (needUserFeedBack)
      {
        let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
          // finish session
          self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
        })
        self.vc.present(alert, animated: true){}
      } else {
        // finish session
        self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
      }
      
      return;
    }
    
    let isOfflineMode = self.sessionId == nil || (self.sessionId?.isEmpty)!
    
    print("sending chunk session interval labels")
    if let urlRequest = NSURL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/session/labels/submit") {
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      var labelInfo = [String:Any]()
      labelInfo["type"] = "interval"
      labelInfo["data"] = intervalLabelsToSend
      
      var parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID() as AnyObject,
        "model": ServerSettingsService.sharedInstance.getDeviceModel() as AnyObject,
        "dtype": "iOS",
        "experiment_id": self.experimentId! as AnyObject,
        "label_info": labelInfo as AnyObject
      ]
      
      if isOfflineMode {
        if let cached: UTECachedExperiment = UserSettingsService.sharedInstance.findCachedExperimentById(experimentId: self.experimentId!) {
          parameters["uid"] = cached.uid! as AnyObject
          parameters["is_initiator"] = self.isInitiator
        }
      } else {
        // session is created through online mode.
        parameters["session_id"] = self.sessionId! as AnyObject
      }
      
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
          self.dismissLoadingMessage()
          
          if (response.response == nil) {
            self.setNotSendingData();
              if needUserFeedBack {
              let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true)
              })
              self.vc.present(alert, animated: true){}
            } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true)
            }
            
            return;
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              // finish session
              self.setNotSendingData();
              if needUserFeedBack {
                let alert = UIAlertController(title: "Error", message:"Unauthorized access. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            case 500:
              self.setNotSendingData();
              if needUserFeedBack {
                let alert = UIAlertController(title: "Server Error", message:"Server error. Please contact the administrator. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            default:
              self.setNotSendingData();
              if needUserFeedBack {
                let title = "Error [Code:" + String(alamoResponse.statusCode) + "]"
                var message = "Error sending request."
                switch response.result {
                case .failure(let error):
                  message = error as! String
                  break
                default: break
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true)
                })
                self.vc.present(alert, animated: true){}
              } else {
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
              }
              
              return
            }
          }
          
          print("finished sending chunk interval label info")
          
          if let jsonResponse = response.result.value as? [String: AnyObject] {
            // check the status response from server
            if let status = jsonResponse["status"] as? String {
              if (status == "OK") {
                let thelastEntryTimestamp = intervalLabelsToSend[intervalLabelsToSend.count - 1]["t_start"] as! Double
                self.dbService!.deleteSessionIntervalLabelsBefore(thetime: thelastEntryTimestamp);
                
                if isOfflineMode {
                  if let sessionId = jsonResponse["session_id"] as? String {
                    self.sessionId = sessionId
                    self.dbService!.updateSessionId(sessionId: sessionId)
                    UserSettingsService.sharedInstance.updateSessionRecordSynced(uniqueId: self.uniqueId!, sessionIdForUpdate: sessionId)
                  }
                }
                
                self.setNotSendingData();
                
                if(isRecursive) {
                  ThreadUtilities.delay(0.01) {
                    self.sendChunkIntervalLabelsGeneric(isRecursive: true); // unsuccessful connection will display alert view.
                  }
                }
              } else {
                if (jsonResponse["code"] as? Int) == 404 {
                  if needUserFeedBack {
                    let alert = UIAlertController(title: "Error", message: "Initiator session has not been uploaded yet. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                      // finish session
                      self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                    })
                    self.vc.present(alert, animated: true){}
                  } else {
                    // finish session
                    self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true);
                  }
                } else {
                  if needUserFeedBack {
                    let alert = UIAlertController(title: "Error", message: "Error in submitting data. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                      // finish session
                      self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true)
                    })
                    self.vc.present(alert, animated: true){}
                  } else {
                    // finish session
                    self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: true, failedApiRequest: true)
                  }
                }
              }
            }
          }
          
          
      }
    }
  }
  
  func closeSession(currentExperimentId: String, currentSessionId: String, didUploadData: Bool) {
    // check if network connection exist
    if(!NetworkUtilities.isConnectedToNetwork()) {
      self.setNotSendingData()
      let alert = UIAlertController(title: "Error", message:"No internet connection available", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
      self.vc.present(alert, animated: true){}
      
      return
    }
    
    // request session ID
    if let urlRequest = URL(string: ServerSettingsService.sharedInstance.baseUrl())?.appendingPathComponent("api/experiment/session/connection/close") {
      
      var urlRequest = URLRequest(url: urlRequest)
      urlRequest.httpMethod = Alamofire.HTTPMethod.post.rawValue
      
      let parameters: Parameters = [
        "did": ServerSettingsService.sharedInstance.getDeviceUDID() as AnyObject,
        "model": ServerSettingsService.sharedInstance.getDeviceModel() as AnyObject,
        "dtype": "iOS" as AnyObject,
        "experiment_id": currentExperimentId as AnyObject,
        "session_id": currentSessionId as AnyObject
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
          self.dismissLoadingMessage()
          
          if (response.response == nil && SessionViewController.hasServer) {
            self.setNotSendingData()
            let alert = UIAlertController(title: "Error", message:"Invalid server", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
              // finish session
              self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: didUploadData, failedApiRequest: true);
            })
            self.vc.present(alert, animated: true){}
            
            return;
          }
          
          if let alamoResponse = response.response as HTTPURLResponse!{
            switch alamoResponse.statusCode {
            case 200: break;
            case 401:
              self.setNotSendingData()
              let alert = UIAlertController(title: "Error", message:"Unauthorized request", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // finish session
                self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: didUploadData, failedApiRequest: true);
              })
              self.vc.present(alert, animated: true){}
              
              return;
            default:
              if(SessionViewController.hasServer == false) {
                // simulate success
              } else {
                self.setNotSendingData()
                let alert = UIAlertController(title: "Error", message:"Error sending request.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                  // finish session
                  self.handler.handleSuccessfullFinishSession(destroyRecord: false, didUploadData: didUploadData, failedApiRequest: true);
                })
                self.vc.present(alert, animated: true){}
                
                return
              }
            }
          }
          
          // finish session
          self.handler.handleSuccessfullFinishSession(destroyRecord: true, didUploadData: didUploadData, failedApiRequest: false)
      }
    }
  }
  
  func dismissLoadingMessage() {
    if let loadingNotification = self.loadingNotification {
      loadingNotification.hide(animated: true)
      self.loadingNotification = nil
    }
  }
}
