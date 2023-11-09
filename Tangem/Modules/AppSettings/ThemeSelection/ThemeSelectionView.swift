//
//  ThemeSelectionView.swift
//  Tangem
//
//  Created by Andrew Son on 08/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ThemeSelectionView: View {
    @ObservedObject var viewModel: ThemeSelectionViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                SelectableGropedSection(
                    viewModel.themeViewModels,
                    selection: $viewModel.currentThemeOption,
                    content: {
                        DefaultSelectableRowView(viewModel: $0)
                    },
                    footer: {
                        Text(Localization.appSettingsThemeSelectionFooter)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                )
            }
        }
        .navigationTitle(Text(Localization.appSettingsThemeSelectorTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView(content: {
        ThemeSelectionView(viewModel: .init())
    })
}
