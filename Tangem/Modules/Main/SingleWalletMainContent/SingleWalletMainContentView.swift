//
//  SingleWalletMainContentView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleWalletMainContentView: View {
    @ObservedObject var viewModel: SingleWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(itemsHorizontalOffset: 16, buttonsInfo: viewModel.actionButtons)

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            ForEach(viewModel.tokenNotificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            MarketPriceView(
                currencySymbol: viewModel.currencySymbol,
                price: viewModel.rateFormatted,
                priceChangeState: viewModel.priceChangeState,
                tapAction: nil
            )

            TransactionsListView(
                state: viewModel.transactionHistoryState,
                exploreAction: viewModel.openExplorer,
                exploreTransactionAction: viewModel.openTransactionExplorer,
                reloadButtonAction: viewModel.reloadHistory,
                isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                fetchMore: viewModel.fetchMoreHistory()
            )
        }
        .animation(.default, value: viewModel.notificationInputs)
        .animation(.default, value: viewModel.tokenNotificationInputs)
        .padding(.horizontal, 16)
        .bindAlert($viewModel.alert)
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel: SingleWalletMainContentViewModel = {
        let mainCoordinator = MainCoordinator()
        let userWalletModel = FakeUserWalletModel.xrpNote
        let walletModel = userWalletModel.walletModelsManager.walletModels.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [userWalletModel])
        let cryptoUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        return SingleWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            walletModel: userWalletModel.walletModelsManager.walletModels.first!,
            exchangeUtility: cryptoUtility,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            tokenNotificationManager: FakeUserWalletNotificationManager(),
            rateAppController: RateAppControllerStub(),
            tokenRouter: SingleTokenRoutableMock(),
            mainViewDelegate: nil
        )
    }()

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
            .background(Colors.Background.secondary)
    }
}
