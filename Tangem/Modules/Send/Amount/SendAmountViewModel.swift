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

protocol SendAmountViewModelInput {
    var walletName: String { get }
    var balance: String { get }
    var tokenIconInfo: TokenIconInfo { get }
    var amountFractionDigits: Int { get }
    var amountAlternativePublisher: AnyPublisher<String, Never> { get }
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    var isFiatCalculation: Bool { get }
    var cryptoCurrencyCode: String { get }
    var fiatCurrencyCode: String { get }

    var blockchain: Blockchain { get }
    var amountType: Amount.AmountType { get }

    func setAmount(_ amount: Amount?)
}

protocol SendAmountViewModelDelegate: AnyObject {
    func didSelectCurrencyOption(isFiat: Bool)
    func didTapMaxAmount()
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let cryptoCurrencyCode: String
    let fiatCurrencyCode: String
    let amountFractionDigits: Int

    @Published var decimalValue: DecimalNumberTextField.DecimalValue? = nil

    @Published var currencyOption: CurrencyOption
    @Published var amountAlternative: String = ""
    @Published var error: String?

    weak var delegate: SendAmountViewModelDelegate?

    private let input: SendAmountViewModelInput
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput) {
        self.input = input
        walletName = input.walletName
        balance = input.balance
        tokenIconInfo = input.tokenIconInfo
        amountFractionDigits = input.amountFractionDigits

        currencyOption = input.isFiatCalculation ? .fiat : .crypto
        cryptoCurrencyCode = input.cryptoCurrencyCode
        fiatCurrencyCode = input.fiatCurrencyCode

        bind(from: input)
    }

    func didTapMaxAmount() {
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
            .sink { [weak self] amount in
                self?.decimalValue = self?.fromAmount(amount)
            }
            .store(in: &bag)

        $decimalValue
            .sink { [weak self] decimalValue in
                guard let self else { return }
                input.setAmount(toAmount(decimalValue))
            }
            .store(in: &bag)

        $currencyOption
            .sink { [weak self] option in
                let isFiat = (option == .fiat)
                self?.delegate?.didSelectCurrencyOption(isFiat: isFiat)
            }
            .store(in: &bag)
    }

    private func fromAmount(_ amount: Amount?) -> DecimalNumberTextField.DecimalValue? {
        if let amount {
            return DecimalNumberTextField.DecimalValue.internal(amount.value)
        } else {
            return nil
        }
    }

    private func toAmount(_ decimalValue: DecimalNumberTextField.DecimalValue?) -> Amount? {
        if let decimalValue {
            return Amount(with: input.blockchain, type: input.amountType, value: decimalValue.value)
        } else {
            return nil
        }
    }
}

extension SendAmountViewModel {
    enum CurrencyOption: String, CaseIterable, Identifiable {
        case crypto
        case fiat

        var id: Self { self }
    }
}
