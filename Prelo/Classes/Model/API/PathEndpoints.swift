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
    class func ProcessParam(_ oldParam : [String : AnyObject]) -> [String : AnyObject] {
        _ = oldParam
        return oldParam
    }
}

extension NSMutableURLRequest {
    class func defaultURLRequest(_ url : URL, token : String?) -> NSMutableURLRequest {
        let r = NSMutableURLRequest(url : url)
        
        if (token != nil) {
            r.setValue("Bearer " + token!, forHTTPHeaderField: "Authorization")
        }

        return r
    }
}

enum APIPathAuth : URLRequestConvertible {
    static let basePath = "oauth2/"
    
    case getToken(clientId : String, clientSecret : String, code : String)
    
    var method : Method {
        switch self {
        case .getToken(_, _, _) : return .POST
        }
    }
    
    var path : String {
        switch self {
        case .getToken(_, _, _) : return "access_token"
        }
    }
    
    var param : String? {
        switch self {
        case .getToken(let clientId, let clientSecret, let code) :
            let p = "grant_type=authorization_code&client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)"
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = URL(string: pathHost)?.appendingPathComponent(APIPathAuth.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!, token: nil)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpMethod = method.rawValue
        req.httpBody = param?.data(using: String.Encoding.ascii, allowLossyConversion: true)
        return req
    }
}

enum APIPathUser : URLRequestConvertible {
    static let basePath = "1/user"
    
    case getSelfData(token : String)
    
    var method : Method {
        switch self {
        case .getSelfData(_) : return .GET
        }
    }
    
    var path : String {
        switch self {
        case .getSelfData(_) : return "self"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .getSelfData(_) :
            return [:]
        }
    }
    
    var token : String {
        switch self {
        case .getSelfData(let token) : return token
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = URL(string: pathHost)?.appendingPathComponent(APIPathUser.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!, token: token)
        req.httpMethod = method.rawValue
        let r = ParameterEncoding.url.encode(req, parameters: PathEndpoints.ProcessParam(param!)).0
        return r
    }
}
