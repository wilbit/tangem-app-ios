//
//  SingleWalletNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 29/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

final class SingleTokenNotificationManager {
    private let analyticsService: NotificationsAnalyticsService = .init()

    private let walletModel: WalletModel
    private let swapPairService: SwapPairService?
    private weak var delegate: NotificationTapDelegate?

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var bag: Set<AnyCancellable> = []
    private var notificationsUpdateTask: Task<Void, Never>?

    private var canShowCrosschainPromotion: Bool {
        guard swapPairService != nil else { return false }
        return !AppSettings.shared.crosschainExchangeTokenPromoDismissed && TangemExpressPromotionUtility().isPromotionRunning
    }

    init(walletModel: WalletModel, swapPairService: SwapPairService?, contextDataProvider: AnalyticsContextDataProvider?) {
        self.walletModel = walletModel
        self.swapPairService = swapPairService

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func bind() {
        bag = []

        walletModel
            .walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.notificationsUpdateTask?.cancel()

                switch state {
                case .failed:
                    self?.setupNetworkUnreachable()
                case .noAccount(let message):
                    self?.setupNoAccountNotification(with: message)
                case .loading, .created:
                    break
                case .idle, .noDerivation:
                    self?.setupLoadedStateNotifications()
                }
            }
            .store(in: &bag)

        if canShowCrosschainPromotion, let swapPairService {
            swapPairService.canSwap()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] canSwap in
                    guard let self else { return }
                    setupCrosschainPromotionNotification(showPromotion: canSwap && canShowCrosschainPromotion)
                }
                .store(in: &bag)
        }
    }

    private func setupLoadedStateNotifications() {
        let factory = NotificationsFactory()

        var events = [TokenNotificationEvent]()
        if let existentialWarning = walletModel.existentialDepositWarning {
            events.append(.existentialDepositWarning(message: existentialWarning))
        }

        if let sendBlockedReason = walletModel.sendBlockedReason {
            events.append(.event(for: sendBlockedReason))
        }

        let inputs = events.map {
            factory.buildNotificationInput(
                for: $0,
                buttonAction: { [weak self] id, actionType in
                    self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                },
                dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }
            )
        }

        notificationInputsSubject.send(inputs)

        notificationsUpdateTask?.cancel()
        notificationsUpdateTask = Task { [weak self] in
            guard
                let rentInput = await self?.loadRentNotificationIfNeeded(),
                let self
            else {
                return
            }

            if Task.isCancelled {
                return
            }

            if !notificationInputsSubject.value.contains(where: { $0.id == rentInput.id }) {
                await runOnMain {
                    self.notificationInputsSubject.value.append(rentInput)
                }
            }
        }
    }

    private func setupNetworkUnreachable() {
        let factory = NotificationsFactory()
        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: .networkUnreachable(currencySymbol: walletModel.blockchainNetwork.blockchain.currencySymbol),
                    dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
                ),
            ])
    }

    private func setupCrosschainPromotionNotification(showPromotion: Bool) {
        let factory = NotificationsFactory()
        let input = factory.buildNotificationInput(
            for: .crosschainSwapPromotion,
            buttonAction: { [weak self] id, actionType in
                self?.delegate?.didTapNotificationButton(with: id, action: actionType)
            },
            dismissAction: { [weak self] id in
                self?.dismissNotification(with: id)
            }
        )

        if !showPromotion {
            notificationInputsSubject.value.removeAll { $0.id == input.id }
        } else if !notificationInputsSubject.value.contains(where: { $0.id == input.id }) {
            notificationInputsSubject.value.append(input)
        }
    }

    private func setupNoAccountNotification(with message: String) {
        let factory = NotificationsFactory()
        let event = TokenNotificationEvent.noAccount(message: message)

        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: event,
                    buttonAction: { [weak self] id, actionType in
                        self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                    },
                    dismissAction: { [weak self] id in
                        self?.dismissNotification(with: id)
                    }
                ),
            ])
    }

    private func loadRentNotificationIfNeeded() async -> NotificationViewInput? {
        guard walletModel.hasRent else { return nil }

        guard let rentMessage = await walletModel.updateRentWarning().async() else {
            return nil
        }

        if Task.isCancelled {
            return nil
        }

        let factory = NotificationsFactory()
        let input = factory.buildNotificationInput(
            for: .rentFee(rentMessage: rentMessage),
            dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
        )
        return input
    }
}

extension SingleTokenNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupLoadedStateNotifications()
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let notification = notificationInputsSubject.value.first(where: { $0.id == id }) else {
            return
        }

        guard let event = notification.settings.event as? TokenNotificationEvent else {
            return
        }

        switch event {
        case .crosschainSwapPromotion:
            AppSettings.shared.crosschainExchangeTokenPromoDismissed = true
        default:
            break
        }

        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
