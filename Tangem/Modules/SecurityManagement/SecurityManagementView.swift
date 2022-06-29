//
//  SecurityManagementView.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct SecurityManagementView: View {
    @ObservedObject var viewModel: SecurityManagementViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                securitySection
                
                privacySection
            }
            .listRowInsets(EdgeInsets())
            .listStyle(GroupedListStyle())
            
            actionButton
            
            NavigationLink(destination: CardOperationView(title: viewModel.selectedOption.title,
                                                          alert: "details_security_management_warning".localized,
                                                          actionButtonPressed: viewModel.actionButtonPressedHandler),
                           isActive: $navigation.securityToWarning)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_manage_security_title", displayMode: .inline)
    }
    
    // MARK: - SecuritySection
    
    @ViewBuilder
    private var securitySection: some View {
        Section(content: {
            ForEach(viewModel.availableSecOptions) { option in
                SecurityManagementRowView(
                    selectedOption: $viewModel.selectedOption,
                    option: option,
                    isEnabled: viewModel.isEnabled(option: option)
                )
            }
        }, header: {
            Text("details_manage_security_title")
        }, footer: {
            firstSectionFooter
        })
    }
    
    @ViewBuilder
    private var firstSectionFooter: some View {
        if viewModel.showAccessCodeDisclaimer {
            HStack(alignment: .center, spacing: 0) {
                Text("manage_security_access_code_disclaimer".localized)
                    .font(.body)
                    .foregroundColor(.tangemGrayDark)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Privacy Section
    
    @ViewBuilder
    private var privacySection: some View {
        if !viewModel.availablePrivacyOptions.isEmpty {
            Section(content: {
                ForEach(viewModel.availablePrivacyOptions) { option in
                    Button {
                        viewModel.resetAccessCode()
                    } label: {
                        Text("Reset access code")
                    }
                }
            }, header: {
                Text("details_manage_security_title")
            })
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        TangemButton(title: viewModel.selectedOption == .longTap ? "common_save_changes" : "common_continue") {
            self.viewModel.onTap()
        }.buttonStyle(TangemButtonStyle(colorStyle: .black,
                                        layout: .flexibleWidth,
                                        isDisabled: viewModel.selectedOption == viewModel.currentSecOption,
                                        isLoading: viewModel.isLoading))
            .alert(item: $viewModel.error) { $0.alert }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
    }
}


struct SecurityManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityManagementView(viewModel: .init(cardModel: PreviewCard.tangemWalletEmpty.cardModel,
                                                coordinator: SecurityManagementCoordinator()))
    }
}
