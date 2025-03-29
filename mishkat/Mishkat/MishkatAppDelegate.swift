
//
//  MishkatAppDelegate.swift
//  Mishkat
//
//  Created by Human on 28/03/2025.
//

import SwiftUI
import UserNotifications

class MishkatAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    var app: MishkatApp?
    var currentDeviceToken: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications();
        
        UNUserNotificationCenter.current().delegate = self;
        
        return true;
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let stringifiedToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.currentDeviceToken = stringifiedToken
        
        if let app = self.app, app.authViewModel.isAuthenticated {
            Task {
                try? await DependencyContainer.shared.profileRepository.addDevice(deviceToken: stringifiedToken)
            }
        }
    }
}

extension MishkatAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("got notification title: ", response.notification.request.content.title);
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .list, .sound]
    }
}
