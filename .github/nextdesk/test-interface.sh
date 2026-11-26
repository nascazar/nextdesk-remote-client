#!/usr/bin/env bash
set -euo pipefail
# Isolate the real presentation widget from the native FFI engine for fast UI tests.
repo="$PWD"
test_dir="$(mktemp -d)"
mkdir -p "$test_dir/lib/desktop/widgets" "$test_dir/assets" "$test_dir/test"
cp flutter/lib/desktop/widgets/nextdesk_home_panel.dart "$test_dir/lib/desktop/widgets/"
cp flutter/test/nextdesk_home_panel_test.dart "$test_dir/test/"
cp flutter/assets/nextdesk-wordmark-white.svg flutter/assets/Manrope-Regular.ttf flutter/assets/Manrope-Semibold.ttf flutter/assets/Manrope-Bold.ttf "$test_dir/assets/"
cat > "$test_dir/pubspec.yaml" <<'YAML'
name: nextdesk_remote_interface
environment:
  sdk: '>=3.1.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: 2.0.10+1
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
  assets:
    - assets/
  fonts:
    - family: Manrope
      fonts:
        - asset: assets/Manrope-Regular.ttf
          weight: 400
        - asset: assets/Manrope-Semibold.ttf
          weight: 600
        - asset: assets/Manrope-Bold.ttf
          weight: 700
YAML
cd "$test_dir"
flutter pub get
flutter analyze lib/desktop/widgets/nextdesk_home_panel.dart
flutter test test/nextdesk_home_panel_test.dart
mkdir -p "$repo/artifacts/interface"
cp test-output/*.png "$repo/artifacts/interface/"
