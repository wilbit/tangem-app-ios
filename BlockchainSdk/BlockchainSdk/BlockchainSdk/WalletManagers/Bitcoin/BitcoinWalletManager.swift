//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum BitcoinError: Error {
    case noUnspents
    case failedToBuildHash
    case failedToBuildTransaction
}

class BitcoinWalletManager: WalletManager {
    var wallet: Wallet { return _wallet }
    let blockchain: Blockchain
    
    private let _wallet: CurrencyWallet
    private let txBuilder: BitcoinTransactionBuilder
    private let cardId: String
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, isTestnet: Bool) {
        self.blockchain = isTestnet ? .bitcoinTestnet : .bitcoin
        self.cardId = cardId
        let address = blockchain.makeAddress(from: walletPublicKey)
        self._wallet = CurrencyWallet(config: walletConfig, address: address)
        self.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: isTestnet)
    }
    
    func update() {
        //TODO: implement
        txBuilder.unspentOutputs = []
    }
}

extension BitcoinWalletManager: TransactionBuilder {
    func getEstimateSize(for transaction: Transaction) -> Int? {
        guard let unspentOutputsCount = txBuilder.unspentOutputs?.count else {
            return nil
        }
        
        guard let tx = txBuilder.buildForSend(transaction: transaction, signature: Data(repeating: UInt8(0x01), count: 64 * unspentOutputsCount)) else {
            return nil
        }
        
        return tx.count + 1
    }
}

extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            completion(.failure(BitcoinError.failedToBuildHash))
            return
        }
        
        signer.sign(hashes: hashes, cardId: cardId) {[weak self] result in
            switch result {
            case .event(let response):
                guard let self = self else { return }
                
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature) else {
                    completion(.failure(BitcoinError.failedToBuildTransaction))
                    return
                }
                
                let txForSend = tx.toHexString()
                //TODO send and invoke completion
            case .completion(let error):
                if let error = error {
                    completion(.failure(error))
                }
            }
        }
    }
}

extension BitcoinWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void) {
        //TODO: implement
        completion(.success([]))
    }
}
