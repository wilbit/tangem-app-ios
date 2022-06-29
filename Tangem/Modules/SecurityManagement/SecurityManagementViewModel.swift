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
    
    var isOptionDisabled: Bool {
        selectedOption == cardViewModel.currentSecOption
    }
    
    var cardViewModel: CardViewModel
    
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: SecurityManagementRoutable
    
    init(cardModel: CardViewModel, coordinator: SecurityManagementRoutable) {
        self.cardViewModel = cardModel
        self.coordinator = coordinator
        selectedOption = cardModel.currentSecOption
        
        cardViewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.selectedOption = self?.cardViewModel.currentSecOption ?? .longTap
                self?.objectWillChange.send()
            })
            .store(in: &bag)
    }
    
    func onTap() {
        switch selectedOption {
        case .accessCode, .passCode:
            openPinChange()
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
//        navigation.securityToWarning = true
        
        cardViewModel.changeSecOption(.accessCode) { result in
            print(result)
        }
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

// MARK: - Navigation
extension SecurityManagementViewModel {
    func openPinChange() {
        coordinator.openPinChange(with: selectedOption.title) { [weak self] completion in
            guard let self = self else { return }
            
            self.cardViewModel.changeSecOption(self.selectedOption, completion: completion)
        }
    }
}
