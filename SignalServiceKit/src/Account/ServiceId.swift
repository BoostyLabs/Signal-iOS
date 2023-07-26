//
// Copyright 2023 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import LibSignalClient
import GRDB

public struct UntypedServiceId: Equatable, Hashable, Codable, CustomDebugStringConvertible {
    private enum Constant {
        static let myStory = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        static let systemStory = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }

    public static var myStory: UntypedServiceId { UntypedServiceId(Constant.myStory) }
    public static var systemStory: UntypedServiceId { UntypedServiceId(Constant.myStory) }

    public let uuidValue: UUID

    public init(_ uuidValue: UUID) {
        self.uuidValue = uuidValue
    }

    public init?(uuidString: String?) {
        guard let uuidString, let uuidValue = UUID(uuidString: uuidString) else {
            return nil
        }
        self.init(uuidValue)
    }

    public static func expectNilOrValid(uuidString: String?) -> UntypedServiceId? {
        let result = UntypedServiceId(uuidString: uuidString)
        owsAssertDebug(uuidString == nil || result != nil, "Couldn't parse a ServiceId that should be valid")
        return result
    }

    public enum KnownValue {
        case myStory
        case systemStory
        case other(UUID)
    }

    public var knownValue: KnownValue {
        switch uuidValue {
        case Constant.myStory:
            return .myStory
        case Constant.systemStory:
            return .systemStory
        default:
            return .other(uuidValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var singleValueContainer = encoder.singleValueContainer()
        try singleValueContainer.encode(uuidValue)
    }

    public init(from decoder: Decoder) throws {
        self.uuidValue = try decoder.singleValueContainer().decode(UUID.self)
    }

    public var debugDescription: String { "<ServiceId \(uuidValue.uuidString)>" }
}

@objc
public class UntypedServiceIdObjC: NSObject, NSCopying {
    public let wrappedValue: UntypedServiceId

    public init(_ wrappedValue: UntypedServiceId) {
        self.wrappedValue = wrappedValue
    }

    @objc
    public init(uuidValue: UUID) {
        self.wrappedValue = UntypedServiceId(uuidValue)
    }

    @objc
    public init?(uuidString: String?) {
        guard let uuidString, let wrappedValue = UntypedServiceId(uuidString: uuidString) else {
            return nil
        }
        self.wrappedValue = wrappedValue
    }

    @objc
    public var uuidValue: UUID { wrappedValue.uuidValue }

    @objc
    public override var hash: Int { uuidValue.hashValue }

    @objc
    public override func isEqual(_ object: Any?) -> Bool { uuidValue == (object as? UntypedServiceIdObjC)?.uuidValue }

    @objc
    public func copy(with zone: NSZone? = nil) -> Any { self }

    @objc
    public override var description: String { wrappedValue.debugDescription }
}

// MARK: - DatabaseValueConvertible

extension UntypedServiceId: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { uuidValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UntypedServiceId? {
        UUID.fromDatabaseValue(dbValue).map { UntypedServiceId($0) }
    }
}

public typealias FutureAci = UntypedServiceId
public typealias FuturePni = UntypedServiceId

#if TESTABLE_BUILD

extension UntypedServiceId {
    public static func randomForTesting() -> UntypedServiceId {
        return UntypedServiceId(UUID())
    }

    public static func constantForTesting(_ serviceIdString: String) -> UntypedServiceId {
        return UntypedServiceId((try! ServiceId.parseFrom(serviceIdString: serviceIdString)).rawUUID)
    }
}

extension Aci {
    public static func randomForTesting() -> Aci {
        Aci(fromUUID: UUID())
    }

    public static func constantForTesting(_ uuidString: String) -> Aci {
        try! ServiceId.parseFrom(serviceIdString: uuidString) as! Aci
     }
 }

extension Pni {
    public static func randomForTesting() -> Pni {
        Pni(fromUUID: UUID())
    }

    public static func constantForTesting(_ serviceIdString: String) -> Pni {
        try! ServiceId.parseFrom(serviceIdString: serviceIdString) as! Pni
    }
}

#endif
