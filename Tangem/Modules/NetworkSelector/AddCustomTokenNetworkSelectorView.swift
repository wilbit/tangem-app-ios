//
//  AddCustomTokenNetworkSelectorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenNetworkSelectorView: View {
    @ObservedObject private var viewModel: AddCustomTokenNetworkSelectorViewModel

    init(viewModel: AddCustomTokenNetworkSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(viewModel.itemViewModels, id: \.networkId) { itemViewModel in
                    AddCustomTokenNetworkSelectorItemView(viewModel: itemViewModel)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(14)
            .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
    }
}

struct AddCustomTokenNetworkSelectorView_Preview: PreviewProvider {
    static let viewModel = AddCustomTokenNetworkSelectorViewModel(selectedBlockchain: .ethereum(testnet: true), blockchains: SupportedBlockchains.all.filter(\.isTestnet), coordinator: AddCustomTokenNetworkSelectorCoordinator())

    static var previews: some View {
        AddCustomTokenNetworkSelectorView(viewModel: viewModel)
    }
}
