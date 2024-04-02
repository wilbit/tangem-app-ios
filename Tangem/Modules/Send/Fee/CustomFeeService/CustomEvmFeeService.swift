//
//  CustomEvmFeeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import BigInt

class CustomEvmFeeService {
    private let _customFeeGasPrice = CurrentValueSubject<BigUInt?, Never>(nil)
    private let _customFeeGasLimit = CurrentValueSubject<BigUInt?, Never>(nil)

    private let blockchain: Blockchain
    private let walletInfo: SendWalletInfo

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?

    private var bag: Set<AnyCancellable> = []
    private var customGasPriceBeforeEditing: BigUInt?

    init(input: CustomFeeServiceInput, output: CustomFeeServiceOutput, blockchain: Blockchain, walletInfo: SendWalletInfo) {
        self.input = input
        self.output = output
        self.blockchain = blockchain
        self.walletInfo = walletInfo

        bind()
    }

    private func bind() {
        guard let input else {
            assertionFailure("WHY")
            return
        }

        input
            .feeValuePublisher
            .sink { [weak self] fee in
                guard
                    let self,
                    let fee,
                    input.customFee == nil
                else {
                    print("ZZZ updating initial fee", "NO")
                    return
                }

                print("ZZZ updating initial fee", fee)
                if let ethereumFeeParameters = fee.parameters as? EthereumFeeParameters {
                    _customFeeGasPrice.send(ethereumFeeParameters.gasPrice)
                    _customFeeGasLimit.send(ethereumFeeParameters.gasLimit)
                    output?.setCustomFee(fee)
                }
            }
            .store(in: &bag)
    }

    private func didChangeCustomFeeGasPrice(_ value: BigUInt?) {
        _customFeeGasPrice.send(value)
        recalculateCustomFee(gasPrice: _customFeeGasPrice.value, gasLimit: _customFeeGasLimit.value)
    }

    private func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        _customFeeGasLimit.send(value)
        recalculateCustomFee(gasPrice: _customFeeGasPrice.value, gasLimit: _customFeeGasLimit.value)
    }

    private func recalculateCustomFee(gasPrice: BigUInt?, gasLimit: BigUInt?) {
        let newFee: Fee?
        if let gasPrice,
           let gasLimit,
           let gasInWei = (gasPrice * gasLimit).decimal {
            let blockchain = blockchain
            let validatedAmount = Amount(with: blockchain, value: gasInWei / blockchain.decimalValue)
            newFee = Fee(validatedAmount, parameters: EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice))
        } else {
            newFee = nil
        }

        output?.setCustomFee(newFee)
    }

    private func recalculateFee(enteredFee: Decimal?) -> Fee? {
        let feeDecimalValue = Decimal(pow(10, Double(walletInfo.feeFractionDigits)))

        guard
            let enteredFee,
            let currentGasLimit = _customFeeGasLimit.value,
            let enteredFeeInSmallestDenomination = BigUInt(decimal: (enteredFee * feeDecimalValue).rounded(roundingMode: .down))
        else {
            return nil
        }

        let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
        guard
            let recalculatedFeeInSmallestDenomination = (gasPrice * currentGasLimit).decimal
        else {
            return nil
        }

        let recalculatedFee = recalculatedFeeInSmallestDenomination / feeDecimalValue
        let feeAmount = Amount(with: walletInfo.blockchain, type: walletInfo.feeAmountType, value: recalculatedFee)
        let parameters = EthereumFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice)
        return Fee(feeAmount, parameters: parameters)
    }
}

extension CustomEvmFeeService: CustomFeeService {
    var customFeeDescription: String? {
        Localization.sendMaxFeeFooter
    }

    var readOnlyCustomFee: Bool {
        false
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let gasPriceFractionDigits = 9
        let gasPriceGweiPublisher = _customFeeGasPrice
            .eraseToAnyPublisher()
            .decimalPublisher
            .map { weiValue -> Decimal? in
                let gweiValue = weiValue?.shiftOrder(magnitude: -gasPriceFractionDigits)
                return gweiValue
            }
            .eraseToAnyPublisher()

        let customFeeGasPriceModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasPrice,
            amountPublisher: gasPriceGweiPublisher,
            fieldSuffix: "GWEI",
            fractionDigits: gasPriceFractionDigits,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasPriceFooter
        ) { [weak self] gweiValue in
            guard let self else { return }

            let weiValue = gweiValue?.shiftOrder(magnitude: gasPriceFractionDigits)
            didChangeCustomFeeGasPrice(weiValue?.bigUIntValue)
        } onFocusChanged: { [weak self] focused in
            self?.onGasPriceFocusChanged(focused)
        }

        let customFeeGasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: _customFeeGasLimit.eraseToAnyPublisher().decimalPublisher,
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            guard let self else { return }
            didChangeCustomFeeGasLimit($0?.bigUIntValue)
        }

        return [
            customFeeGasPriceModel,
            customFeeGasLimitModel,
        ]
    }

    func setCustomFee(enteredFee: Decimal?) {
        let fee = recalculateFee(enteredFee: enteredFee)

        output?.setCustomFee(fee)
        if let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters {
            _customFeeGasPrice.send(ethereumFeeParameters.gasPrice)
            _customFeeGasLimit.send(ethereumFeeParameters.gasLimit)
        }
    }

    private func onGasPriceFocusChanged(_ focused: Bool) {
        if focused {
            customGasPriceBeforeEditing = _customFeeGasPrice.value
        } else {
            let customGasPriceAfterEditing = _customFeeGasPrice.value
            if customGasPriceAfterEditing != customGasPriceBeforeEditing {
                Analytics.log(.sendGasPriceInserted)
            }

            customGasPriceBeforeEditing = nil
        }
    }
}

// MARK: - private extensions

private extension Decimal {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: self)
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.decimal }.eraseToAnyPublisher()
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
