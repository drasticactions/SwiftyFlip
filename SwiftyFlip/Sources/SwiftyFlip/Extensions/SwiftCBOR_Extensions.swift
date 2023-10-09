//
//  SwiftCBOR_Extensions.swift
//
//
//  Created by ミラー・ティモシー on 2023/10/09.
//

import Foundation
import SwiftCBOR

extension SwiftCBOR.CBOR {
  
    public func sanitize(value: String) -> String {
      return value.replacingOccurrences(of: "\"", with: "\\\"")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func toString() -> String {
        switch self {
        case let .byteString(val):
            let fallBack = "[" + val.map { "\($0)" }.joined(separator: ", ") + "]"
            return fallBack
        case let .unsignedInt(val):
            return "\(val)"
        case let .negativeInt(val):
            return "-\(val + 1)"
        case let .utf8String(val):
            return "\"\(sanitize(value: val))\""
        case let .array(vals):
            var str = ""
            for val in vals {
              str += (str.isEmpty ? "" : ", ") + val.toString()
            }
            return "[\(str)]"
        case let .map(vals):
            var str = ""
            for pair in vals {
                let val = pair.value
                if case .undefined = val {
                  continue
                }
                let key = "\"\(pair.key.toString().trimmingCharacters(in: ["\""]))\""
                str += (str.isEmpty ? "" : ", ") + "\(key): \(val.toString())"
            }
            return "{\(str)}"
        case let .boolean(val):
            return String(describing: val)
        case .null, .undefined:
            return "null"
        case let .float(val):
            return "\(val)"
        case let .double(val):
            return "\(val)"
        default:
            return "\"unsupported data\""
        }
    }
}
