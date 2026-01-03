## [0.1.0] - 2026-01-03

### Added
- **iOS Support**: Added full support for iOS background location tracking.
- Native Swift implementation.

## [0.0.2] - 2026-01-01

### Added
- **Dynamic Request Support**: Placeholder-based URL and body customization
  - Support for `%latitude%`, `%longitude%`, `%speed%`, `%accuracy%`, `%timestamp%` placeholders
  - Use placeholders in API URL for query parameter construction
  - Use placeholders in request body for custom JSON schemas
  - Recursive placeholder replacement supporting deeply nested JSON structures
- **Debug Mode**: Conditional logging control
- **Configurable Update Interval**: Control location update frequency

### Fixed
- Nested JSON placeholder replacement now works correctly with `coordinates: { lat: '%latitude%' }`
- Type safety issues with map casting in recursive functions
- Body validation allowing optional body for PUT/PATCH requests


## 0.0.1 

### Added
- Android foreground service for background location tracking
- Server-side transmission with configurable API
- Live location stream via EventChannel
- One-time current location fetch
- Service running state detection
- Android 14+ compliance

### Notes
- Initial public release
- Android only