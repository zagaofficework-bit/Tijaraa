# -------------------------------------------------------------------------
# 1. FLUTTER CORE (Essential for startup)
# -------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# -------------------------------------------------------------------------
# 2. FIREBASE & GOOGLE PLAY SERVICES
# -------------------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth & Google Sign-In specific (Prevents Login Hangs)
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keepattributes *Annotation*, Signature, EnclosingMethod, InnerClasses

# Firestore & gRPC (Prevents "Hang" due to missing networking classes)
-keep class io.grpc.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-dontwarn io.grpc.**

# -------------------------------------------------------------------------
# 3. STRIPE PAYMENT SDK (Updated for 2025)
# -------------------------------------------------------------------------
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.** { *; }
-keep class com.stripe.** { *; }
-keep class com.stripe.android.databinding.** { *; }

# -------------------------------------------------------------------------
# 4. GOOGLE MAPS
# -------------------------------------------------------------------------
-keep class com.google.android.libraries.maps.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# -------------------------------------------------------------------------
# 5. ANDROID 15 (API 35) COMPATIBILITY
# -------------------------------------------------------------------------
-keep class com.google.android.gms.clearcut.** { *; }
-keep class com.google.android.gms.phenotype.** { *; }
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# -------------------------------------------------------------------------
# 6. DATA MODELS (Crucial for JSON parsing)
# -------------------------------------------------------------------------
# This prevents your data classes from being renamed, which breaks JSON decoding
-keep class com.tijaraa.app.models.** { *; }

# Prevent R8 from removing Enum values (Fixes many common crashes)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn androidx.work.CoroutineWorker
-dontwarn androidx.work.DirectExecutor

# WebRTC (Very heavy, keep this to prevent crashes)
-keep class org.webrtc.** { *; }

# Remove logging from release builds to save space
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
# -------------------------------------------------------------------------
# 7. RAZORPAY PAYMENT SDK (CRITICAL – FIXES R8 CRASH)
# -------------------------------------------------------------------------
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Razorpay uses reflection internally
-keepclassmembers class com.razorpay.** {
    *;
}
