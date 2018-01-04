//
//  SessionFinishedHandlerProtocol.swift
//  Mobi-UTE
//
//  Created by Jonathan Liono on 30/10/2016.
//  Copyright © 2016 RMIT University. All rights reserved.
//

import Foundation

protocol SessionFinishedHandlerProtocol {
  func handleSuccessfullFinishSession(destroyRecord: Bool, didUploadData: Bool, failedApiRequest: Bool)
}
