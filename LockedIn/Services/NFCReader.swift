//
//  NFCReader.swift
//  LockedIn
//
//  Created by Assistant on 8/24/25.
//

import Foundation
import CoreNFC

@available(iOS 16.0, *)
final class NFCReader: NSObject, NFCNDEFReaderSessionDelegate {
    static let shared = NFCReader()

    private var session: NFCNDEFReaderSession?
    private var completion: ((Result<UUID, Error>) -> Void)?

    enum ReaderError: LocalizedError {
        case nfcUnavailable
        case noNDEFMessage
        case invalidPayload
        case invalidURL
        case invalidProfileIdentifier

        var errorDescription: String? {
            switch self {
            case .nfcUnavailable: return "NFC is not available on this device."
            case .noNDEFMessage: return "No NDEF message found on the tag."
            case .invalidPayload: return "Unrecognized NDEF payload."
            case .invalidURL: return "Could not parse URL from tag."
            case .invalidProfileIdentifier: return "Profile identifier not found on tag."
            }
        }
    }

    func beginRead(completion: @escaping (Result<UUID, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(ReaderError.nfcUnavailable))
            return
        }
        self.completion = completion
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the NFC tag to read the profile."
        session?.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.session = nil
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first, let record = message.records.first else {
            complete(.failure(ReaderError.noNDEFMessage), session: session)
            return
        }

        if let url = decodeURI(from: record) {
            handle(url: url, session: session)
        } else {
            complete(.failure(ReaderError.invalidPayload), session: session)
        }
    }

    // MARK: - Helpers

    private func handle(url: URL, session: NFCNDEFReaderSession) {
        guard url.scheme == "lockedin" else {
            complete(.failure(ReaderError.invalidURL), session: session)
            return
        }

        // Expecting lockedin://profile/<uuid>
        if url.host == "profile" {
            let uuidString = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if let uuid = UUID(uuidString: uuidString) {
                complete(.success(uuid), session: session)
                return
            }
        }

        complete(.failure(ReaderError.invalidProfileIdentifier), session: session)
    }

    private func complete(_ result: Result<UUID, Error>, session: NFCNDEFReaderSession) {
        DispatchQueue.main.async { [weak self] in
            self?.completion?(result)
            self?.completion = nil
            session.invalidate()
            self?.session = nil
        }
    }

    // Decode a URI record (TNF Well Known, Type 'U') according to NFC Forum RTD URI
    private func decodeURI(from record: NFCNDEFPayload) -> URL? {
        guard record.typeNameFormat == .nfcWellKnown, record.type.count == 1, record.type.first == 0x55 else {
            return nil
        }
        guard let payload = record.payload as Data?, payload.count >= 1 else { return nil }
        let prefixCode = payload[payload.startIndex]
        let remainderData = payload.dropFirst()
        let prefix = uriPrefix(for: prefixCode)
        guard let remainder = String(data: remainderData, encoding: .utf8) else { return nil }
        let urlString = prefix + remainder
        return URL(string: urlString)
    }

    private func uriPrefix(for code: UInt8) -> String {
        switch code {
        case 0x00: return ""
        case 0x01: return "http://www."
        case 0x02: return "https://www."
        case 0x03: return "http://"
        case 0x04: return "https://"
        case 0x05: return "tel:"
        case 0x06: return "mailto:"
        default: return "" // For custom schemes like lockedin://, builder likely used 0x00
        }
    }
}


