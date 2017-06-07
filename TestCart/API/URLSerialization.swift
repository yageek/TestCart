//
//  URLSerialization.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import Foundation

extension API {
    static var Key: String?

    static let baseHost = Foundation.URL(string: "http://www.apilayer.net/api")!

    public var URL: Foundation.URL {

        guard let apiKey = API.Key else { fatalError("API KEY was not set.") }

        let path: String = {
            switch self {
            case .list: return "/list"
            case .rates: return "/live"
            }
        }()

        let pathURL = API.baseHost.appendingPathComponent(path)
        var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name:"access_key", value: apiKey),
            URLQueryItem(name:"pretty_print", value: "1")
        ]
        guard let url = components?.url else {
            fatalError("URL should noe be nil at this point")
        }
        return url
    }
}
