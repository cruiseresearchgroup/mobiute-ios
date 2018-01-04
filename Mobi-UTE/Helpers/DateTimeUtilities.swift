//
//  DateTimeUtilities.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 2/01/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import UIKit

public class DateTimeUtilities {
  class func getCurrentTimeStamp() -> Double  {
    return NSDate().timeIntervalSince1970;
  }
  
  class func getNSDate(unixTimestamp: Double) -> NSDate {
    return NSDate(timeIntervalSinceReferenceDate: unixTimestamp);
  }
}