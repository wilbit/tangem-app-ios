//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

#warning("TODO: move these to different files?")

protocol SendAmountViewModelInput {
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    var blockchain: Blockchain { get }
    var amountType: Amount.AmountType { get }

    func setAmount(_ amount: Amount?)
}

protocol SendAmountViewModelDelegate: AnyObject {
    func didTapMaxAmount()
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let showCurrencyPicker: Bool
    let cryptoIconURL: URL?
    let cryptoCurrencyCode: String
    let fiatIconURL: URL?
    let fiatCurrencyCode: String
    let amountFractionDigits: Int
    let windowWidth: CGFloat

    @Published var amount: DecimalNumberTextField.DecimalValue? = nil
    @Published var useFiatCalculation = false
    @Published var amountAlternative: String = ""
    @Published var error: String?

    weak var delegate: SendAmountViewModelDelegate?

    private let input: SendAmountViewModelInput
    private var bag: Set<AnyCancellable> = []

    private let converter: SendFiatCryptoHelper

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        converter = SendFiatCryptoHelper(
            blockchain: input.blockchain,
            amountType: input.amountType,
            cryptoCurrencyId: walletInfo.currencyId,
            amountFractionDigits: walletInfo.amountFractionDigits
        )

        self.input = input
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits
        windowWidth = UIApplication.shared.windows.first?.frame.width ?? 400

        showCurrencyPicker = walletInfo.currencyId != nil
        cryptoIconURL = walletInfo.cryptoIconURL
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode
        fiatIconURL = walletInfo.fiatIconURL
        fiatCurrencyCode = walletInfo.fiatCurrencyCode

        bind(from: input)
    }

    func didTapMaxAmount() {
        converter.didChooseMaxAmount()
        delegate?.didTapMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .amountPublisher
            .removeDuplicates()
            .sink { [weak self] amount in
                self?.converter.setModelAmount(amount?.value)
            }
            .store(in: &bag)

        $amount
            .removeDuplicates()
            .sink { [weak self] amount in
                self?.converter.setUserInputAmount(amount?.value)
            }
            .store(in: &bag)

        converter
            .modelAmount
            .sink { [weak self] in
                self?.input.setAmount($0)
            }
            .store(in: &bag)

        converter
            .userInputAmount
            .map { newUserInputAmount -> DecimalNumberTextField.DecimalValue? in
                guard let newUserInputAmount else { return nil }
                return DecimalNumberTextField.DecimalValue.external(newUserInputAmount)
            }
//            .filter { [weak self] in
//                self?.amount != $0
//            }
            .sink { [weak self] newUserInputAmount in
                self?.amount = newUserInputAmount
            }
            .store(in: &bag)

        $useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] useFiatCalculation in
                self?.converter.setUseFiatCalculation(useFiatCalculation)
            }
            .store(in: &bag)
    }
}
