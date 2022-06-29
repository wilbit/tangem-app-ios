//
//  StoriesTangemLogo.swift
//  Tangem
//
//  Created by Andrey Chukavin on 17.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoriesTangemLogo: View {
    var body: some View {
        HStack {
            Image("tangemLogo")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 19)
            Spacer()
        }
        .padding(.top)
    }
}

struct StoriesTangemLogo_Previews: PreviewProvider {
    static var previews: some View {
        StoriesTangemLogo()
    }
}
