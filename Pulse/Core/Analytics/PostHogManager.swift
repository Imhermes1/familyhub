import Foundation

/// PostHog analytics manager
/// TODO: Install PostHog SDK via SPM: https://github.com/PostHog/posthog-ios
class PostHogManager {
    static let shared = PostHogManager()

    private var apiKey: String?
    private var isEnabled = true

    private init() {}

    func initialize() {
        // Load API key from plist
        guard let config = PostHogConfig.load() else {
            print("Warning: PostHog configuration not found")
            return
        }

        self.apiKey = config.apiKey

        // TODO: Initialize PostHog SDK
        // let configuration = PHGPostHogConfiguration(apiKey: apiKey, host: "https://app.posthog.com")
        // PHGPostHog.setup(with: configuration)
    }

    func identify(userId: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }

        // TODO: Implement
        // PHGPostHog.shared()?.identify(userId, properties: properties)
        print("PostHog identify: \(userId)")
    }

    func track(_ event: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }

        // TODO: Implement
        // PHGPostHog.shared()?.capture(event, properties: properties)
        print("PostHog track: \(event) \(properties)")
    }

    func track(_ event: AnalyticsEvent, properties extra: [String: Any] = [:]) {
        var merged = event.properties
        extra.forEach { merged[$0.key] = $0.value }
        track(event.name, properties: merged)
    }

    func screen(_ screenName: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }

        // TODO: Implement
        // PHGPostHog.shared()?.screen(screenName, properties: properties)
        print("PostHog screen: \(screenName)")
    }

    func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled

        // TODO: Persist preference
        UserDefaults.standard.set(enabled, forKey: "posthog_enabled")
    }
}

// MARK: - Configuration

struct PostHogConfig {
    let apiKey: String

    static func load() -> PostHogConfig? {
        guard let path = Bundle.main.path(forResource: "PostHog", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String],
              let apiKey = dict["POSTHOG_API_KEY"] else {
            return nil
        }

        return PostHogConfig(apiKey: apiKey)
    }
}
