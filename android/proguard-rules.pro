# Flutter Fortress ProGuard/R8 Rules
-keep class com.example.flutter_fortress.** { *; }
-keepclassmembers class com.example.flutter_fortress.** { *; }
-keepnames class com.example.flutter_fortress.StringObfuscator { *; }
-keepclassmembers class * {
    native <methods>;
}
-dontwarn javax.annotation.**
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keepclassmembers class com.google.android.play.core.** { *; }
