package com.reelgrab.reelgrab

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val SCANNER_CHANNEL = "com.reelgrab.reelgrab/media_scanner"
    private val MUXER_CHANNEL = "com.reelgrab.reelgrab/video_muxer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(path),
                        arrayOf("video/mp4")
                    ) { _, _ -> }
                    result.success(true)
                } else {
                    result.error("INVALID_PATH", "Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MUXER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "mux") {
                val videoPath = call.argument<String>("videoPath")
                val audioPath = call.argument<String>("audioPath")
                val outputPath = call.argument<String>("outputPath")
                if (videoPath != null && audioPath != null && outputPath != null) {
                    Thread {
                        try {
                            val success = muxVideoAndAudio(videoPath, audioPath, outputPath)
                            runOnUiThread {
                                if (success) {
                                    result.success(true)
                                } else {
                                    result.error("MUX_FAILED", "MediaMuxer failed", null)
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("MUX_EXCEPTION", e.message, null)
                            }
                        }
                    }.start()
                } else {
                    result.error("INVALID_ARGS", "Missing arguments for mux", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun muxVideoAndAudio(videoPath: String, audioPath: String, outputPath: String): Boolean {
        var videoExtractor: MediaExtractor? = null
        var audioExtractor: MediaExtractor? = null
        var muxer: MediaMuxer? = null

        try {
            videoExtractor = MediaExtractor()
            videoExtractor.setDataSource(videoPath)

            audioExtractor = MediaExtractor()
            audioExtractor.setDataSource(audioPath)

            val outputFile = File(outputPath)
            if (outputFile.exists()) {
                outputFile.delete()
            }

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Select video track
            var videoTrackIndex = -1
            var videoSourceTrack = -1
            for (i in 0 until videoExtractor.trackCount) {
                val format = videoExtractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/")) {
                    videoSourceTrack = i
                    videoTrackIndex = muxer.addTrack(format)
                    break
                }
            }

            // Select audio track
            var audioTrackIndex = -1
            var audioSourceTrack = -1
            for (i in 0 until audioExtractor.trackCount) {
                val format = audioExtractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    audioSourceTrack = i
                    audioTrackIndex = muxer.addTrack(format)
                    break
                }
            }

            if (videoTrackIndex == -1) {
                return false
            }

            muxer.start()

            val buffer = ByteBuffer.allocate(1024 * 1024)
            val bufferInfo = MediaCodec.BufferInfo()

            // Copy video samples
            if (videoSourceTrack != -1) {
                videoExtractor.selectTrack(videoSourceTrack)
                while (true) {
                    val sampleSize = videoExtractor.readSampleData(buffer, 0)
                    if (sampleSize < 0) break

                    bufferInfo.offset = 0
                    bufferInfo.size = sampleSize
                    bufferInfo.presentationTimeUs = videoExtractor.sampleTime
                    bufferInfo.flags = videoExtractor.sampleFlags

                    muxer.writeSampleData(videoTrackIndex, buffer, bufferInfo)
                    videoExtractor.advance()
                }
            }

            // Copy audio samples
            if (audioTrackIndex != -1 && audioSourceTrack != -1) {
                audioExtractor.selectTrack(audioSourceTrack)
                while (true) {
                    val sampleSize = audioExtractor.readSampleData(buffer, 0)
                    if (sampleSize < 0) break

                    bufferInfo.offset = 0
                    bufferInfo.size = sampleSize
                    bufferInfo.presentationTimeUs = audioExtractor.sampleTime
                    bufferInfo.flags = audioExtractor.sampleFlags

                    muxer.writeSampleData(audioTrackIndex, buffer, bufferInfo)
                    audioExtractor.advance()
                }
            }

            muxer.stop()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        } finally {
            try { videoExtractor?.release() } catch (_: Exception) {}
            try { audioExtractor?.release() } catch (_: Exception) {}
            try { muxer?.release() } catch (_: Exception) {}
        }
    }
}
