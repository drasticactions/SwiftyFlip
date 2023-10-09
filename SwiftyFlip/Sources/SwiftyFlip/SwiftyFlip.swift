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
                        // Handle received data
//                        self.backgroundQueue.async {
//                            self.handleMessage(data: data)
//                        }
                        let decoder = CBORDecoder(stream: CBORDataInputStream(data: [UInt8](data)))
                        let one = try! decoder.decodeItem()
                        let two = try! decoder.decodeItem()
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
