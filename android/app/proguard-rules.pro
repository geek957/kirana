# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Encryption libraries - Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# Encryption libraries - Encrypt package
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }

# Don't obfuscate security-critical classes
-keepnames class * extends java.security.Provider
-keepclassmembers class * extends java.security.Provider {
    <init>(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core (for Flutter dynamic feature modules)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
