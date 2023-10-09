// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftyFlip
import Foundation

var wss = SwiftyFlip_WSS(connectionUrl: "wss://bsky.social/xrpc/com.atproto.sync.subscribeRepos")
print("Press any key to quit...")
_ = readLine()
