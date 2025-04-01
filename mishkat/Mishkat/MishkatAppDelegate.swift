//
//  MishkatAppDelegate.swift
//  Mishkat
//
//  Created by Human on 28/03/2025.
//

import SwiftUI
import UserNotifications

@MainActor
class MishkatAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    var currentDeviceToken: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        askForNotificationsPermission()
        application.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().delegate = self;
        
        return true;
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let stringifiedToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Received device token: \(stringifiedToken)")
        self.currentDeviceToken = stringifiedToken

        if KeychainManager.shared.getToken() != nil {
            print("User authenticated (checked via Keychain), attempting to register potentially updated token.")
            Task {
                do {
                   try await DependencyContainer.shared.profileRepository.addDevice(deviceToken: stringifiedToken)
                   print("Successfully registered updated device token while authenticated.")
                } catch {
                    print("Failed to register updated device token while authenticated: \(error)")
                }
            }
        } else {
             print("User not authenticated when token received, registration will happen after login.")
        }
    }

    private func askForNotificationsPermission() {
        let notifCenter = UNUserNotificationCenter.current()
        notifCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
                return
            }
            if granted {
                print("Notification permission granted.")
                DispatchQueue.main.async {
                   UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied.")
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
