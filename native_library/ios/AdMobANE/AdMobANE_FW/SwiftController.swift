/* Copyright 2017 Tua Rua Ltd.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.*/

import Foundation
import CoreImage
import GoogleMobileAds

public class SwiftController: NSObject, FreSwiftMainController {
    public var context: FreContextSwift!
    public var functionsToSet: FREFunctionMap = [:]
    private var bannerController: BannerController? = nil
    private var interstitialController: InterstitialController? = nil
    private var deviceArray: Array<String> = Array()

    // Must have this function. It exposes the methods to our entry ObjC.
    @objc public func getFunctions(prefix: String) -> Array<String> {


        functionsToSet["\(prefix)isSupported"] = isSupported
        functionsToSet["\(prefix)init"] = initController
        functionsToSet["\(prefix)loadBanner"] = loadBanner
        functionsToSet["\(prefix)clearBanner"] = clearBanner
        functionsToSet["\(prefix)loadInterstitial"] = loadInterstitial
        functionsToSet["\(prefix)showInterstitial"] = showInterstitial
        functionsToSet["\(prefix)getBannerSizes"] = getBannerSizes
        functionsToSet["\(prefix)setTestDevices"] = setTestDevices

        var arr: Array<String> = []
        for key in functionsToSet.keys {
            arr.append(key)
        }
        return arr
    }

    func isSupported(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        do {
            return try FreObjectSwift(bool: true).rawValue
        } catch {
        }
        return nil
    }

    func initController(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        guard argc > 2,
              let inFRE0 = argv[0],
              let inFRE1 = argv[1],
              let inFRE2 = argv[2],
              let key: String = FreObjectSwift(freObject: inFRE0).value as? String
          else {
            return FreError(stackTrace: "",
              message: "initAdMob - incorrect arguments",
              type: FreError.Code.invalidArgument).getError(#file, #line, #column)
        }

        var volume: Double = 1.0
        if let volInt = FreObjectSwift.init(freObject: inFRE1).value as? Int {
            volume = Double(volInt)
        } else if let volDbl = FreObjectSwift.init(freObject: inFRE1).value as? Double {
            volume = volDbl
        }

        let muted = FreObjectSwift(freObject: inFRE2).value as! Bool

        // Sample AdMob app ID: ca-app-pub-3940256099942544~1458002511
        GADMobileAds.configure(withApplicationID: key)
        GADMobileAds.sharedInstance().applicationVolume = Float(volume)
        GADMobileAds.sharedInstance().applicationMuted = muted

        bannerController = BannerController.init(context: context)
        interstitialController = InterstitialController.init(context: context)
        return nil
    }

    func loadBanner(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        guard argc > 6,
              let inFRE2 = argv[2], //targeting
              let inFRE3 = argv[3],
              let inFRE4 = argv[4],
              let unitId: String = FreObjectSwift(freObject: argv[0]).value as? String,
              let adSize: Int = FreObjectSwift(freObject: argv[1]).value as? Int,
              let hAlign: String = FreObjectSwift(freObject: argv[5]).value as? String,
              let vAlign: String = FreObjectSwift(freObject: argv[6]).value as? String
          else {
            return FreError(stackTrace: "",
              message: "loadBanner - incorrect arguments",
              type: FreError.Code.invalidArgument).getError(#file, #line, #column)
        }

        var x: CGFloat = 1.0
        if let xInt = FreObjectSwift.init(freObject: inFRE3).value as? Int {
            x = CGFloat.init(xInt)
        } else if let xDbl = FreObjectSwift.init(freObject: inFRE3).value as? Double {
            x = CGFloat.init(xDbl)
        }

        var y: CGFloat = 1.0
        if let yInt = FreObjectSwift.init(freObject: inFRE4).value as? Int {
            y = CGFloat.init(yInt)
        } else if let yDbl = FreObjectSwift.init(freObject: inFRE4).value as? Double {
            y = CGFloat.init(yDbl)
        }

        let targeting = Targeting.init(freObjectSwift: FreObjectSwift.init(freObject: inFRE2))


        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController,
           let avc = bannerController {
            avc.load(airView: rootViewController.view, unitId: unitId, size: adSize, deviceList: deviceArray,
              targeting: targeting, x: x, y: y, hAlign: hAlign, vAlign: vAlign)

        }

        return nil
    }

    func clearBanner(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        guard let bc = bannerController else {
            trace("clearBanner early return")
            return nil
        }
        trace("calling bannerController.clear")
        bc.clear()
        return nil
    }

    func loadInterstitial(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        guard argc > 2,
              let unitId: String = FreObjectSwift(freObject: argv[0]).value as? String,
              let inFRE1 = argv[1],
              let inFRE2 = argv[2]
          else {
            return FreError(stackTrace: "",
              message: "loadInterstitial - incorrect arguments",
              type: FreError.Code.invalidArgument).getError(#file, #line, #column)
        }

        let showOnLoad = FreObjectSwift(freObject: inFRE2).value as! Bool
        let targeting = Targeting.init(freObjectSwift: FreObjectSwift.init(freObject: inFRE1))

        trace("unitId: \(unitId)")
        trace("targetting: \(targeting)")
        trace("showOnLoad: \(showOnLoad)")

        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController,
            let ivc = interstitialController {
            //unitId, deviceList, targeting, showOnLoad
            ivc.load(airVC: rootViewController, unitId: unitId, deviceList: deviceArray, targeting: targeting, showOnLoad: showOnLoad)
        }
        
        return nil
    }

    func showInterstitial(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        if let ivc = interstitialController {
            ivc.show()
        }
    
        return nil
    }

    func getBannerSizes(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        guard let bc = bannerController else {
            return nil
        }
        do {
            let arr: FreArraySwift = try FreArraySwift.init(intArray: bc.getBannerSizes())
            return arr.rawValue
        } catch {
        }
        return nil
    }

    func setTestDevices(ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        guard argc > 0,
              let inFRE0 = argv[0]
          else {
            return FreError(stackTrace: "",
              message: "setTestDevices - incorrect arguments",
              type: FreError.Code.invalidArgument).getError(#file, #line, #column)
        }
        let deviceArrayAny: Array<Any?> = FreArraySwift.init(freObject: inFRE0).value
        for device in deviceArrayAny {
            deviceArray.append(device as! String)
        }
        return nil
    }


    // Must have this function. It exposes the methods to our entry ObjC.
    @objc public func callSwiftFunction(name: String, ctx: FREContext, argc: FREArgc, argv: FREArgv) -> FREObject? {
        if let fm = functionsToSet[name] {
            return fm(ctx, argc, argv)
        }
        return nil
    }

    @objc public func setFREContext(ctx: FREContext) {
        self.context = FreContextSwift.init(freContext: ctx)
    }


}
