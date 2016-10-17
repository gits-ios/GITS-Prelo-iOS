//
//  PathEndpoints.swift
//  Prelo
//
//  Created by Fransiska on 10/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

let pathHost = "https://partner.path.com/"

class PathEndpoints: NSObject {
    class func ProcessParam(_ oldParam : [String : Any]) -> [String : Any] {
        return oldParam
    }
}

extension URLRequest {
    func defaultURLRequest(token : String?) -> URLRequest {
        var r = URLRequest(url : self.url!)
        
        // Set token
        if (token != nil) {
            r.setValue("Bearer " + token!, forHTTPHeaderField: "Authorization")
        }

        return r
    }
}

enum APIPathAuth : URLRequestConvertible {
    case getToken(clientId : String, clientSecret : String, code : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "oauth2/"
        let url = URL(string: pathHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest(token: nil)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = param.data(using: String.Encoding.ascii, allowLossyConversion: true)
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: nil)
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getToken(_, _, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .getToken(_, _, _) : return "access_token"
        }
    }
    
    var param : String {
        switch self {
        case .getToken(let clientId, let clientSecret, let code) :
            let p = "grant_type=authorization_code&client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)"
            return p
        }
    }
}

enum APIPathUser : URLRequestConvertible {
    case getSelfData(token : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "1/user"
        let url = URL(string: pathHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest(token: token)
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PathEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getSelfData(_) : return .get
        }
    }
    
    var path : String {
        switch self {
        case .getSelfData(_) : return "self"
        }
    }
    
    var param : [String : Any] {
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
}
