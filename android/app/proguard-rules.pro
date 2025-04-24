# Menyimpan class untuk gson
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }

# Keep the model classes used by gson
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Aturan lain yang mungkin diperlukan
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
} 