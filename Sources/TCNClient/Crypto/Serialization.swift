//
//  Created by Zsombor Szabo on 03/04/2020.
//  

import Foundation
import CryptoKit

protocol TCNSerializable {
    
    init(serializedData: Data) throws
    
    func serializedData() -> Data
    
}

extension Report: TCNSerializable {
    
    public static var minimumSerializedDataLength = 32 + 32 + 2 + 2 + 1 + 1
    
    public init(serializedData: Data) throws {
        guard serializedData.count >= Report.minimumSerializedDataLength else {
            throw CocoaError(.coderInvalidValue)
        }
        self.reportVerificationPublicKeyBytes = serializedData[0..<32]
        self.temporaryContactKeyBytes = serializedData[32..<64]
        self.startIndex = try UInt16(dataRepresentation: serializedData[64..<66])
        self.endIndex = try UInt16(dataRepresentation: serializedData[66..<68])
        self.memoType = try MemoType(dataRepresentation: serializedData[68..<69])
        self.memoData = serializedData[69..<serializedData.count]
        // Invariant: j_1 > 0
        guard self.startIndex > 0 else {
            throw TCNError.InvalidReportIndex
        }
    }
    
    public func serializedData() -> Data {
        return reportVerificationPublicKeyBytes +
            temporaryContactKeyBytes +
            startIndex.dataRepresentation +
            endIndex.dataRepresentation +
            memoType.dataRepresentation + memoData
    }
    
}

extension SignedReport: TCNSerializable {
    
    public init(serializedData: Data) throws {
        guard serializedData.count >= Report.minimumSerializedDataLength + 64 else {
            throw CocoaError(.coderInvalidValue)
        }
        self.report = try Report(
            serializedData: serializedData[0..<serializedData.count-64]
        )
        self.signatureBytes = serializedData[serializedData.count-64..<serializedData.count]
    }
    
    public func serializedData() -> Data {
        return report.serializedData() + signatureBytes
    }
}

extension TemporaryContactKey: TCNSerializable {
    
    public init(serializedData: Data) throws {
        guard serializedData.count == 2 + 32 + 32 else {
            throw CocoaError(.coderInvalidValue)
        }
        self.index = try UInt16(dataRepresentation: serializedData[0..<2])
        self.reportVerificationPublicKeyBytes = serializedData[2..<34]
        self.bytes = serializedData[34..<66]
    }
    
    public func serializedData() -> Data {
        return index.dataRepresentation + reportVerificationPublicKeyBytes + bytes
    }
    
}

extension ReportAuthorizationKey: TCNSerializable {
    
    public init(serializedData: Data) throws {
        guard serializedData.count == 32 else {
            throw CocoaError(.coderInvalidValue)
        }
        self.reportAuthorizationPrivateKey = try Curve25519.Signing.PrivateKey(
            rawRepresentation: serializedData
        )
    }
    
    public func serializedData() -> Data {
        return reportAuthorizationPrivateKey.rawRepresentation
    }
    
}
