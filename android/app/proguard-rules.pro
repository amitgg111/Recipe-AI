# Keep generic type information required by Gson/TypeToken
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep flutter_local_notifications classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson TypeToken generic information
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.** { *; }

# Preserve fields/classes used by Gson
-keepattributes *Annotation*