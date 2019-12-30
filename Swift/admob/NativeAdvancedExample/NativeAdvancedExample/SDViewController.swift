//
//  SDViewController.swift
//  NativeAdvancedExample
//
//  Created by Fritz Ammon on 12/30/19.
//  Copyright © 2019 Google. All rights reserved.
//

import Foundation
import UIKit

class SDViewController: UIViewController, NativeAdViewProtocol {
    @IBOutlet weak var adPlaceholder: UIView!
    @IBOutlet weak var reloadAdButton: UIButton!
    
    var nativeAdView: NativeAdView?
    
    // GADAppId
    // ca-app-pub-3940256099942544~1458002511
    let testAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadAd()
    }
    
    func reloadAd() {
        reloadAdButton.isEnabled = false
        
        nativeAdView?.removeFromSuperview()
        
        nativeAdView = NativeAdView.newAd(with: testAdUnitID, for: self, customTargeting: [:])
        nativeAdView?.delegate = self
    }
    
    @IBAction func reloadAdTapped(_ sender: Any) {
        reloadAd()
    }
    
    func adLoadedSuccessfully() {
        reloadAdButton.isEnabled = true
        
        guard let validNativeAdView = nativeAdView else { return }
        
        adPlaceholder.addSubviewAndCover(validNativeAdView)
    }
    
    func adFailedToLoad() {
        reloadAdButton.isEnabled = true
    }
}
