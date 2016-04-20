//
//  PathEndpoints.swift
//  Prelo
//
//  Created by Fransiska on 10/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

let pathHost = "https://partner.path.com/"

class PathEndpoints: NSObject {
    class func ProcessParam(oldParam : [String : AnyObject]) -> [String : AnyObject] {
        let newParam = oldParam
        return oldParam
    }
}

extension NSMutableURLRequest {
    class func defaultURLRequest(url : NSURL, token : String?) -> NSMutableURLRequest {
        let r = NSMutableURLRequest(URL : url)
        
        if (token != nil) {
            r.setValue("Bearer " + token!, forHTTPHeaderField: "Authorization")
        }

        return r
    }
}

enum APIPathAuth : URLRequestConvertible {
    static let basePath = "oauth2/"
    
    case GetToken(clientId : String, clientSecret : String, code : String)
    
    var method : Method {
        switch self {
        case .GetToken(_, _, _) : return .POST
        }
    }
    
    var path : String {
        switch self {
        case .GetToken(_, _, _) : return "access_token"
        }
    }
    
    var param : String? {
        switch self {
        case .GetToken(let clientId, let clientSecret, let code) :
            let p = "grant_type=authorization_code&client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)"
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = NSURL(string: pathHost)?.URLByAppendingPathComponent(APIPathAuth.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!, token: nil)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.HTTPMethod = method.rawValue
        req.HTTPBody = param?.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        return req
    }
}

enum APIPathUser : URLRequestConvertible {
    static let basePath = "1/user"
    
    case GetSelfData(token : String)
    
    var method : Method {
        switch self {
        case .GetSelfData(_) : return .GET
        }
    }
    
    var path : String {
        switch self {
        case .GetSelfData(_) : return "self"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .GetSelfData(_) :
            return [:]
        }
    }
    
    var token : String {
        switch self {
        case .GetSelfData(let token) : return token
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = NSURL(string: pathHost)?.URLByAppendingPathComponent(APIPathUser.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!, token: token)
        req.HTTPMethod = method.rawValue
        let r = ParameterEncoding.URL.encode(req, parameters: PathEndpoints.ProcessParam(param!)).0
        return req
    }
}