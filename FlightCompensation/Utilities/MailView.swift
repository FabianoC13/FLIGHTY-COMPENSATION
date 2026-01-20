import SwiftUI
import MessageUI

struct MailView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    let recipients: [String]
    let ccRecipients: [String]?
    let subject: String
    let messageBody: String
    let attachmentData: Data?
    let attachmentFileName: String
    
    init(result: Binding<Result<MFMailComposeResult, Error>?>, recipients: [String], ccRecipients: [String]? = nil, subject: String, messageBody: String, attachmentData: Data? = nil, attachmentFileName: String = "") {
        self._result = result
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.subject = subject
        self.messageBody = messageBody
        self.attachmentData = attachmentData
        self.attachmentFileName = attachmentFileName
    }
    
    var body: some View {
        if MFMailComposeViewController.canSendMail() {
            MailComposeWrapper(
                result: $result,
                recipients: recipients,
                ccRecipients: ccRecipients,
                subject: subject,
                messageBody: messageBody,
                attachmentData: attachmentData,
                attachmentFileName: attachmentFileName
            )
            .ignoresSafeArea()
        } else {
            // Fallback for Simulator OR Devices without Mail Setup
            MockMailView(
                result: $result,
                recipients: recipients,
                ccRecipients: ccRecipients,
                subject: subject,
                messageBody: messageBody,
                attachmentFileName: attachmentFileName
            )
        }
    }
}

// MARK: - Mock for Simulator
struct MockMailView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    let recipients: [String]
    let ccRecipients: [String]?
    let subject: String
    let messageBody: String
    let attachmentFileName: String
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    LabeledContent("To", value: recipients.joined(separator: ", "))
                    if let cc = ccRecipients, !cc.isEmpty {
                        LabeledContent("Cc", value: cc.joined(separator: ", "))
                    }
                    LabeledContent("Subject", value: subject)
                } header: {
                    Text("New Message (Simulator Mock)")
                }
                
                if !attachmentFileName.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "paperclip")
                                .foregroundStyle(.blue)
                            Text(attachmentFileName)
                        }
                    } header: {
                        Text("Attachments")
                    }
                }
                
                Section {
                    Text(messageBody)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Body")
                }
            }
            .navigationTitle("Compose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        result = .success(.cancelled)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        // Simulate sending delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            result = .success(.sent)
                            dismiss()
                        }
                    }
                    .font(.headline)
                }
            }
        }
    }
}

// MARK: - Real Implementation
struct MailComposeWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    let recipients: [String]
    let ccRecipients: [String]?
    let subject: String
    let messageBody: String
    let attachmentData: Data?
    let attachmentFileName: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        if let ccRecipients = ccRecipients {
            vc.setCcRecipients(ccRecipients)
        }
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        
        if let data = attachmentData {
            vc.addAttachmentData(data, mimeType: "application/pdf", fileName: attachmentFileName)
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeWrapper
        
        init(parent: MailComposeWrapper) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.dismiss()
        }
    }
}
