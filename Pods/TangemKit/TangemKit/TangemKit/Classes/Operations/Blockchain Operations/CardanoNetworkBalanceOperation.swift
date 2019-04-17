//
//  CardanoNetworkBalanceOperation.swift
//  Tangem
//
//  Created by Gennady Berezovsky on 03.10.18.
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class CardanoNetworkBalanceOperation: GBAsyncOperation {

    private struct Constants {
        static let mainNetURL = "https://explorer2.adalite.io/api/addresses/summary/"
    }

    var address: String
    var completion: (TangemObjectResult<String>) -> Void

    init(address: String, completion: @escaping (TangemObjectResult<String>) -> Void) {
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
                do {
                    let balanceInfo = try JSON(data: data)
                    let balance = balanceInfo["Right"]["caBalance"]["getCoin"].doubleValue
                    
                    let decimalCount: Int16 = 6
                    let walletValue = NSDecimalNumber(value: balance).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: decimalCount))
                        
                    self.completeOperationWith(balance: walletValue.stringValue)
                } catch {
                    self.failOperationWith(error: error)
                }
                
            case .failure(let error):
                self.failOperationWith(error: error)
            }
        }
        
        task.resume()
    }

    func completeOperationWith(balance: String) {
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