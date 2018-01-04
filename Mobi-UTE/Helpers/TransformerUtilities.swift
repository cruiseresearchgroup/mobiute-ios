//
//  TransformerUtilities.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 5/06/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation

public class TransformerUtilities {
  class func convertHzToMillisec(hz: Double) -> Int {
    return Int(transformRound(value: 1000.0/hz, places: 0));
  }
  
  class func convertMillisecToSec(milliseconds: Int) -> Double {
    return (Double(milliseconds) / 1000.0)
  }
  
  class func transformRound( value: Double, places: Int) -> Double {
    var value = value
    var places = places
    if (places < 0) {
      places = 0;
    }
  
    let factor: Double = pow(10, Double(places));
    value = value * factor;
    let tmp: Double = round(value);
    return tmp / factor;
  }
}
