//
//  ReferralPlaceholderPointView.swift
//  Tangem
//
//  Created by Andrew Son on 02/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReferralPlaceholderPointView: View {
    private let icon: Image

    init(@ViewBuilder _ icon: () -> Image) {
        self.icon = icon()
    }

    var body: some View {
        HStack(spacing: 14) {
            icon
                .padding(14)
                .background(Colors.Button.secondary)
                .cornerRadius(16)
            
            VStack(alignment: .leading) {
                Color.white
                    .skeletonable(isShown: true, size: .init(width: 102, height: 21), radius: 6)
                
                Color.white
                    .skeletonable(isShown: true, size: .init(width: 40, height: 11), radius: 3)
            }
            
            Spacer()
        }
    }
}

struct ReferralLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralPlaceholderPointView { Assets.cryptocurrencies }
    }
}
