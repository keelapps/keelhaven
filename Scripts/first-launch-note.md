Drag **Keelhaven** to Applications. This beta isn't notarized by Apple yet, so macOS asks you to allow it once on first launch:

- **macOS 15 (Sequoia):** double-click the app, dismiss the warning, then open **System Settings › Privacy & Security**, scroll down, and click **Open Anyway**.
- **macOS 14 (Sonoma):** right-click the app in Applications and choose **Open**, then **Open** again.
- **Terminal instead:** `xattr -d com.apple.quarantine /Applications/Keelhaven.app`

More detail: https://keelhaven.app/#faq
