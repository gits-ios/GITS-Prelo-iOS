//
//  PreloTests.swift
//  PreloTests
//
//  Created by Prelo on 6/7/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import XCTest


class PreloTests: XCTestCase {
    
    var token = ""
    var idUser = ""
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
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
               
                //print("convertedJsonIntoDict \(convertedJsonIntoDict)")
                
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
    
    
    func testCheckEmail(){
        let email = "fransiskapw@gmail.com"
        
        let URL = NSURL(string: "https://dev.prelo.id/api/auth/check_email?email="+email)!
        
        var request = URLRequest(url:URL as URL)
        
        request.httpMethod = "GET"
        
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

    func testCheckUsername(){
        let username = "apaajaada"
        
        let URL = NSURL(string: "https://dev.prelo.id/api/auth/check_username?username="+username)!
        
        var request = URLRequest(url:URL as URL)
        
        request.httpMethod = "GET"
        
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
    
    func testLoveList() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/lovelist")!
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
    
    func testGetUsersCart() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/v2/cart")!
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
    
    func testGetUnreadNotifications() {
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/notif/unread")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    
    func testGetNotifications() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/notification")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testGetSocmedData() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/socmed")!
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
    
    func testRemoveAllFromCart() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/cart/remove_all")!
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
    
    func testGetInboxThreads() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/inbox")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testGetPreloMessage() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/prelo_message")!
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
    
    func testGetReferralBonus() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/referral_bonus")!
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
    
    func testResendEmail() {
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/verify/resend_email")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testUserPasswordChecker() {
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/checkpassword")!
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

    func testSendForgotPasswordEmail(){
        let email = "test@prelo.id"

        let URL = NSURL(string: "https://dev.prelo.id/api/auth/forgot_password")!
        
        let bodyData = "email=" + email
        
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
                
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
    }
    
    
    func testGetUserAddressBook() {
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/address_book")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testGetUserDeviceRegistrationID() {
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/device_registration_id")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testGetUsersProfile() {
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/me/profile")!
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
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    
    func testRegister(){
        let email = "testregister3@prelo.com"
        let username = "testregister3"
        let fullname = "Test Register3"
        let password = "testregister3"
        let platform_sent_from = "ios"
        let device_id = "123"
        let fa_id = "123"
    
        let URL = NSURL(string: "https://dev.prelo.id/api/auth/register")!
        let bodyData = "email=" + email + "&username=" + username + "&fullname=" + fullname + "&password=" + password + "&platform_sent_from=" + platform_sent_from + "&device_id=" + device_id + "&fa_id=" + fa_id
    
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
    
    func testGetUsersAchievement(){
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
                
                //print("convertedJsonIntoDict \(convertedJsonIntoDict)")
                
                let tempDic = convertedJsonIntoDict as! Dictionary<String,Any>
                let isiData = tempDic["_data"]! as! Dictionary<String,Any>
                //                print("ini isi data")
                //                print(isiData)
                self.idUser = isiData["_id"] as! String
                                print("ini isi id")
                                print(self.idUser)
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
        
        
        let URL2 = NSURL(string: "https://dev.prelo.id/api/user/"+idUser+"/achievements")!
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
    
    func testAddNewBrand(){
        let name = "uniqlo"
        let category_ids = "women"
        
        let URL = NSURL(string: "https://dev.prelo.id/api/admin/brand/add")!
        let bodyData = "name=" + name + "&category_ids=" + category_ids
        
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
    
// yang ini ga bisa soalnya butuh username password admin
//    func testGetAllProductsList(){
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        
//        //login buat dapet authorization
//        let username_or_email = "apaajaada"
//        let password = "password"
//        
//        let URL = NSURL(string: "https://dev.prelo.id/api/auth/login")!
//        
//        let bodyData = "username_or_email=" + username_or_email + "&password=" + password
//        
//        var request = URLRequest(url:URL as URL)
//        
//        request.httpMethod = "POST"
//        request.httpBody = bodyData.data(using: String.Encoding.utf8)
//        
//        let expect = expectation(description: "GET \(URL)")
//        let session = URLSession.shared
//        
//        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
//            //            print("cobain")
//            
//            if let convertedJsonIntoDict = try? JSONSerialization.jsonObject(with: data!, options: []){
//                
//                // Print out dictionary
//                
//                //print("convertedJsonIntoDict \(convertedJsonIntoDict)")
//                
//                let tempDic = convertedJsonIntoDict as! Dictionary<String,Any>
//                let isiData = tempDic["_data"]! as! Dictionary<String,Any>
//                //                print("ini isi data")
//                //                print(isiData)
//                self.token = isiData["token"] as! String
//                                print("ini isi token")
//                                print(self.token)
//            } else {
//                print("masuknya kesini")
//            }
//            
//            
//            expect.fulfill()
//        }
//        
//        task.resume()
//        
//        waitForExpectations(timeout: 1) { error in
//            if let error = error {
//                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
//            }
//        }
//        
//        let URL2 = NSURL(string: "https://dev.prelo.id/api/admin/products")!
//        var request2 = URLRequest(url:URL2 as URL)
//        request2.httpMethod = "GET"
//        request2.setValue("Token "+token, forHTTPHeaderField: "Authorization")
//        
//        let expect2 = expectation(description: "GET \(URL2)")
//        let session2 = URLSession.shared
//        let task2 = session2.dataTask(with: request2 as URLRequest) { (data, response, error) in
//            XCTAssertNotNil(data, "data should not be nil")
//            XCTAssertNil(error, "error should be nil")
//            
//            if let response = response as? HTTPURLResponse,
//                let responseURL = response.url,
//                let mimeType = response.mimeType
//            {
//                XCTAssertEqual(responseURL.absoluteString, URL2.absoluteString, "HTTP response URL should be equal to original URL")
//                XCTAssertEqual(response.statusCode, 200, "HTTP response status code 200")
//                XCTAssertEqual(mimeType, "application/json", "HTTP response content type should be application/json")
//            } else {
//                XCTFail("Response was not NSHTTPURLResponse")
//            }
//            
//            expect2.fulfill()
//        }
//        
//        task2.resume()
//        
//        waitForExpectations(timeout: 5) { error in
//            if let error = error {
//                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
//            }
//        }
//    }
}
