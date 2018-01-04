//
//  SettingsViewController
//  Mobi-UTE
//
//  Created by Jonathan Liono on 23/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, UITextFieldDelegate {

  @IBOutlet weak var serverUrlTextField: UITextField!
  
  @IBOutlet weak var appVersionLabel: UILabel!
  
  @IBOutlet weak var deviceIdLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    
    // load items
    // server url.
    serverUrlTextField.text = ServerSettingsService.sharedInstance.baseUrl()
    
    // app version
    //First get the nsObject by defining as an optional anyObject
    self.appVersionLabel.textColor = UIColor.gray
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      self.appVersionLabel.text = version
    }     
    
    // device ID.
    self.deviceIdLabel.textColor = UIColor.gray
    self.deviceIdLabel.font = self.deviceIdLabel.font.withSize(8)
    self.deviceIdLabel.text = ServerSettingsService.sharedInstance.getDeviceUDID()
    self.deviceIdLabel.isUserInteractionEnabled = true
    let tapOnDeviceId = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.tapOnDeviceId(_:)))
    self.deviceIdLabel.addGestureRecognizer(tapOnDeviceId)
    
    self.navigationItem.hidesBackButton = true
    let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SettingsViewController.back(_:)))
    self.navigationItem.leftBarButtonItem = newBackButton;
  }
  
  func tapOnDeviceId(_ sender: UITapGestureRecognizer) {
    let alert = UIAlertController(title: "Device ID", message:"Your device ID is: " + ServerSettingsService.sharedInstance.getDeviceUDID(), preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
    present(alert, animated: true, completion: nil)
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == serverUrlTextField {
      UserSettingsService.sharedInstance.setSettingsBaseServerUrl(baseServerUrl: textField.text)
    }
  }
  
  func back(_ sender: UIBarButtonItem) {
    UserSettingsService.sharedInstance.setSettingsBaseServerUrl(baseServerUrl: serverUrlTextField.text)
    if let nc = self.navigationController {
      nc.popViewController(animated: true)
    }
  }
}
