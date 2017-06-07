//
//  DownloadProcedure.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import ProcedureKit
import ProcedureKitNetwork
import ProcedureKitMobile

final class SerializeURL<Endpoint: APIEndpoint>: Procedure, OutputProcedure {

    let endpoint: Endpoint
    var output: Pending<ProcedureResult<URL>> = .pending

    init(endpoint: Endpoint) {
        self.endpoint = endpoint
        super.init()
        name = "SerializeURL.<\(endpoint)>"
    }

    override func execute() {
        guard !isCancelled else { self.finish(); return }

        self.finish(withResult: .success(endpoint.URL))
    }
}

final class ValidResponseProcedure: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<HTTPPayloadResponse<URL>> = .pending
    var output: Pending<ProcedureResult<URL>> = .pending

    override func execute() {
        guard !isCancelled else { self.finish(); return }

        guard let payload = self.input.value else {
            self.finish(withError: ProcedureKitError.dependenciesFailed())
            return
        }

        switch payload.response.statusCode {
        case 200..<299:

            do {
                let decodeProcedure = UnmarshalProcedure<API.Response>(URL: payload.payload)

                decodeProcedure.addDidFinishBlockObserver(block: { (procedure, _) in

                    if let response = procedure.output.success {

                        if response.success {
                            self.finish(withResult: .success(payload.payload!))
                        } else {
                            self.finish(withError: API.Error.apiError(code: response.error!.code, info: response.error!.info))
                        }

                    } else {
                        self.finish(withError: API.Error.unexpectedError)
                    }
                })

                try produce(operation: decodeProcedure)

            } catch let error {
                Log.debug("Impossible to create procedure: \(error)")
                self.finish(withError: error)
            }
        default:
            self.finish(withError: API.Error.unexpectedError)
        }
    }
}

final class UnmarshalProcedure<Object: JSONDecodable>: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<URL> = .pending
    var output: Pending<ProcedureResult<Object>> = .pending

    init(URL: URL? = nil) {
        if let url = URL {
            self.input = .ready(url)
        }
        super.init()
    }

    override func execute() {
        guard !isCancelled else { self.finish(); return }

        guard let url = self.input.value else {
            self.finish(withError: ProcedureKitError.dependenciesFailed())
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            let object = try Object(json: json)
            self.finish(withResult: .success(object))
        } catch let error {
            Log.error("Impossible to retrieve the downloaded data: \(error)")
            self.finish(withError: error)
        }
    }
}

final class DownloadProcedure<Endpoint: APIEndpoint, Object: JSONDecodable>: GroupProcedure, OutputProcedure {

    var output: Pending<ProcedureResult<Object>> = .pending

    init(endpoint: Endpoint, success successBlock: ((Object) -> Void)? = nil, error: ((Error?) -> Void)? = nil) {

        let marshal = SerializeURL(endpoint: endpoint)
        let map = TransformProcedure { URLRequest(url: $0) }.injectResult(from: marshal)
        let download = NetworkDownloadProcedure(session: URLSession.shared).injectResult(from: map)
        let valid = ValidResponseProcedure().injectResult(from: download)
        let unmarhshal = UnmarshalProcedure<Object>().injectResult(from: valid)

        super.init(operations: [marshal, map, download, valid, unmarhshal])
        name = "DownloadProcedure"

        unmarhshal.addDidFinishBlockObserver { (procedure, errors) in
            if let object = procedure.output.success, let successBlock = successBlock {
                DispatchQueue.main.async {
                    successBlock(object)
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    error(errors.first)
                }
            }
        }
        self.add(observer: NetworkObserver())
    }

    override func childWillFinishWithoutErrors(_ child: Operation) {
        if let op = child as? UnmarshalProcedure<Object> {
            self.output = op.output
        }
    }
}
