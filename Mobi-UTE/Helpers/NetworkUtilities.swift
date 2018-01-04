//
//  NetworkUtilities.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 2/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import SystemConfiguration

public class NetworkUtilities {
  class func isConnectedToNetwork() -> Bool {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
        SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
      }
    }
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
      return false
    }
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
  }
  
  func post(params : Dictionary<String, AnyObject>, url : String) {
    var request = URLRequest(url: NSURL(string: url)! as URL)
    
    let session = URLSession.shared
    //let param = jsonString.dataUsingEncoding(NSUTF8StringEncoding)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
    
    // or if you think the conversion might actually fail (which is unlikely if you built `params` yourself)
    //
    // do {
    //    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
    // } catch {
    //    print(error)
    // }
    
    let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
      guard data != nil else {
        print("no data found: \(error)")
        return
      }
      
      // this, on the other hand, can quite easily fail if there's a server error, so you definitely
      // want to wrap this in `do`-`try`-`catch`:
      
      do {
        if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
          let success = json["success"] as? Int                                  // Okay, the `json` is here, let's get the value for 'success' out of it
          print("Success: \(success)")
        } else {
          let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)    // No error thrown, but not NSDictionary
          print("Error could not parse JSON: \(jsonStr)")
        }
      } catch let parseError {
        print(parseError)                                                          // Log the error thrown by `JSONObjectWithData`
        let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        print("Error could not parse JSON: '\(jsonStr)'")
      }
    })
    
    task.resume()
  }
  
  func post(params : Dictionary<String, String>, url : String, postCompleted : @escaping (_ succeeded: Bool, _ msg: String) -> ()) {
    let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
    let session = URLSession.shared
    request.httpMethod = "POST"

    request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
      print("Response: \(response)")
      let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
      print("Body: \(strData)")
      
      //var msg = "No message"
      
      do {
        let json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
        
        // The JSONObjectWithData constructor didn't return an error. But, we should still
        // check and make sure that json has a value using optional binding.
        if let parseJSON = json {
          // Okay, the parsedJSON is here, let's get the value for 'success' out of it
          if let success = parseJSON["success"] as? Bool {
            print("Success: \(success)")
            postCompleted(success, "Logged in.")
          }
          return
        }
        else {
          // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
          let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
          print("Error could not parse JSON: \(jsonStr)")
          postCompleted(false, "Error")
        }
        // use anyObj here
      } catch let error as NSError {
        print(error.localizedDescription)
        let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        print("Error could not parse JSON: '\(jsonStr)'")
        postCompleted(false, "Error")
      }
    })
    
    task.resume()
  }
}
