//
//  UserWalletListCoordinator.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletListCoordinatorRoutable: AnyObject {
    func didTapUserWallet(userWallet: UserWallet)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
}

class UserWalletListCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>
    weak var router: UserWalletListCoordinatorRoutable?

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UserWalletListViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>,
        router: UserWalletListCoordinatorRoutable
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.router = router
    }

    func start(with options: Options) {

    }
}

// MARK: - Options

extension UserWalletListCoordinator {
    enum Options {

    }
}

// MARK: - UserWalletListRoutable

extension UserWalletListCoordinator: UserWalletListRoutable {
    func didTapUserWallet(userWallet: UserWallet) {
        router?.didTapUserWallet(userWallet: userWallet)
    }

    func openMail(with dataCollector: EmailDataCollector) {
        dismissAction()

        let dismissingDelay = 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissingDelay) {
            self.router?.openMail(with: dataCollector, emailType: .failedToScanCard, recipient: EmailConfig.default.recipient)
        }
    }
}
