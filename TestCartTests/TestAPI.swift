//
//  TestAPI.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//
import XCTest
@testable import TestCart

class TestAPI: XCTestCase {

    static let sampleBundle: Bundle = {
        let bundleURL = Bundle(for: TestAPI.self).url(forResource: "apisamples", withExtension: "bundle")!
        return Bundle(url: bundleURL)!

    }()

    private func getJSONData(jsonName: String) -> Data {
        let jsonURL = TestAPI.sampleBundle.url(forResource: jsonName, withExtension: "json")!
        return try! Data(contentsOf: jsonURL)
    }

    func testLoadList() {
        let data = getJSONData(jsonName: "list")

        do {
            let listJSON = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            let list = try API.ListResponse(json: listJSON)

            XCTAssert(list.currencies.count == 169)


        } catch let error {
            XCTFail("Should be able to correctly download list: \(error)")
        }
    }

    func testLoadRates() {
        let data = getJSONData(jsonName: "rates")

        do {
            let ratesJSON = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            let rates = try API.RatesResponse(json: ratesJSON)

            XCTAssert(rates.quotes.count == 169)
            XCTAssertEqual(rates.source, "USD")
            XCTAssertEqual(rates.timestamp, Date(timeIntervalSince1970: 1496778564))

        } catch let error {
            XCTFail("Should be able to correctly download list: \(error)")
        }
    }

    func testURLBuild() {
        API.Key = "fake_key"

        XCTAssertEqual(API.rates.URL.absoluteString, "http://www.apilayer.net/api/live?access_key=fake_key&pretty_print=1")
        XCTAssertEqual(API.list.URL.absoluteString, "http://www.apilayer.net/api/list?access_key=fake_key&pretty_print=1")
    }

    func testDownload() {

        let exp = expectation(description: "effective download")
         API.Key = "a0a879526535de6ba0d56c1c0868ac4e"
        APIDownloadList(endpoint: API.list, success: { (list: API.ListResponse) in
            exp.fulfill()
        }) { (error) in
         exp.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }
}
