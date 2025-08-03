#-keepattributes *Annotation*
#-dontwarn com.razorpay.**
#-keep class com.razorpay.** {*;}
#-optimizations !method/inlining/
#-keepclasseswithmembers class * {
#  public void onPayment*(...);
#}
# Keep all annotations
# ==== Razorpay ProGuard Rules ====

# Keep all Razorpay classes
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }

# Keep Razorpay payment callbacks
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Disable method inlining (optional but recommended for some payment callbacks)
-optimizations !method/inlining/

# Keep annotations
-keepattributes *Annotation*

# ==== Fix R8 Missing Annotations ====

# Ignore missing annotation classes that are only referenced by Razorpay but not present
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Optional: Prevent warnings for any unknown annotations (extra safe)
-dontwarn **.annotation.**

# ==== Stripe ProGuard Rules ====

# Stripe Payment Sheet warnings suppression
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
