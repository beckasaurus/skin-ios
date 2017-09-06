//
//  AppDelegate.swift
//  skin
//
//  Created by Becky Henderson on 8/28/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let realmConnected = NSNotification.Name(rawValue: "realmConnected")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

	var window: UIWindow?
	public var realm: Realm?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		(window?.rootViewController as? UISplitViewController)?.delegate = self
		
		setupRealm()
		
		return true
	}
	
	func setupRealm() {
		guard let jsonURL = Bundle.main.url(forResource: "credentials", withExtension: "json")
			else {fatalError("Bundle must include credentials.json file contain Realm credentials")}
		
		do {
			let jsonData = try Data(contentsOf: jsonURL)
			
			let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments)
			
			if let jsonDict = jsonObject as? [String:String] {
				let username = jsonDict["username"]!
				let password = jsonDict["password"]!
				
				loginToRealm(username: username, password: password)
			}
		} catch let error  {
			fatalError(error.localizedDescription)
		}
	}
	
	func loginToRealm(username: String, password: String) {
		guard let serverURL = URL(string: "http://127.0.0.1:9080")
			else { return }
		
		let credentials = SyncCredentials.usernamePassword(username: username, password: password, register: false)
		
		SyncUser.logIn(with: credentials, server: serverURL) { user, error in
			guard let user = user else {
				fatalError(String(describing: error))
			}
			
			DispatchQueue.main.async {
				// Open Realm
				let configuration = Realm.Configuration(
					syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://127.0.0.1:9080/~/skin")!)
				)
				self.realm = try! Realm(configuration: configuration)
				
				NotificationCenter.default.post(name: realmConnected, object: nil)
			}
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController,
	                         collapseSecondary secondaryViewController: UIViewController,
	                         onto primaryViewController: UIViewController) -> Bool {
		if let navigationController = secondaryViewController as? UINavigationController,
			let secondaryController = navigationController.topViewController,
		let castedSecondaryController = secondaryController as? RoutineTableViewController,
		castedSecondaryController.routine == nil {
			return true
		} else {
			return false
		}
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

