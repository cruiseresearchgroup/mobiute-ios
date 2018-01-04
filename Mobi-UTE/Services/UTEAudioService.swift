//
//  UTEAudioService.swift
//  UTEAudioService
//
//  Created by Jonathan Liono on 25/12/2014.
//  Copyright (c) 2014 RMIT University. All rights reserved.
//

import Foundation
import AVFoundation

class UTEAudioService: NSObject {
  var audioPlayer: AVAudioPlayer?;
  
  override init(){
    self.audioPlayer = AVAudioPlayer();
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
    } catch _ {
    }
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch _ {
    }
  }
  
  // MARK: public methods.
  func playAudioStartSession() {
    //var startSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("start", ofType: "wav", inDirectory: "Mobi-UTE/Assets/Audio")!);
    let filepath = Bundle.main.path(forResource: "start", ofType: "wav");
    let startSound = URL(fileURLWithPath: filepath!);
    self.prepareAndPlaySound(url: startSound);
  }
  
  func playAudioFinishSession() {
    //var finishSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("finish", ofType: "wav", inDirectory: "Mobi-UTE/Assets/Audio")!);
    let finishSound = URL(fileURLWithPath: Bundle.main.path(forResource: "finish", ofType: "wav")!);
    self.prepareAndPlaySound(url: finishSound);
  }
  
  func playAudioHardAccelEvent() {
    let filepath = Bundle.main.path(forResource: "beep-xylo", ofType: "aif");
    let startSound = URL(fileURLWithPath: filepath!);
    self.prepareAndPlaySound(url: startSound);
  }
  
  func playAudioHardBrakeEvent() {
    let filepath = Bundle.main.path(forResource: "beep-warmguitar", ofType: "aif");
    let startSound = URL(fileURLWithPath: filepath!);
    self.prepareAndPlaySound(url: startSound);
  }
  
  // MARK: private methods
  private func prepareAndPlaySound(url: URL){
    self.audioPlayer = try? AVAudioPlayer(contentsOf: url);
    self.audioPlayer!.prepareToPlay();
    self.audioPlayer!.play();
  }
}
