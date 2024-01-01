// swift-tools-version:5.9
//
//  Copyright (c) 2016-2020 Anton Mironov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom
//  the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "AsyncNinja",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    .executable(name: "ImportingTestExecutable", targets: [
      "ImportingTestExecutable"
    ]),
    .library(name: "AsyncNinja", targets: [
      "AsyncNinja",
      "AsyncNinjaReactiveUI"
    ]),
    .library(
        name: "NinjaMacros",
        targets: ["NinjaMacros"]
    ),
  ],
  dependencies: [
      .package(url: "https://gitlab.com/sergiy.vynnychenko/essentials.git", branch: "master" ),
      .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
  ],
  targets: [
    .macro(
        name: "NinjaMacros",
        dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]
    ),
    .target(
      name: "AsyncNinja",
      dependencies: [
          .product(name: "Essentials", package: "essentials")
      ],
      path: "Sources/AsyncNinja"
    ),
    .testTarget(
      name: "AsyncNinjaTests",
      dependencies: ["AsyncNinja"],
      path: "Tests/AsyncNinja"
    ),
    .testTarget(
      name: "AsyncNinjaMacrosTests",
      dependencies: ["AsyncNinja", "NinjaMacros", .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),],
      path: "Tests/NinjaMacros"
    ),

    .target(
      name: "AsyncNinjaReactiveUI",
      dependencies: ["AsyncNinja"],
      path: "Sources/AsyncNinjaReactiveUI"
    ),
    .testTarget(
      name: "AsyncNinjaReactiveUITests",
      dependencies: ["AsyncNinjaReactiveUI"],
      path: "Tests/AsyncNinjaReactiveUI"
    ),

    .target(
      name: "ImportingTestExecutable",
      dependencies: ["AsyncNinja", "AsyncNinjaReactiveUI"],
      path: "Sources/ImportingTestExecutable"
    )
  ],
  swiftLanguageVersions: [.v5]
)
