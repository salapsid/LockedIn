//
//  NFCWriter.swift
//  LockedIn
//
//  Created by Assistant on 8/23/25.
//

import Foundation
import CoreNFC

@available(iOS 16.0, *)
final class NFCWriter: NSObject, NFCNDEFReaderSessionDelegate {
    static let shared = NFCWriter()

    private var session: NFCNDEFReaderSession?
    private var messageToWrite: NFCNDEFMessage?

    func beginWrite(profile: Profile) {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC not available on this device.")
            return
        }

        guard let uri = URL(string: "lockedin://profile/\(profile.id.uuidString)") else {
            print("Failed to build profile URL")
            return
        }

        let uriRecord = NFCNDEFPayload.wellKnownTypeURIPayload(url: uri)!
        let nameRecord = NFCNDEFPayload.wellKnownTypeTextPayload(string: profile.name, locale: Locale.current)!
        messageToWrite = NFCNDEFMessage(records: [uriRecord, nameRecord])

        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the NFC tag to write the profile."
        session?.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Session ended or failed
        self.session = nil
        self.messageToWrite = nil
        if (error as NSError).code != NFCReaderError.readerSessionInvalidationErrorFirstNDEFTagRead.rawValue {
            print("NFC session invalidated: \(error.localizedDescription)")
        }
    }

    // Required by protocol (used for read flows). Not used in our write flow.
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // No-op for write-only sessions
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first, let message = messageToWrite else {
            session.alertMessage = "No tag or message. Please try again."
            session.invalidate()
            return
        }

        session.connect(to: tag) { [weak self] error in
            if let error = error {
                session.alertMessage = "Connection failed: \(error.localizedDescription)"
                session.invalidate()
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.alertMessage = "NDEF status error: \(error.localizedDescription)"
                    session.invalidate()
                    return
                }

                switch status {
                case .readOnly:
                    session.alertMessage = "Tag is read-only."
                    session.invalidate()
                case .notSupported:
                    session.alertMessage = "Tag not NDEF compatible."
                    session.invalidate()
                case .readWrite:
                    let length = message.length
                    if capacity < length {
                        session.alertMessage = "Tag capacity (\(capacity)) insufficient for message (\(length))."
                        session.invalidate()
                        return
                    }
                    tag.writeNDEF(message) { writeError in
                        if let writeError = writeError {
                            session.alertMessage = "Write failed: \(writeError.localizedDescription)"
                            session.invalidate()
                            return
                        }
                        session.alertMessage = "Profile written successfully."
                        session.invalidate()
                        self?.messageToWrite = nil
                    }
                @unknown default:
                    session.alertMessage = "Unknown tag status."
                    session.invalidate()
                }
            }
        }
    }
}


