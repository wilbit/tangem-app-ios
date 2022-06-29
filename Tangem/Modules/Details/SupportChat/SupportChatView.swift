//
//  ChatView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportChatView: UIViewControllerRepresentable {
    let viewModel: SupportChatViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        guard let viewController = try? viewModel.buildUI() else {
            return UIViewController(nibName: nil, bundle: nil)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
