//
//  AnalyticManager.swift
//  Prelo
//
//  Created by Djuned on 2/20/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

class AnalyticManager: NSObject {
    static let sharedInstance = AnalyticManager()
    
    // send record to Analytic Server
    func send(eventType : String, data : [String : Any]) {
        let _ = request(APIAnalytic.event(eventType: eventType, data: data)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(false, dataResp: resp, reqAlias: "Analytics " + eventType)) {
                print("Sent!")
            }
        }
    }
    
    func updateUser() {
        let _ = request(APIAnalytic.user).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(false, dataResp: resp, reqAlias: "Analytics - User")) {
                print("Sent!")
            }
        }
    }
}
