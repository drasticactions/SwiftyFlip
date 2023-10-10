// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftCBOR
import Dispatch

public class SwiftyFlip
{
    
}

public class SwiftyFlip_WSS
{
    private var webSocketTask: URLSessionWebSocketTask!
    private let backgroundQueue = DispatchQueue.global(qos: .background)
    private let carDecoder = CarDecoder()
    public init(connectionUrl: String)
    {
    let session = URLSession(configuration: .default)
    webSocketTask = session.webSocketTask(with: URL(string: connectionUrl)!)
    webSocketTask.resume()
    receiveMessages()
    }
    
    func receiveMessages() {
        webSocketTask.receive { result in
            switch result {
                case .success(let message):
                    switch message {
                        case .data(let data):
                            
                            self.backgroundQueue.async {
                                self.handleMessage(cborData: [UInt8](data)) // Continue to receive more messages
                            }
//                            let testing = carDecoder.decode(blocks)
                            self.receiveMessages() // Continue to receive more messages
                        case .string(let text):
                            // Handle received text message
                            print("Received message: \(text)")
                            self.receiveMessages() // Continue to receive more messages
                        @unknown default:
                            fatalError()
                    }
                case .failure(let error):
                    print("WebSocket receive error: \(error)")
            }
        }
    }
    
    func carDecodedHandler(event: CarProgressStatusEvent) {
        // print("CAR Decoded - CID: \(event.cid), Bytes Count: \(event.bytes.count)")
        do {
            let decoded = try! CBOR.decode([UInt8](event.bytes))!
            let item = decoded["$type"]
            switch item ?? "unknown"
            {
                case "app.bsky.feed.post":
                let message = try! SwiftCBOR.CodableCBORDecoder().decode(FeedPost.self, from: Data([UInt8](event.bytes)))
                break;
                case "\"app.bsky.graph.follow\"":
                let message = try! SwiftCBOR.CodableCBORDecoder().decode(GraphFollow.self, from: Data([UInt8](event.bytes)))
                break;
                case "\"app.bsky.feed.like\"":
                let message = try! SwiftCBOR.CodableCBORDecoder().decode(FeedLike.self, from: Data([UInt8](event.bytes)))
                break;
                case "\"app.bsky.graph.block\"":
                let message = try! SwiftCBOR.CodableCBORDecoder().decode(GraphBlock.self, from: Data([UInt8](event.bytes)))
                break;
                case "\"app.bsky.feed.repost\"":
                let message = try! SwiftCBOR.CodableCBORDecoder().decode(FeedRepost.self, from: Data([UInt8](event.bytes)))
                break;
                case "\"app.bsky.actor.profile\"":
                let message = try! SwiftCBOR.CodableCBORDecoder().decode(ActorProfile.self, from: Data([UInt8](event.bytes)))
                break;
                case "unknown":
                break;
                default:
                break;
            }
        }
        catch {
            
        }
    }
    
    struct Header : Codable
    {
    public let op: UInt64
    public let t: String
    }
    
    func handleMessage (cborData: [UInt8])
    {
    let decoder = CBORDecoder(stream: CBORDataInputStream(data: cborData))
    
    let objectHeader = try! decoder.decodeItem()
    let header = try! SwiftCBOR.CodableCBORDecoder().decode(Header.self, from: Data([UInt8](objectHeader.encode())))
    let object = try! decoder.decodeItem()
    switch header.t {
        case "#commit":
            print("commit")
            break;
        case "#handle":
            print("handle")
            break;
        case "#repoOp":
            print("repoOp")
            break;
        case "#info":
            print("info")
            break;
        case "#tombstone":
            print("tombstone")
            break;
        case "#migrate":
            print("migrate")
            break;
        default:
            print("unknown")
            break;
    }
    
    // print(object!.toString())
    
    
    let blocks = (object!["blocks"])
    switch blocks {
        case let .byteString(val):
            self.carDecoder.decodeCar(bytes: val, progress: self.carDecodedHandler)
            break;
        default:
            break;
    }
    }

}

class CBORDataInputStream : CBORInputStream
{
    private var data: [UInt8] // The source data containing bytes
    private var currentIndex: Int // The current index of the data being read
    
    init(data: [UInt8]) {
        self.data = data
        self.currentIndex = 0
    }
    
    public func isAtEnd() -> Bool {
        return currentIndex >= data.count
    }
    
    func popByte() throws -> UInt8 {
        guard currentIndex < data.count else {
            throw CBORInputStreamError.endOfStream
        }
        let byte = data[currentIndex]
        currentIndex += 1
        return byte
    }
    
    func popBytes(_ n: Int) throws -> ArraySlice<UInt8> {
        guard currentIndex + n <= data.count else {
            throw CBORInputStreamError.endOfStream
        }
        let bytes = data[currentIndex..<currentIndex + n]
        currentIndex += n
        return bytes
    }
}

enum CBORInputStreamError: Error {
    case endOfStream
}

struct FeedPost: Codable {
    let langs: [String]
    let type: String
    let text: String
    let reply: Reply?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case langs
        case type = "$type"
        case text
        case reply
        case createdAt
    }
}

struct Reply: Codable {
    let parent: Parent
    let root: Root
}

struct Parent: Codable {
    let cid: String
    let uri: String
}

struct Root: Codable {
    let uri: String
    let cid: String
}

struct GraphFollow: Codable {
    let subject: String
    let type: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case subject
        case type = "$type"
        case createdAt
    }
}

struct FeedLike: Codable {
    let subject: Subject
    let type: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case subject
        case type = "$type"
        case createdAt
    }
}

struct Subject: Codable {
    let cid: String
    let uri: String
}

struct GraphBlock: Codable {
    let createdAt: String
    let subject: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case createdAt
        case subject
        case type = "$type"
    }
}

struct FeedRepost: Codable {
    let type: String
    let createdAt: String
    let subject: Subject
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case createdAt
        case subject
    }
}

struct ActorProfile: Codable {
    let type: String
    let banner: Banner
    let avatar: Avatar
    let description: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case banner
        case avatar
        case description
        case displayName
    }
}

struct Banner: Codable {
    let type: String
    let size: Int
    let mimeType: String
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case size
        case mimeType
    }
}

struct Avatar: Codable {
    let mimeType: String
    let type: String
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case mimeType
        case type = "$type"
        case size
    }
}

struct Message : Codable
{
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
    }
}
