//
//  API.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import ProcedureKit

protocol JSONDecodable {
    init(json: [String: Any]) throws
}

protocol APIEndpoint {
    var URL: Foundation.URL { get }
}

enum API: APIEndpoint {
    case list
    case rates

    enum Error: Swift.Error {
        case invalidProperty(String)
        case invalidTimeFormat
        case apiError(code: Int, info: String)
        case unexpectedError
        case ioError
    }

    struct ResponseError: JSONDecodable {
        let code: Int
        let info: String

        init(json: [String : Any]) throws {
            guard let errorCode = json["error"] as? Double else {
                throw API.Error.invalidProperty("error")
            }
            self.code = Int(errorCode)

            guard let desc = json["info"] as? String else {
                throw API.Error.invalidProperty("info")
            }

            self.info = desc
        }
    }

    struct Response: JSONDecodable {
        let success: Bool
        let error: ResponseError?

        init(json: [String : Any]) throws {

            guard let successValue = json["success"] as? Bool else {
                throw API.Error.invalidProperty("success")
            }

            self.success = successValue

            if let error = json["error"] as? [String: Any] {
                self.error = try ResponseError(json: error)
            } else {
                self.error = nil
            }
        }
    }

    struct RatesResponse: JSONDecodable {
        let timestamp: Date
        let source: String
        let quotes: [String: Double]

        init(json: [String : Any]) throws {

            guard let source = json["source"] as? String else {
                throw API.Error.invalidProperty("source")
            }
            self.source = source

            guard let timeRaw = json["timestamp"] as? Double else {
                throw API.Error.invalidProperty("timestamp")
            }
            self.timestamp = Date(timeIntervalSince1970: timeRaw)

            guard let values = json["quotes"] as? [String : Double] else {
                throw API.Error.invalidProperty("quotes")
            }

            self.quotes = values
        }
    }

    struct ListResponse: JSONDecodable {
        let currencies: [String: String]

        init(json: [String : Any]) throws {

            guard let values = json["currencies"] as? [String : String] else {
                throw API.Error.invalidProperty("currencies")
            }

            self.currencies = values
        }
    }
}

let apiQueue = ProcedureQueue()

func APIDownloadList<Endpoint: APIEndpoint>(endpoint: Endpoint, success successBlock: @escaping (API.ListResponse) -> Void, error: @escaping (Error?) -> Void) {

    let download = DownloadProcedure(endpoint: endpoint, success: successBlock, error: error)
    apiQueue.add(operation: download)
}
