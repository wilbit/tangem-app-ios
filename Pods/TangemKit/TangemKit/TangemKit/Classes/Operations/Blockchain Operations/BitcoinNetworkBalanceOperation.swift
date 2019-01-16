//
//  BitcoinNetworkBalanceOperation.swift
//  Tangem
//
//  Created by Gennady Berezovsky on 03.10.18.
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class BitcoinNetworkBalanceOperation: GBAsyncOperation {

    private struct Constants {
        static let mainNetURL = "https://blockchain.info/balance?active="
        static let testNetURL = "https://testnet.blockchain.info/balance?active="
    }

    var address: String
    var completion: (TangemObjectResult<Double>) -> Void

    init(address: String, completion: @escaping (TangemObjectResult<Double>) -> Void) {
        self.address = address
        self.completion = completion
    }

    override func main() {
        let url = URL(string: Constants.mainNetURL + address)
        let urlRequest = URLRequest(url: url!)
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                let balanceInfo = JSON(data: data)
                let satoshi = balanceInfo[self.address]["final_balance"].doubleValue
                
                self.completeOperationWith(balance: satoshi)
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
        
        task.resume()
    }

    func completeOperationWith(balance: Double) {
        guard !isCancelled else {
            return
        }

        completion(.success(balance))
        finish()
    }

    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }

        completion(.failure(error))
        finish()
    }
}