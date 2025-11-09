# Config

Environment-specific configuration values can be defined here.

## Files

- `dependencies.dart`: Contains dependency injection configuration
- `environment_config.dart`: Contains platform-specific configuration like base URLs
  - Handles different base URLs for Windows (localhost) and Android emulator (10.0.2.2)