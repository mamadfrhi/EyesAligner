//
//  AppDelegate.swift
//  EyesAligner
//
//  Created by iMamad on 07.05.22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow()
        let mainVM = MainVM()
        window?.rootViewController = MainVC.`init`(mainVM: mainVM)
        
        return true
    }
}

