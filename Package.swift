// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "StockTradingApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "StockTradingApp",
            targets: ["StockTradingApp"]),
    ],
    dependencies: [
        // 可以在这里添加外部依赖
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
    ],
    targets: [
        .target(
            name: "StockTradingApp",
            dependencies: [
                // 在这里添加依赖
            ],
            path: "user_input_files",
            exclude: [
                "ios.zip",
                "StockTradingApp.xcodeproj"
            ]
        ),
        .testTarget(
            name: "StockTradingAppTests",
            dependencies: ["StockTradingApp"]),
    ]
)