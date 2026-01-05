import Foundation

class PluginLogger {
    static func logPermission(_ message: String) {
        if TrackingConfig.debug {
            print("🛡️ [BLT_PERMISSION] \(message)")
        }
    }

    static func logAction(_ message: String) {
        if TrackingConfig.debug {
            print("⚡ [BLT_ACTION] \(message)")
        }
    }

    static func logService(_ message: String) {
        if TrackingConfig.debug {
            print("⚙️ [BLT_SERVICE] \(message)")
        }
    }

    static func logError(_ message: String) {
        if TrackingConfig.debug {
            print("❌ [BLT_ERROR] \(message)")
        }
    }
}
