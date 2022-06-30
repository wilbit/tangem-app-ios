//
//  DetailsCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: DetailsCoordinator
    
    var body: some View {
        ZStack {
            if let model = coordinator.detailsViewModel {
                DetailsView(viewModel: model)
                    .navigationLinks(links)
            }
            
            sheets
        }
    }
    
    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .navigation(item: $coordinator.currencySelectViewModel) {
                CurrencySelectView(viewModel: $0)
            }
            .navigation(item: $coordinator.secManagementCoordinator) {
                SecurityManagementCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.walletConnectCoordinator) {
                WalletConnectCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.cardOperationViewModel) {
                CardOperationView(viewModel: $0)
            }
            .navigation(item: $coordinator.disclaimerViewModel) {
                DisclaimerView(viewModel: $0)
            }
            .navigation(item: $coordinator.supportChatViewModel) {
                SupportChatView(viewModel: $0)
                    .edgesIgnoringSafeArea(.vertical)
            }
    }
    
    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
        
        NavHolder()
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
        
        NavHolder()
           
    }
}