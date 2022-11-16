//
//  WalletManager+BlockchainProvider.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 09.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

struct ExchangeBlockchainProvider {
    private let walletManager: WalletManager
    private let signer: TangemSigner

    init(walletManager: WalletManager, signer: TangemSigner) {
        self.walletManager = walletManager
        self.signer = signer
    }
}

// MARK: - BlockchainProvider

extension ExchangeBlockchainProvider: BlockchainProvider {
    func signAndSend(_ transaction: Transaction) async throws {
        try await walletManager.send(transaction, signer: signer).async()
    }

    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal] {
        let amount = createAmount(from: currency, amount: amount)

        return try await walletManager.getFee(amount: amount, destination: destination)
            .map { $0.map { $0.value } }
//            .map{ amounts in
//                return [
//                    Currency(amount: amounts[0].value, blockchainNetwork: currency.blockchainNetwork),
//                    Currency(amount: amounts[1].value, blockchainNetwork: currency.blockchainNetwork),
//                    Currency(amount: amounts[2].value, blockchainNetwork: currency.blockchainNetwork),
//                ]
//            }
            .eraseToAnyPublisher()
            .async()
    }

    func createTransaction(for info: TransactionInfo) throws -> Transaction {
        let amount = createAmount(from: info.currency, amount: info.amount)
        let fee = createAmount(from: info.currency, amount: info.fee)

        return try walletManager.createTransaction(amount: amount,
                                                   fee: fee,
                                                   destinationAddress: info.destination,
                                                   sourceAddress: info.sourceAddress,
                                                   changeAddress: info.changeAddress)
    }
}

// MARK: - Private

private extension ExchangeBlockchainProvider {
    func createAmount(from currency: Currency, amount: Decimal) -> Amount {
        if let token = currency.asToken() {
            return Amount(with: token, value: amount)
        }

        return Amount(
            type: .coin,
            currencySymbol: currency.symbol,
            value: amount,
            decimals: currency.decimalCount
        )
    }
}

private extension Currency {
    func asToken() -> Token? {
        guard let contractAddress = contractAddress else {
            return nil
        }

        return Token(name: name, symbol: symbol, contractAddress: contractAddress, decimalCount: decimalCount)
    }
}
