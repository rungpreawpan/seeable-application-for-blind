# Keep TensorFlow Lite classes
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# Suppress warnings about missing classes
-dontwarn org.tensorflow.**
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**
