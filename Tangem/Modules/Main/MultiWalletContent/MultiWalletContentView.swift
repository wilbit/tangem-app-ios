//
//  MultiWalletContentView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletContentView: View {
    @ObservedObject var viewModel: MultiWalletContentViewModel

    var body: some View {
        VStack {
            Text("Hello, Multiwallet!")
        }
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static let viewModel = MultiWalletContentViewModel(coordinator: MultiWalletContentCoordinator())

    static var previews: some View {
        MultiWalletContentView(viewModel: viewModel)
    }
}
