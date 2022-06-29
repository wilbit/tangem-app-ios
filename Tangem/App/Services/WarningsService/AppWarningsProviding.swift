//
//  AppWarningsProviding.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol AppWarningsProviding: AnyObject {
    var warningsUpdatePublisher: PassthroughSubject<WarningsLocation, Never> { get }

    func setupWarnings(for cardInfo: CardInfo)
    func appendWarning(for event: WarningEvent)
    func warnings(for location: WarningsLocation) -> WarningsContainer
    func hideWarning(_ warning: AppWarning)
    func hideWarning(for event: WarningEvent)
}

private struct AppWarningsProvidingKey: InjectionKey {
    static var currentValue: AppWarningsProviding = WarningsService()
}

extension InjectedValues {
    var appWarningsService: AppWarningsProviding {
        get { Self[AppWarningsProvidingKey.self] }
        set { Self[AppWarningsProvidingKey.self] = newValue }
    }
}
