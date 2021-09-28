//
//  OnboardingStep.swift
//  Tangem Tap
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum OnboardingSteps {
    case singleWallet([SingleCardOnboardingStep]), twins([TwinsOnboardingStep]), wallet([WalletOnboardingStep])
    
    var needOnboarding: Bool {
        switch self {
        case .singleWallet(let steps):
            return steps.count > 0
        case .twins(let steps):
            return steps.count > 0
        case .wallet(let steps):
            return steps.count > 0
        }
    }
}

typealias OnboardingStep = OnboardingProgressStepIndicatable & OnboardingMessagesProvider & OnboardingButtonsInfoProvider & OnboardingInitialStepInfo

protocol OnboardingMessagesProvider {
    var title: LocalizedStringKey { get }
    var subtitle: LocalizedStringKey { get }
    var messagesOffset: CGSize { get }
}

protocol OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey { get }
    var supplementButtonTitle: LocalizedStringKey { get }
    var isSupplementButtonVisible: Bool { get }
    var isContainSupplementButton: Bool { get }
}

protocol OnboardingInitialStepInfo {
    static var initialStep: Self { get }
}