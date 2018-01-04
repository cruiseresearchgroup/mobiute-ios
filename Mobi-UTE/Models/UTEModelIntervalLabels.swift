//
//  UTEModelIntervalLabels.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 26/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation

public class UTEModelIntervalLabels: NSObject {
  
  public static let LABEL_SPLITTER: String = ":"
  
  public var start_date: Double?;
  public var end_date: Double?;
  public var labels: String?;
  
  public func toJson() -> Dictionary<String, AnyObject> {
    var dict: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>();
    dict["t_start"] = (self.start_date != nil) ? self.start_date! as AnyObject : NSNull();
    dict["t_end"] = (self.end_date != nil) ? self.end_date! as AnyObject : NSNull();
    
    if let labels = self.labels {
      if labels.isEmpty == false {
        let labelArray: [String] = labels.components(separatedBy: UTEModelIntervalLabels.LABEL_SPLITTER)
        dict["labels"] = labelArray as AnyObject?
      }
    }
    
    return dict;
  }
}
