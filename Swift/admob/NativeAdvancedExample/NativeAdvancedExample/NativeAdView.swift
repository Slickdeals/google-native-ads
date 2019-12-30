//
//  NativeAdView.swift
//  Slickdeals
//
//  Created by Sanju Varghese on 8/29/17.
//  Copyright © 2017 Slickdeals, LLC. All rights reserved.
//

import GoogleMobileAds

enum NativeAdSize {
    case h100
    case h250

    var height: CGFloat {
        switch self {
        case .h100:
            return 100
        case .h250:
            return 250
        }
    }
}

class SDGADUnifiedNativeAdView: GADUnifiedNativeAdView {
    @IBOutlet weak var adLabelView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        adLabelView?.layer.cornerRadius = 2
    }
}

protocol NativeAdViewProtocol: class {
    func adLoadedSuccessfully()
}

protocol LoadableAdView: class {
    var adDelegate: NativeAdViewProtocol? { get set }
    var adLoadedSuccessfully: Bool { get set }
    var viewHeight: CGFloat { get }
}

class NativeAdView: UIView, LoadableAdView {
    weak var delegate: NativeAdViewProtocol?
    weak var displayingViewController: UIViewController?
    var adLoadedSuccessfully = false
    var googleDFPAdLoader: GADAdLoader?
    var isLoading = false
    var placementId = ""
    var size: NativeAdSize = .h100
    var directDFPBannerView: DFPBannerView? //Used when only banner ads should be filled
    var customTargeting: [AnyHashable: Any] = [:]
    
    class func newAd(with placementId: String, for viewController: UIViewController, customTargeting: [AnyHashable: Any]) -> NativeAdView? {
        let adView = NativeAdView()
        adView.displayingViewController = viewController
        adView.placementId = placementId
        
        adView.translatesAutoresizingMaskIntoConstraints = false // To stop temporary constraints from being created
        
        adView.customTargeting += adView.defaultTargeting + customTargeting
        
        adView.isLoading = true
        adView.setupAdLoaders()
        
        return adView
    }
    
    func loadDFPAdRequest() {
        // Initialize and load the request
        let request = DFPRequest()
        
        let customTargetingValues: [AnyHashable: Any] = defaultTargeting + customTargeting
        
        request.customTargeting = customTargetingValues

        googleDFPAdLoader?.load(request)
    }
    
    func setupAdLoaders() {
        // Ad options
        let adOptions = GADNativeAdViewAdOptions()
        adOptions.preferredAdChoicesPosition = .topRightCorner
        
        // Ad types
        let adTypes: [GADAdLoaderAdType] = [.unifiedNative, .dfpBanner]
        
        // Initialize loader and request
        self.googleDFPAdLoader = GADAdLoader(adUnitID: placementId, rootViewController: displayingViewController, adTypes: adTypes, options: [adOptions])
        self.googleDFPAdLoader?.delegate = self
        
        loadDFPAdRequest()
    }
}

// MARK: LoadableAdView conformance
extension NativeAdView {
    var adDelegate: NativeAdViewProtocol? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    var viewHeight: CGFloat { return size.height }
}

// MARK: - Google AdX Loader Delegate
extension NativeAdView: GADAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        isLoading = false
        adLoadedSuccessfully = false
    }
}

extension NativeAdView: GADUnifiedNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        guard let unifiedAdView = Bundle.main.loadNibNamed("DFPUnifiedNativeAdView", owner: nil, options: nil)?.first as? SDGADUnifiedNativeAdView else { return }
        
        // Layout
        self.removeFromSuperview()
        let heightConstraint = heightAnchor.constraint(equalToConstant: 100)
        heightConstraint.priority = UILayoutPriority(999) // Setting a lower priority to fix constraint warnings
        heightConstraint.isActive = true
        self.addSubviewAndCover(unifiedAdView)
        
        // Setting Ad
        unifiedAdView.nativeAd = nativeAd
        
        // Setting values
        (unifiedAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (unifiedAdView.storeView as? UILabel)?.text = nativeAd.store?.isEmpty == false ? nativeAd.store : nativeAd.advertiser
        (unifiedAdView.storeView as? UILabel)?.font = UIFont(name: "OpenSans-Italic", size: 10.0)
        (unifiedAdView.bodyView as? UILabel)?.text = nativeAd.body
        (unifiedAdView.bodyView as? UILabel)?.setLineHeight(lineHeight: 0.9)
        (unifiedAdView.callToActionView as? UIButton)?.setTitle(
            nativeAd.callToAction, for: .normal)
        
        // Required by Google to keep their interaction behavior consistent
        unifiedAdView.callToActionView?.isUserInteractionEnabled = false
        
        // Delegate stuff
        adLoadedSuccessfully = true
        isLoading = false
        delegate?.adLoadedSuccessfully()
    }
}

