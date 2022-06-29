//
//  ShopViewRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ShopViewRoutable: AnyObject {
    func openWebCheckout(at url: URL)
    func closeWebCheckout()
}
