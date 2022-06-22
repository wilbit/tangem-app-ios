//
//  SecurityManagementViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemSdk

class SecurityManagementViewModel: ViewModel, ObservableObject {
    @Injected(\.appFeaturesService) private var featuresService: AppFeaturesProviding
    
    @Published var error: AlertBinder?
    @Published var availableSecOptions: [SecurityManagementOption] = []
    @Published var availablePrivacyOptions: [PrivacyManagementOption] = []
    
    @Published var selectedOption: SecurityManagementOption = .longTap
    
    @Published var isLoading: Bool = false
    
    var currentSecOption: SecurityManagementOption { cardViewModel.currentSecOption }
    
    var showAccessCodeDisclaimer: Bool {
        if cardViewModel.cardInfo.isTangemWallet,
           cardViewModel.cardInfo.card.backupStatus == .noBackup {
            return true
        }
        
        return false
    }
    
    var actionButtonPressedHandler: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void {
        return { completion in
            self.cardViewModel.changeSecOption(self.selectedOption,
                                                 completion: completion) }
    }
    
    private var bag = Set<AnyCancellable>()
    private var cardViewModel: CardViewModel
    private var card: Card { cardViewModel.cardInfo.card }
    
    init(cardViewModel: CardViewModel) {
        self.cardViewModel = cardViewModel
        
        self.selectedOption = cardViewModel.currentSecOption
        
        super.init()
        
        updateAvailableSecOptions()
        updateAvailablePrivacyOptions()
    }
    
    func cardViewModelBinding() {
        cardViewModel
            .$currentSecOption
            .weakAssign(to: \.selectedOption, on: self)
            .store(in: &bag)
    }
    
    func updateAvailableSecOptions() {
        var options = [SecurityManagementOption.longTap]
        
        if featuresService.canSetAccessCode || currentSecOption == .accessCode {
            options.append(.accessCode)
        }

        if featuresService.canSetPasscode || card.isTwinCard || currentSecOption == .passCode {
            options.append(.passCode)
        }

        availableSecOptions = options
    }
    
    func updateAvailablePrivacyOptions() {
        availablePrivacyOptions.append(.resetPassword)
    }
    
    func onTap() {
        switch selectedOption {
        case .accessCode, .passCode:
            navigation.securityToWarning = true
        case .longTap:
            isLoading = true
            cardViewModel.changeSecOption(.longTap) { result in
                self.isLoading = false
                switch result {
                case .success:
                    break
                case .failure(let error):
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    self.error = error.alertBinder
                }
            }
        }
    }
    
    func resetAccessCode() {
        navigation.securityToWarning = true
        
//        cardViewModel.changeSecOption(.accessCode) { result in
//            print(result)
//        }
    }
    
    func isEnabled(option: SecurityManagementOption) -> Bool {
        switch option {
        case .accessCode:
            return cardViewModel.canSetAccessCode
        case .longTap:
            return cardViewModel.canSetLongTap
        case .passCode:
            return cardViewModel.canSetPasscode
        }
    }
}


enum SecurityManagementOption: CaseIterable, Identifiable {
    case longTap
    case passCode
    case accessCode
    
    var id: String { "\(self)" }
    
    var title: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code".localized
        case .longTap:
            return "details_manage_security_long_tap".localized
        case .passCode:
            return "details_manage_security_passcode".localized
        }
    }
    
    var subtitle: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code_description".localized
        case .longTap:
            return "details_manage_security_long_tap_description".localized
        case .passCode:
            return "details_manage_security_passcode_description".localized
        }
    }
}

enum PrivacyManagementOption: String, CaseIterable, Identifiable {
    case resetPassword
    
    var id: String { rawValue }
}
