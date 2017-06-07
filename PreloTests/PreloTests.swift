//
//  PreloTests.swift
//  PreloTests
//
//  Created by Prelo on 6/7/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import XCTest


class PreloTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var token = ""
    
    func testAchievement() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        //login buat dapet authorization
        let username_or_email = "apaajaada"
        let password = "password"
        
        let URL = NSURL(string: "https://dev.prelo.id/api/auth/login")!
        
        let bodyData = "username_or_email=" + username_or_email + "&password=" + password
        
        var request = URLRequest(url:URL as URL)
        
        request.httpMethod = "POST"
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let expect = expectation(description: "GET \(URL)")
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
//            print("cobain")
            
            if let convertedJsonIntoDict = try? JSONSerialization.jsonObject(with: data!, options: []){
                
                // Print out dictionary
               
//                print("convertedJsonIntoDict \(convertedJsonIntoDict)")
                
                let tempDic = convertedJsonIntoDict as! Dictionary<String,Any>
                let isiData = tempDic["_data"]! as! Dictionary<String,Any>
//                print("ini isi data")
//                print(isiData)
                self.token = isiData["token"] as! String
//                print("ini isi token")
//                print(self.token)
            } else {
                print("masuknya kesini")
            }

            
            expect.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/achievements")!
        var request2 = URLRequest(url:URL2 as URL)
        request2.httpMethod = "GET"
        request2.setValue("Token "+token, forHTTPHeaderField: "Authorization")
        
        let expect2 = expectation(description: "GET \(URL2)")
        let session2 = URLSession.shared
        let task2 = session2.dataTask(with: request2 as URLRequest) { (data, response, error) in
            XCTAssertNotNil(data, "data should not be nil")
            XCTAssertNil(error, "error should be nil")
            
            if let response = response as? HTTPURLResponse,
                let responseURL = response.url,
                let mimeType = response.mimeType
            {
                XCTAssertEqual(responseURL.absoluteString, URL2.absoluteString, "HTTP response URL should be equal to original URL")
                XCTAssertEqual(response.statusCode, 200, "HTTP response status code 200")
                XCTAssertEqual(mimeType, "application/json", "HTTP response content type should be application/json")
            } else {
                XCTFail("Response was not NSHTTPURLResponse")
            }
            
            expect2.fulfill()
        }
        
        task2.resume()
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testLogin(){
        let username_or_email = "apaajaada"
        let password = "password"

        let URL = NSURL(string: "https://dev.prelo.id/api/auth/login")!
        
        let bodyData = "username_or_email=" + username_or_email + "&password=" + password
        
        var request = URLRequest(url:URL as URL)
        
        request.httpMethod = "POST"
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let expect = expectation(description: "GET \(URL)")
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            XCTAssertNotNil(data, "data should not be nil")
            XCTAssertNil(error, "error should be nil")
            
            if let response = response as? HTTPURLResponse,
                let responseURL = response.url,
                let mimeType = response.mimeType
            {
                XCTAssertEqual(responseURL.absoluteString, URL.absoluteString, "HTTP response URL should be equal to original URL")
                XCTAssertEqual(response.statusCode, 200, "HTTP response status code 200")
                XCTAssertEqual(mimeType, "application/json", "HTTP response content type should be application/json")
            } else {
                XCTFail("Response was not NSHTTPURLResponse")
            }
            
            expect.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
    }
    
    func testLogout() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        //login buat dapet authorization
        let username_or_email = "apaajaada"
        let password = "password"
        
        let URL = NSURL(string: "https://dev.prelo.id/api/auth/login")!
        
        let bodyData = "username_or_email=" + username_or_email + "&password=" + password
        
        var request = URLRequest(url:URL as URL)
        
        request.httpMethod = "POST"
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let expect = expectation(description: "GET \(URL)")
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            //            print("cobain")
            
            if let convertedJsonIntoDict = try? JSONSerialization.jsonObject(with: data!, options: []){
                
                // Print out dictionary
                
                //                print("convertedJsonIntoDict \(convertedJsonIntoDict)")
                
                let tempDic = convertedJsonIntoDict as! Dictionary<String,Any>
                let isiData = tempDic["_data"]! as! Dictionary<String,Any>
                //                print("ini isi data")
                //                print(isiData)
                self.token = isiData["token"] as! String
                //                print("ini isi token")
                //                print(self.token)
            } else {
                print("masuknya kesini")
            }
            
            
            expect.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/auth/logout")!
        var request2 = URLRequest(url:URL2 as URL)
        request2.httpMethod = "POST"
        request2.setValue("Token "+token, forHTTPHeaderField: "Authorization")
        
        let expect2 = expectation(description: "GET \(URL2)")
        let session2 = URLSession.shared
        let task2 = session2.dataTask(with: request2 as URLRequest) { (data, response, error) in
            XCTAssertNotNil(data, "data should not be nil")
            XCTAssertNil(error, "error should be nil")
            
            if let response = response as? HTTPURLResponse,
                let responseURL = response.url,
                let mimeType = response.mimeType
            {
                XCTAssertEqual(responseURL.absoluteString, URL2.absoluteString, "HTTP response URL should be equal to original URL")
                XCTAssertEqual(response.statusCode, 200, "HTTP response status code 200")
                XCTAssertEqual(mimeType, "application/json", "HTTP response content type should be application/json")
            } else {
                XCTFail("Response was not NSHTTPURLResponse")
            }
            
            expect2.fulfill()
        }
        
        task2.resume()
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    
}
