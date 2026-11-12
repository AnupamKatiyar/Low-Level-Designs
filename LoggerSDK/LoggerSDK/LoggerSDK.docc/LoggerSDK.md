# LoggerSDK

A Swift logging framework with pluggable destinations, local persistence, and remote upload support.

## Usage

### Development (console only)

```swift
import LoggerSDK

Logger.shared.configure(.development())
Logger.shared.debug("Cache hit", category: "Storage")
Logger.shared.error("Request failed", metadata: ["code": "500"])
```

### Production (console + file + remote upload)

```swift
import LoggerSDK

let config = try LoggerConfiguration.production(
    remoteEndpoint: URL(string: "https://api.example.com/logs")!,
    apiKey: "your-key"
)
Logger.shared.configure(config)
Logger.shared.setUserID("user-123")

// On app background
await Logger.shared.flush()
```

## Run tests

From the command line:

```bash
xcodebuild -scheme LoggerSDK -destination 'platform=macOS' test
```

Or press **Cmd+U** in Xcode.
