//
//  SessionJourneySummaryViewController.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 23/04/2015.
//  Copyright (c) 2015 RMIT University. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import MapKit
import CoreLocation

class SessionJourneySummaryViewController: UIViewController, MKMapViewDelegate {
  private let genericUIColor: UIColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0);
  
  var mapView: MKMapView!
  var locationToDisplay: [NSArray]?;
  
  override func viewDidLoad() {
    super.viewDidLoad();
    
    let superview = self.view;
    
    self.title = "Journey Summary";
    let titlebar = UIView();
    titlebar.backgroundColor=(UIColor .black)
    let titleLabel = UILabel()
    titleLabel.text = self.title
    titleLabel.textAlignment = NSTextAlignment.center
    titleLabel.lineBreakMode = .byWordWrapping
    titleLabel.numberOfLines = 0
    titleLabel.textColor = genericUIColor
    titlebar.addSubview(titleLabel);
    
    titleLabel.snp.makeConstraints { (make) -> () in
      make.centerX.equalTo(titlebar.snp.centerX)
      make.centerY.equalTo(titlebar.snp.centerY)
      make.width.lessThanOrEqualTo(300)
    }
    
    let doneButton = UIButton()
    doneButton.setTitle("Done", for: .normal);
    doneButton.setTitleColor(genericUIColor, for: .normal);
    doneButton.addTarget(self, action: #selector(SessionJourneySummaryViewController.done(_:)), for: .touchUpInside);
    titlebar.addSubview(doneButton);
    doneButton.snp.makeConstraints { (make) -> () in
      make.width.lessThanOrEqualTo(100)
      make.right.lessThanOrEqualTo(titlebar.snp.right).offset(-20)
      make.centerY.equalTo(titlebar.snp.centerY)
    }
    
    self.view.addSubview(titlebar);
    
    self.mapView = MKMapView();
    self.mapView.mapType = .standard;
    //self.mapView.frame = view.frame;
    self.mapView.delegate = self;
    self.mapView.backgroundColor=(UIColor .blue)
    self.view.addSubview(mapView);
    
    titlebar.snp.makeConstraints { make in
      make.width.equalTo((superview?.snp.width)!)
      make.height.equalTo(50)
      make.top.equalTo((superview?.snp.top)!).offset(20)
    };
    
    // constraint of map below the title bar. 
    self.mapView.snp.makeConstraints { make in
      make.top.equalTo(titlebar.snp.bottom)
      make.width.equalTo((superview?.snp.width)!)
      make.height.lessThanOrEqualTo((superview?.snp.height)!)
      make.bottom.equalTo((superview?.snp.bottom)!)
      //make.centerX.greaterThanOrEqualTo(superview.snp_centerX).with.priorityLow();
    }
    
    drawPath()
    
    SCLAlertView().showTitle(
      "Congratulations", // Title of view
      subTitle: "Thanks for using Mobi-UTE Service, your session has ended", // String of view
      duration: 10, // Duration to show before closing automatically, default: 2.0
      completeText: "Done", // Optional button value, default: ""
      style: .success // Styles - see below.
    )
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func done(_ sender: UIBarButtonItem!){
    self.dismiss(animated: true, completion: nil);
  }
  
  func setLocationsToDisplay(locations: [NSArray]?) {
    self.locationToDisplay = locations
  }
  
  func drawPath() {
    if let locations = self.locationToDisplay {
      var points: [CLLocationCoordinate2D] = [];
      let pointCount: Int = locations.count;
      for i in (0 ..< pointCount) {
        let geopoint = locations[i]
        points.append(CLLocationCoordinate2DMake(geopoint[0] as! Double, geopoint[1] as! Double));
      }
      
      let geodesic = MKPolyline(coordinates: &points, count: pointCount)
      self.mapView.setVisibleMapRect(geodesic.boundingMapRect, animated: true)
      self.mapView.add(geodesic)
    }
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if (overlay is MKPolyline) {
      let pr = MKPolylineRenderer(overlay: overlay);
      pr.strokeColor = UIColor.red.withAlphaComponent(0.5);
      pr.lineWidth = 5;
      return pr;
    }
    
    return MKPolylineRenderer()
  }
}
