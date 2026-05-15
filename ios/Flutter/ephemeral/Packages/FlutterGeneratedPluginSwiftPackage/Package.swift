// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios"),
        .package(name: "rive_native", path: "../.packages/rive_native"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus"),
        .package(name: "google_sign_in_ios", path: "../.packages/google_sign_in_ios"),
        .package(name: "flutter_email_sender", path: "../.packages/flutter_email_sender"),
        .package(name: "firebase_core", path: "../.packages/firebase_core"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth"),
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "integration-test", package: "integration_test"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "rive-native", package: "rive_native"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "google-sign-in-ios", package: "google_sign_in_ios"),
                .product(name: "flutter-email-sender", package: "flutter_email_sender"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "device-info-plus", package: "device_info_plus")
            ]
        )
    ]
)
