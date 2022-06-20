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

class SecurityManagementViewModel: ViewModel, ObservableObject {
    @Published var error: AlertBinder?
    @Published var availableSecOptions: [SecurityManagementOption] = []
    @Published var selectedOption: SecurityManagementOption = .longTap
    
    @Published var isLoading: Bool = false
    
    var currentSecOption: SecurityManagementOption { cardViewModel.currentSecOption }
    
    var showAccessCodeDisclaimer: String? {
        if cardViewModel.cardInfo.isTangemWallet, cardViewModel.cardInfo.card.backupStatus == .noBackup {
            return "manage_security_access_code_disclaimer".localized
        }
        
        return nil
    }
    
    var actionButtonPressedHandler: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void {
        return { completion in
            self.cardViewModel.changeSecOption(self.selectedOption,
                                                 completion: completion) }
    }
    
    private var bag = Set<AnyCancellable>()
    private var cardViewModel: CardViewModel
    
    init(cardViewModel: CardViewModel) {
        self.cardViewModel = cardViewModel
        
        self.availableSecOptions = cardViewModel.availableSecOptions
        self.selectedOption = cardViewModel.currentSecOption
    }
    
    func cardViewModelBinding() {
        self.cardViewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.availableSecOptions = self?.cardViewModel.availableSecOptions ?? []
                
                self?.selectedOption = self?.cardViewModel.currentSecOption ?? .longTap
                self?.objectWillChange.send()
            })
            .store(in: &bag)
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
