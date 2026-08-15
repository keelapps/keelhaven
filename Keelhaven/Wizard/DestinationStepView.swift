import SwiftUI

struct DestinationStepView: View {
    @Bindable var model: WizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where should the encrypted backup go?")
                .font(.title3)

            Picker("Destination type", selection: $model.destinationType) {
                ForEach(DestinationType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            destinationForm

            Toggle("Connect to an existing repository at this destination", isOn: $model.adoptExistingRepository)
                .toggleStyle(.checkbox)
            Text("For a repository created earlier — by another plan, a previous install, or another Mac. Your password is verified against it; no new repository is created.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !model.adoptExistingRepository {
                if model.localDestinationHasRepository && !model.destinationAlreadyUsed {
                    Text("This folder already contains a backup repository. Connect to it with the checkbox above, or choose an empty folder.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if model.destinationAlreadyUsed {
                    Text("Another plan already backs up to this destination. Connect to its repository with the checkbox above, or pick a different folder or bucket path.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Encryption password")
                    .font(.headline)
                if model.adoptExistingRepository {
                    Text("Enter the password of the existing repository. It is checked when you click Next.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Existing repository password", text: $model.password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: model.password) { _, _ in
                            model.passwordVerificationError = nil
                        }
                    if let verificationError = model.passwordVerificationError {
                        Text(verificationError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(3)
                            .help(verificationError)
                    }
                } else {
                    newPasswordFields
                }
            }
        }
    }

    @ViewBuilder
    private var newPasswordFields: some View {
        Group {
                Text("Backups are encrypted before leaving your Mac. This password is stored in your Keychain — without it, backups cannot be restored.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if model.passwordWasGenerated {
                    HStack {
                        Text(model.password)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                        Button("Copy") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(model.password, forType: .string)
                        }
                    }
                    Text("Write this down or store it in a password manager now — without it, your backups cannot be restored.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    SecureField("Password (at least 8 characters)", text: $model.password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Confirm password", text: $model.passwordConfirm)
                        .textFieldStyle(.roundedBorder)
                }
                Button(model.passwordWasGenerated ? "Type My Own Instead" : "Generate Strong Password") {
                    if model.passwordWasGenerated {
                        model.password = ""
                        model.passwordConfirm = ""
                        model.passwordWasGenerated = false
                    } else {
                        model.generatePassword()
                    }
                }
                if !model.password.isEmpty && !model.passwordValid {
                    Text(model.password.count < 8
                         ? "Password must be at least 8 characters."
                         : "Passwords don't match.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }

    @ViewBuilder
    private var destinationForm: some View {
        switch model.destinationType {
        case .local:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Destination folder", text: $model.localPath, prompt: Text("/Volumes/BackupDrive/Keelhaven"))
                        .textFieldStyle(.roundedBorder)
                    Button("Choose…") {
                        if let url = FolderPicker.pickFolder() {
                            model.localPath = url.path
                        }
                    }
                }
                if model.localDestinationInsideSource {
                    Text("The destination can't be inside a folder you're backing up.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        case .s3:
            Form {
                TextField("Endpoint", text: $model.s3Endpoint, prompt: Text("s3.amazonaws.com"))
                TextField("Bucket", text: $model.s3Bucket)
                TextField("Path prefix (optional)", text: $model.s3Prefix)
                TextField("Access key ID", text: $model.s3AccessKey)
                SecureField("Secret access key", text: $model.s3SecretKey)
            }
            .formStyle(.columns)
            .textFieldStyle(.roundedBorder)
        case .sftp:
            Form {
                TextField("User", text: $model.sftpUser)
                TextField("Host", text: $model.sftpHost, prompt: Text("nas.local"))
                TextField("Port", text: $model.sftpPort)
                TextField("Path on server", text: $model.sftpPath, prompt: Text("/backups/mac"))
            }
            .formStyle(.columns)
            .textFieldStyle(.roundedBorder)
            Text("Uses your existing SSH keys (~/.ssh) or ssh-agent for authentication.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
