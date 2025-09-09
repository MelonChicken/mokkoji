/// Development tools configuration
/// Controls visibility of debug panels and tools
library;

/// Whether to enable development tools
/// Set to true only when explicitly requested via build flag
const bool kEnableDevTools = bool.fromEnvironment(
  'MOKKOJI_DEVTOOLS', 
  defaultValue: false,
);

/// Usage:
/// flutter run --dart-define=MOKKOJI_DEVTOOLS=true
/// 
/// By default, debug tools are completely hidden in all builds