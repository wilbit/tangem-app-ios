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
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var body: some View {
        VStack {
            List {
                Section(content: {
                    ForEach(viewModel.availableSecOptions) { option in
                        SecurityManagementRowView(
                            selectedOption: $viewModel.selectedOption,
                            option: option,
                            isEnabled: viewModel.isEnabled(option: option)
                        )
//                            .environmentObject(self.viewModel.cardViewModel)
                    }
                }, footer: {
                    if viewModel.accessCodeDisclaimer != nil {
                        HStack(spacing: 0) {
                            Spacer()
                            Text(viewModel.accessCodeDisclaimer!)
                                .font(.body)
                                .foregroundColor(.tangemGrayDark)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                            Spacer()
                        }
                    } else {
                        EmptyView()
                    }
                })
            }
            .listRowInsets(EdgeInsets())
            .listStyle(GroupedListStyle())
            
            
            TangemButton(title: viewModel.selectedOption == .longTap ? "common_save_changes" : "common_continue") {
                self.viewModel.onTap()
            }.buttonStyle(TangemButtonStyle(colorStyle: .black,
                                            layout: .flexibleWidth,
                                            isDisabled: viewModel.selectedOption == viewModel.cardViewModel.currentSecOption,
                                            isLoading: viewModel.isLoading))
                .alert(item: $viewModel.error) { $0.alert }
                .padding(.horizontal, 16.0)
                .padding(.bottom, 16.0)
            
            NavigationLink(destination: CardOperationView(title: viewModel.selectedOption.title,
                                                          alert: "details_security_management_warning".localized,
                                                          actionButtonPressed: viewModel.actionButtonPressedHandler),
                           isActive: $navigation.securityToWarning)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_manage_security_title", displayMode: .inline)
    }
}


struct SecurityManagementView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    static let navigation = NavigationCoordinator()
    
    static var previews: some View {
        SecurityManagementView(viewModel: assembly.makeSecurityManagementViewModel(with: assembly.previewCardViewModel))
            .environmentObject(navigation)
    }
}