extension NativeAdView {
    var defaultTargeting: [AnyHashable: Any] {
        return [
            "SomeKey": "SomeValue"
        ]
    }
}

// MARK: - Stuff to get this SD sample project to work

func += <K, V> (left: inout Dictionary<K,V>, right: Dictionary<K, V>?) {
    guard let right = right else {
        return
    }
    
    right.forEach {
        key, value in
        
        left.updateValue(value, forKey: key)
    }
}

func + <K, V> (left: Dictionary<K, V>, right: Dictionary<K, V>?) -> Dictionary<K, V> {
    guard let right = right else {
        return left
    }
    
    return left.reduce(right) {
        var new = $0 as [K: V]
        new.updateValue($1.1, forKey: $1.0)
        
        return new
    }
}

public typealias SimpleConstraint = (NSLayoutConstraint.Attribute, CGFloat)

extension UIView {
    public static let coverConstraints: [SimpleConstraint] = [
        (.top, 0),
        (.left, 0),
        (.bottom, 0),
        (.right, 0)
    ]
    
    public func addSubview(_ view: UIView, withConstraints constraints: [SimpleConstraint]){
        self.addSubview(view)
        
        self.addConstraints(constraints, forView: view)
    }
    
    @discardableResult
    public func addSubviewAndCover(_ view: UIView, withConstraintsForCover constraints: [NSLayoutConstraint] = []) -> UIView {
        self.addConstraints(constraints)
        self.addSubview(view, withConstraints: UIView.coverConstraints)
        return self
    }
    
    public static func addSubviewAndCover(_ view: UIView, withConstraintsForCover constraints: [NSLayoutConstraint] = []) -> UIView {
        return UIView(frame: view.frame).addSubviewAndCover(view, withConstraintsForCover: constraints)
    }
    
    public func addConstraints(_ constraints: [SimpleConstraint]) {
        addConstraints(constraints, forView: self)
    }
    
    @discardableResult
    public func addConstraints(_ constraints: [SimpleConstraint], forView view: UIView) -> [NSLayoutConstraint] {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        var addedConstraints: [NSLayoutConstraint] = []
        
        for (attribute, constant) in constraints {
            if attribute == .width || attribute == .height {
                addedConstraints.append(NSLayoutConstraint(
                    item: view,
                    attribute: attribute,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1.0,
                    constant: constant
                ))
                self.addConstraint(
                    addedConstraints.last!
                )
            }
            else if attribute == .top || attribute == .left || attribute == .bottom || attribute == .right {
                addedConstraints.append(NSLayoutConstraint(
                    item: view,
                    attribute: attribute,
                    relatedBy: .equal,
                    toItem: self,
                    attribute: attribute,
                    multiplier: 1.0,
                    constant: constant
                ))
                self.addConstraint(
                    addedConstraints.last!
                )
            }
            else if attribute == .centerX || attribute == .centerY {
                addedConstraints.append(NSLayoutConstraint(
                    item: view,
                    attribute: attribute,
                    relatedBy: .equal,
                    toItem: view.superview,
                    attribute: attribute,
                    multiplier: 1.0,
                    constant: constant
                ))
                self.addConstraint(
                    addedConstraints.last!
                )
            }
        }
        
        self.layoutIfNeeded()
        
        return addedConstraints
    }
}

extension UILabel {
    func setLineHeight(lineHeight: CGFloat) {
        if let _text = self.text {
            let attributeString = NSMutableAttributedString(string: _text)
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = lineHeight
            attributeString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, _text.count))
            self.attributedText = attributeString
        }
    }
}

