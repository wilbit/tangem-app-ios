//
//  CardDetailsViewController.swift
//  Tangem
//
//  Created by Gennady Berezovsky on 24.07.18.
//  Copyright © 2018 dns user. All rights reserved.
//

import UIKit
import QRCode

class CardDetailsViewController: UIViewController {
    
    @IBOutlet var viewModel: CardDetailsViewModel!
    
    var cardDetails: Card?
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    
    let helper = NFCHelper()
    let cardParser = CardParser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cardParser.delegate = self
        self.helper.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupWithCardDetails()
    }
    
    func setupWithCardDetails() {
        setupUI()
        getBalance()
        setupBalanceVerified(false)
    }
    
    func setupUI() {
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        self.viewModel.walletBlockchainLabel.text = cardDetails.blockchain
        self.viewModel.walletAddressLabel.text = cardDetails.address
        
        var blockchainName = String()
        if cardDetails.type == .btc {
            blockchainName = "bitcoin:"
        } else {
            blockchainName = "ethereum:"
        }
        
        var qrCodeResult = QRCode(blockchainName + cardDetails.address)
        qrCodeResult?.size = self.viewModel.qrCodeImageView.frame.size
        self.viewModel.qrCodeImageView.image = qrCodeResult?.image
    }
    
    func verifyBalance() {
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        self.viewModel.balanceVerificationActivityIndicator.startAnimating()
        
        let balanceVerificationOperation = BalanceVerificationOperation(saltHex: cardDetails.salt, challengeHex: cardDetails.challenge, signatureArr: cardDetails.signArr, publicKeyArr: cardDetails.pubArr) { (result) in
            self.viewModel.balanceVerificationActivityIndicator.stopAnimating()
            self.setupBalanceVerified(result)
        }
        
        self.operationQueue.addOperation(balanceVerificationOperation)
    }
    
    func setupBalanceVerified(_ verified: Bool) {
        self.viewModel.balanceVerificationLabel.text = verified ? "Verified balance" : "Unverified balance"
        self.viewModel.balanceVerificationLabel.textColor = verified ? UIColor.green : UIColor.red
        let verificationIconName = verified ? "icon-verified" : "icon-unverified"
        self.viewModel.balanceVefificationIconImageView.image = UIImage(named: verificationIconName)
    }
    
    func getBalance() {

        let onResult = { (card: Card) in
            guard card.error == 0 else {
                let validationAlert = UIAlertController(title: "Error", message: "Cannot obtain full wallet data", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(validationAlert, animated: true, completion: nil)
                self.setupBalanceVerified(false)
                
                return
            }
            
            self.cardDetails = card
            self.viewModel.balanceLabel.text = card.walletValue + " " + card.walletUnits
            
            self.verifyBalance()
        }
        
        DispatchQueue.global(qos: .background).async {
            guard let card = self.cardDetails else {
                return
            }
            
            switch card.type {
            case .btc:
                BalanceService.sharedInstance.getBalanceBTC(card, onResult: onResult)
            case .eth:
                BalanceService.sharedInstance.getBalanceETH(card, onResult: onResult)
            case .seed:
                BalanceService.sharedInstance.getBalanceToken(card, onResult: onResult)
            default:
                break
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func exploreButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func copyButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func loadButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func extractButtonPressed(_ sender: Any) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: ModalActionViewController.self)) else {
            return
        }
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: self.view.frame.height - 200)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        self.showSimulationSheet()
        #else
        self.helper.restartSession()
        #endif
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        
    }
    
    func showSimulationSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let seedAction = UIAlertAction(title: "SEED", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.seed.rawValue)
        }
        let ethAction = UIAlertAction(title: "ETH", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.ethWallet.rawValue)
        }
        let ertAction = UIAlertAction(title: "ERT", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.ert.rawValue)
        }
        alertController.addAction(seedAction)
        alertController.addAction(ethAction)
        alertController.addAction(ertAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension CardDetailsViewController: NFCHelperDelegate {
    
    func nfcHelper(_ helper: NFCHelper, didInvalidateWith error: Error) {
        print("\(error.localizedDescription)")
    }
    
    func nfcHelper(_ helper: NFCHelper, didDetectCardWith hexPayload: String) {
        DispatchQueue.main.async {
            self.cardParser.parse(payload: hexPayload)
        }
    }
    
}

extension CardDetailsViewController: CardParserDelegate {
    
    func cardParserWrongTLV(_ parser: CardParser) {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParserLockedCard(_ parser: CardParser) {
        print("Card is locked, two first bytes are equal 0x6A86")
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParser(_ parser: CardParser, didFinishWith card: Card) {
        operationQueue.cancelAllOperations()
        
        cardDetails = card
        setupWithCardDetails()
    }
}
