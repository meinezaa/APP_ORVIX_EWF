package com.example.app_pt_ewf

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "pivot_point_downloader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImageToGallery") {
                    val imagePath = call.argument<String>("path") ?: run {
                        result.error("INVALID_PATH", "Path gambar tidak valid", null)
                        return@setMethodCallHandler
                    }

                    val imageFile = File(imagePath)
                    if (!imageFile.exists()) {
                        result.error("FILE_NOT_FOUND", "File gambar tidak ditemukan", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val resolver = applicationContext.contentResolver
                        val imageName = "pivot_point_${System.currentTimeMillis()}.png"
                        val contentValues = ContentValues().apply {
                            put(MediaStore.MediaColumns.DISPLAY_NAME, imageName)
                            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/Orvix")
                                put(MediaStore.MediaColumns.IS_PENDING, 1)
                            }
                        }

                        val uri = resolver.insert(
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            contentValues,
                        )

                        if (uri == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        resolver.openOutputStream(uri)?.use { outputStream ->
                            imageFile.inputStream().use { inputStream ->
                                inputStream.copyTo(outputStream)
                            }
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            contentValues.clear();
                            contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                            resolver.update(uri, contentValues, null, null)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
