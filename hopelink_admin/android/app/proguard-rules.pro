# Stripe SDK - Keep push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }

# Stripe SDK - General keep rules
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }

# Stripe SDK - Keep specific classes
-keepnames class com.stripe.android.pushProvisioning.PushProvisioningActivity
-keepnames class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-keepnames class com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Keep all inner classes of push provisioning
-keepclassmembers class com.stripe.android.pushProvisioning.* { *; }
-keepclassmembers class com.reactnativestripesdk.pushprovisioning.* { *; }
