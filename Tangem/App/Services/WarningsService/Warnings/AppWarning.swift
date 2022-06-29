//
//  AppWarning.swift
//  Tangem
//
//  Created by Andrew Son on 22/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WarningPriority: String, Decodable {
    case info
    case warning
    case critical
}

enum WarningType: String, Decodable {
    case temporary
    case permanent
    
    var isWithAction: Bool {
        self == .temporary
    }
}

enum WarningsLocation: String, Decodable {
    case main
    case send
}

struct AppWarning: Decodable, Hashable {
    let title: String
    let message: String
    let priority: WarningPriority
    
    var type: WarningType = .permanent
    var location: [WarningsLocation] = [.main]
    
    // Warning settings
    var blockchains: [String]?
    var event: WarningEvent?
    
    init(title: String, message: String, priority: WarningPriority, type: WarningType = .permanent,
         location: [WarningsLocation] = [.main], blockchains: [String]? = nil, event: WarningEvent? = nil) {
        self.title = title
        self.message = message
        self.priority = priority
        self.type = type
        self.location = location
        self.blockchains = blockchains
        self.event = event
    }
    
    init(from remote: RemoteAppWarning) {
        title = remote.title
        message = remote.message
        priority = remote.priority
        if let type = remote.type {
            self.type = type
        }
        if let location = remote.location {
            self.location = location
        }
        blockchains = remote.blockchains
    }
    
    static func fetch(remote: [RemoteAppWarning]) -> [AppWarning] {
        remote.map { AppWarning(from: $0) }
    }
}

struct RemoteAppWarning: Decodable {
    let title: String
    let message: String
    let priority: WarningPriority
    
    var type: WarningType?
    var location: [WarningsLocation]?
    
    // Warning settings
    var blockchains: [String]?
}
