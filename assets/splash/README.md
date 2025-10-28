This folder stores the source images for native splash screens used by flutter_native_splash.

Expected files:
- splash_logo.png (recommended 512x512)
- splash_logo_dark.png (optional, used for dark mode; can be same as splash_logo.png if logo has sufficient contrast)
- splash_logo_android12.png (recommended 960x960 for Android 12 animated icon)
- splash_logo_android12_dark.png (optional dark mode variant)

The generator will create platform-specific resources under android and ios.