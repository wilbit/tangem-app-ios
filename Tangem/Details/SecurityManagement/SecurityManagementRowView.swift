//
//  SecurityManagementRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SecurityManagementRowView: View {
    @Binding var selectedOption: SecurityManagementOption
    let option: SecurityManagementOption

    let isEnabled: Bool
    var isSelected: Bool { selectedOption == option }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            HStack (alignment: .lastTextBaseline) {
                Text(option.title)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
                    .padding(.top, 16.0)
                    .padding([.bottom, .leading, .trailing], 8.0)
                    .opacity(isEnabled ? 1.0 : 0.5)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Font.system(size: 21.0, weight: .light, design: .default))
                    .foregroundColor(isSelected ? Color.tangemBlueLight : Color.tangemGrayLight4)
            }
            Text(option.subtitle)
                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                .foregroundColor(.tangemGrayDark)
                .padding([.top, .leading, .trailing], 8.0)
                .padding(.bottom, 26.0)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if self.isEnabled {
                self.selectedOption = self.option
            }
        }
        .overlay(isEnabled ? Color.clear : Color.white.opacity(0.4))
    }
}
