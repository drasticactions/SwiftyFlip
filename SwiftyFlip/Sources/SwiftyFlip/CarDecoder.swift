//
//  CarDecoder.swift
//
//
//  Created by ミラー・ティモシー on 2023/10/09.
//

import Foundation

// CarProgressStatusEvent class
public class CarProgressStatusEvent {
    public let cid: Cid
    public let bytes: [UInt8]
    
    public init(cid: Cid, bytes: [UInt8]) {
        self.cid = cid
        self.bytes = bytes
    }
}

public class Cid {
    public let bytes: [UInt8]
    
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
}

// OnCarDecoded typealias
public typealias OnCarDecoded = (CarProgressStatusEvent) -> Void

// CarDecoder class
public class CarDecoder {
    private let CidV1BytesLength = 36
    private let BufferSize = 32768
    
    // Decode CAR Byte Array
    public func decodeCar(bytes: [UInt8], progress: OnCarDecoded? = nil) {
        let bytesLength = bytes.count
        let header = decodeReader(bytes: bytes)
        var start = header.length + header.value
        
        while start < bytesLength {
            let body = decodeReader(bytes: Array(bytes[start...]))
            if body.value == 0 {
                break
            }
            
            start += body.length
            
            let cidBytes = Array(bytes[start..<(start + CidV1BytesLength)])
            let cid = Cid(bytes: cidBytes)
            
            start += CidV1BytesLength
            let bs = Array(bytes[start..<(start + body.value - CidV1BytesLength)])
            start += body.value - CidV1BytesLength
            progress?(CarProgressStatusEvent(cid: cid, bytes: bs))
        }
    }

    private func scanStream(stream: InputStream, length: Int) throws {
        var receiveBuffer = [UInt8](repeating: 0, count: length)
        stream.read(&receiveBuffer, maxLength: length)
    }
    
    private func decodeReader(bytes: [UInt8]) -> DecodedBlock {
        var a = [UInt8]()
        
        var i = 0
        while true {
            let b = bytes[i]
//            if b == -1 {
//                return DecodedBlock(value: -1, length: -1)
//            }
            
            i += 1
            a.append(b)
            if (b & 0x80) == 0 {
                break
            }
        }
        
        return DecodedBlock(value: decode(a: a), length: a.count)
    }
    
    private func decodeReader(stream: InputStream) -> DecodedBlock {
        var a = [UInt8]()
        
        var i = 0
        while true {
            var b: UInt8 = 0
            stream.read(&b, maxLength: 1)
//            if b == -1 {
//                return DecodedBlock(value: -1, length: -1)
//            }
            
            i += 1
            a.append(UInt8(b))
            if (UInt8(b) & 0x80) == 0 {
                break
            }
        }
        
        return DecodedBlock(value: decode(a: a), length: a.count)
    }
    
    private func decode(a: [UInt8]) -> Int {
        var r = 0
        for i in 0..<a.count {
            let e = a[i]
            r = r + Int((Int(e) & 0x7F) << (i * 7))
        }
        
        return r
    }
    
    private struct DecodedBlock {
        let value: Int
        let length: Int
    }
}
