//
//  CoinView.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum CoinViewManageButtonType {
    case add
    case edit
    case info
}

struct CoinView: View {
    @ObservedObject var model: CoinViewModel
    var subtitle: String = Localization.currencySubtitleExpanded

    let iconWidth: Double = 46

    @State private var isExpanded = false

    private var symbolFormatted: String { " \(model.symbol)" }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: model.imageURL, size: CGSize(width: iconWidth, height: iconWidth), forceKingfisher: true)
                    .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(model.name)
                            .lineLimit(1)

                        Text(symbolFormatted)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    HStack(spacing: 4) {
                        Text(model.price)
                            .lineLimit(1)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                        TokenPriceChangeView(state: model.priceChange)
                    }
                }

                Spacer(minLength: 13)

                if let priceHistory = model.priceHistory {
                    LineChartView(
                        color: model.priceHistoryChangeType.textColor,
                        data: priceHistory
                    )
                    .frame(width: 50, height: 37, alignment: .center)
                }

                Spacer(minLength: 24)

                manageButton(for: model.manageType)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 10)
        .animation(nil) // Disable animations on scroll reuse
    }

    @ViewBuilder
    private func manageButton(for type: CoinViewManageButtonType) -> some View {
        ZStack {
            switch type {
            case .add:
                Button {
                    print("add")
                } label: {
                    AddButtonView()
                }
            case .edit:
                Button {
                    print("edit")
                } label: {
                    EditButtonView()
                }
            case .info:
                Image(systemName: "info.circle")
            }

            AddButtonView()
                .hidden()

            EditButtonView()
                .hidden()
        }
    }
}

private struct AddButtonView: View {
    var body: some View {
        TextButtonView(text: "Add", foreground: Colors.Text.primary2, background: Colors.Button.primary)
    }
}

private struct EditButtonView: View {
    var body: some View {
        TextButtonView(text: "Edit", foreground: Colors.Text.primary1, background: Colors.Button.secondary)
    }
}

private struct TextButtonView: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .style(Fonts.Bold.caption1, color: foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}

struct CurrencyViewNew_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/bitcoin/info/logo.png")!,
                name: "Bitcoin",
                symbol: "BTC",
                price: "$23,034.83",
                priceChange: .loaded(signType: .positive, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13],
                manageType: .add
            ))
//            .border(Color.blue.opacity(0.3))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Ethereum",
                symbol: "ETH",
                price: "$1,340.33",
                priceChange: .loaded(signType: .negative, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13].reversed(),
                manageType: .add
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png")!,
                name: "Solana",
                symbol: "SOL",
                price: "$33.00",
                priceChange: .loaded(signType: .positive, text: "1.3%"),
                priceHistory: [1, 7, 3, 5, 13],
                manageType: .add
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/polygon/info/logo.png")!,
                name: "Polygon",
                symbol: "MATIC",
                price: "$34.83",
                priceChange: .loaded(signType: .same, text: "0.0%"),
                priceHistory: [4, 7, 3, 5, 4],
                manageType: .edit
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/acalaevm/info/logo.png")!,
                name: "Very long token name is very long",
                symbol: "BUS",
                price: "$23,341,324,034.83",
                priceChange: .loaded(signType: .positive, text: "1,340,340.0%"),
                priceHistory: [1, 7, 3, 5, 13],
                manageType: .info
            ))
            
            CoinView(model: CoinViewModel(
                imageURL: nil,
                name: "Custom Token",
                symbol: "CT",
                price: "$100.83",
                priceChange: .loaded(signType: .positive, text: "1.0%"),
                priceHistory: nil,
                manageType: .add
            ))

            Spacer()
        }
//        .border(Color.blue.opacity(0.3))
        .padding()
    }
}
