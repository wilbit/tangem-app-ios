//
//  PersistentStorageKey.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PersistentStorageKey {
    case cards
    case wallets(cid: String)

    var path: String {
        switch self {
        case .cards:
            return "scanned_cards"
        case .wallets(let cid):
            return "wallets_\(cid)"
        }
    }
}
