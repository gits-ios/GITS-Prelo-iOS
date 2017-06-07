//
//  PreloUITests.swift
//  PreloUITests
//
//  Created by Prelo on 6/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import XCTest

class PreloUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAchievement() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        //        let app = XCUIApplication()
        //        app.buttons["MY ACCOUNT"].tap()
        //
        //        let tablesQuery2 = app.tables
        //        let tablesQuery = tablesQuery2
        //        tablesQuery.staticTexts["Achievement"].tap()
        //        tablesQuery2.cells.containing(.staticText, identifier:"4 Poin").staticTexts[""].tap()
        //        tablesQuery.staticTexts["Kumpulkan Poin untuk digunakan di aplikasi Prelo. Saat ini Poin sudah dapat digunakan untuk meng-up barang secara gratis!"].tap()
        //        tablesQuery2.children(matching: .cell).element(boundBy: 9).staticTexts["The Ultimate Inspector"].swipeRight()
        //        tablesQuery2.cells.containing(.staticText, identifier:"The Authentic Club").staticTexts[""].tap()
        //        tablesQuery.staticTexts["Badge ini hanya untuk Prelovers yang selalu meng-upload barang original!"].tap()
        //        tablesQuery2.children(matching: .cell).element(boundBy: 15).children(matching: .staticText).element.swipeRight()
        //        tablesQuery2.cells.containing(.staticText, identifier:"Top Seller").staticTexts[""].tap()
        
        
        let app = XCUIApplication()
        app.buttons["MY ACCOUNT"].tap()
        
        let tablesQuery2 = app.tables
        let tablesQuery = tablesQuery2
        tablesQuery.staticTexts["Achievement"].tap()
        tablesQuery2.cells.containing(.staticText, identifier:"4 Poin").staticTexts[""].tap()
        tablesQuery.staticTexts["Kumpulkan Poin untuk digunakan di aplikasi Prelo. Saat ini Poin sudah dapat digunakan untuk meng-up barang secara gratis!"].tap()
        tablesQuery.staticTexts[""].tap()
        tablesQuery2.cells.containing(.staticText, identifier:"The Authentic Club").staticTexts[""].tap()
        tablesQuery.staticTexts["Badge ini hanya untuk Prelovers yang selalu meng-upload barang original!"].tap()
        tablesQuery2.cells.containing(.staticText, identifier:"Top Seller").staticTexts[""].tap()
        tablesQuery.staticTexts["Khusus untuk 10 besar penjual yang menjual barang terbanyak setiap bulannya, rajin membalas chat, dan mendapatkan review yang bagus."].tap()
    }
    
    func testRequestBarang(){
        
        let app = XCUIApplication()
        app.buttons["MY ACCOUNT"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Request"].tap()
        tablesQuery.staticTexts["Request Barang"].tap()
        app.webViews.staticTexts["REQUEST BARANG"].tap()
        
    }
    
    func testRequestPackaging(){
        
        let app = XCUIApplication()
        app.buttons["MY ACCOUNT"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Request"].tap()
        tablesQuery.staticTexts["Request Packaging"].tap()
        app.webViews.staticTexts["REQUEST PACKAGING"].tap()
        
    }
    
    func testTarikUang(){
        
        let app = XCUIApplication()
        app.buttons["MY ACCOUNT"].tap()
        app.tables.staticTexts["Tarik Uang"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .staticText).matching(identifier: "Prelo Balance").element(boundBy: 0).tap()
        app.buttons["TARIK UANG"].tap()
        
        let scrollViewsQuery = app.scrollViews
        let elementsQuery = scrollViewsQuery.otherElements
        elementsQuery.staticTexts["Prelo Balance yang bisa ditarik"].tap()
        scrollViewsQuery.otherElements.containing(.staticText, identifier:"Prelo Balance yang bisa ditarik").children(matching: .other).element(boundBy: 2).children(matching: .button).element.tap()
        app.otherElements.containing(.sheet, identifier:"Pilih Bank").children(matching: .other).element(boundBy: 0).tap()
        elementsQuery.staticTexts["Nomor Rekening"].swipeRight()
        elementsQuery.staticTexts["Rekening Atas Nama"].swipeUp()
        elementsQuery.staticTexts["Jumlah Penarikan"].tap()
        elementsQuery.staticTexts["Password Prelo"].tap()
        elementsQuery.staticTexts["Penarikan dana ke rekening selain Mandiri, BCA, dan BNI, akan dikenakan biaya Rp6.500 dan akan dikenakan biaya Rp1.000 ke rekening BRI."].tap()
        elementsQuery.buttons["TARIK UANG SEKARANG"].tap()
        
    }
    
    func testReferralBonus(){
        
        let app = XCUIApplication()
        app.buttons["MY ACCOUNT"].tap()
        
        app.tables.staticTexts["Referral Bonus"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["SALDO REFERRAL BONUS"].tap()
        elementsQuery.staticTexts["Untuk setiap referral yang dipakai, temanmu akan mendapatkan referral bonus Rp25.000 dan kamu akan mendapatkan Rp5.000. Dapatkan tambahan Rp20.000 saat temanmu berhasil belanja."].tap()
        
        let penggunaBaruHanyaDapatMemasukkanKodeReferralSebanyakSatuKaliStaticText = elementsQuery.staticTexts["(Pengguna baru hanya dapat memasukkan kode referral sebanyak satu kali)"]
        penggunaBaruHanyaDapatMemasukkanKodeReferralSebanyakSatuKaliStaticText.tap()
        penggunaBaruHanyaDapatMemasukkanKodeReferralSebanyakSatuKaliStaticText.swipeUp()
        
    }
    
    func testBantuan(){
        
        let app = XCUIApplication()
        app.buttons["MY ACCOUNT"].tap()
        
        let app2 = app
        app2.tables.staticTexts["Bantuan"].tap()
        
        let webViewsQuery = app2.webViews
        webViewsQuery.staticTexts["Frequently Asked Questions"].tap()
        
        let webViewsQuery2 = app.webViews
        let element = webViewsQuery2.children(matching: .other).element
        element.tap()
        
        let frequentlyAnsweredQuestionPreloCoIdElement = webViewsQuery2.otherElements["Frequently Answered Question | Prelo.co.id"]
        
    }
    
    
    
}
