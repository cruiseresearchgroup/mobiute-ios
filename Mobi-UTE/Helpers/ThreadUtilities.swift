//
//  ThreadUtilities.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 24/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation

public class ThreadUtilities {
  class func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
    
    /*dispatch_after(
     DispatchTime.now(
     dispatch_time_t(DispatchTime.now),
     Int64(delay * Double(NSEC_PER_SEC))
     ),
     dispatch_get_main_queue(), closure)*/
  }
}
