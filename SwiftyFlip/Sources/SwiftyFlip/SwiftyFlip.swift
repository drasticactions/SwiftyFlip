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
                            let decoder = CBORDecoder(stream: CBORDataInputStream(data: [UInt8](data)))
                            let objectHeader = try! decoder.decodeItem()
                            let object = try! decoder.decodeItem()
                            //print(objectHeader!.toString())
                            //print(object!.toString())
                            let blocks = (object!["blocks"])
                            switch blocks {
                                case let .byteString(val):
                                    self.carDecoder.decodeCar(bytes: val, progress: self.carDecodedHandler)
                                    break;
                                default:
                                    break;
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
        let decoded = try! CBOR.decode(event.bytes)
        let type = decoded!["$type"]
        switch type?.toString() ?? ""
        {
            case "\"app.bsky.feed.post\"":
            print(decoded!.toString())
            break;
            default:
            break;
        }
        //print(type?.toString() ?? "")
    }
    
    func handleMessage (cborData: [UInt8])
    {
    // let decoder = try! SwiftCBOR.CBORDecoder.init(input: [UInt8](data))
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
