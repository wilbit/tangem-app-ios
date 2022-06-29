//
//  Environment.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum AppEnvironment: String {
    case beta = "Beta"
    case production = "Production"

    static var current: AppEnvironment {
        guard let environmentName = Bundle.main.infoDictionary?["ENVIRONMENT_NAME"] as? String else {
            assertionFailure("ENVIRONMENT_NAME not found")
            return .production
        }

        guard let environment = AppEnvironment(rawValue: environmentName) else {
            assertionFailure("ENVIRONMENT_NAME not correct")
            return .production
        }

        return environment
    }
}
