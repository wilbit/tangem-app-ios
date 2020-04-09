//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by Gennady Berezovsky on 04.10.18.
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
class RSKCardBalanceOperation: BaseCardBalanceOperation {

     var hasToken: Bool = false
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD
        getMainBalance()
    }
    
    func getTokenBalance() {
        let tokenBalanceOperation = TokenNetworkBalanceOperation(card: card, network: .rsk) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleTokenBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(tokenBalanceOperation)
    }

    func handleTokenBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletTokenValue = balanceValue        
        completeOperation()
    }
    
    func getMainBalance() {
        let mainBalanceOperation = ETHCardBalanceOperation(card: card, networkUrl: TokenNetwork.rsk.rawValue) { [weak self] (result) in
            switch result {
            case .success:
                self?.handleMainBalanceLoaded()
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error.0, title: error.title)
            }
        }
        operationQueue.addOperation(mainBalanceOperation)
    }
    
    func handleMainBalanceLoaded() {
        guard !isCancelled else {
            return
        }
        if hasToken {
            getTokenBalance()
        } else {
            completeOperation()
        }
    }
}