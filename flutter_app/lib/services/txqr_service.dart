import 'package:flutter/services.dart';

/// Dart-side wrapper around the Go TXQR encoder/decoder exposed via MethodChannel.
/// Note: Channel names and native bindings remain as "txqr" to maintain compatibility
/// with the underlying Go backend (TXQR library).
class TxqrService {
  static const _decoderChannel = MethodChannel('com.divan.txqr/decoder');
  static const _encoderChannel = MethodChannel('com.divan.txqr/encoder');

  // ============ DECODER METHODS ============

  /// Feed a single QR frame string to the Go decoder.
  /// Returns null on success, or an error message string.
  Future<String?> decode(String data) async {
    final result = await _decoderChannel.invokeMethod<String>('decode', data);
    return result;
  }

  /// Whether the decoder has collected enough frames to reconstruct the data.
  Future<bool> isCompleted() async {
    final result = await _decoderChannel.invokeMethod<bool>('isCompleted');
    return result ?? false;
  }

  /// The fully decoded payload as a string (only valid after [isCompleted] returns true).
  Future<String> getData() async {
    final result = await _decoderChannel.invokeMethod<String>('getData');
    return result ?? '';
  }

  /// The fully decoded payload as bytes (only valid after [isCompleted] returns true).
  Future<Uint8List> getDataBytes() async {
    final result = await _decoderChannel.invokeMethod<Uint8List>('getDataBytes');
    return result ?? Uint8List(0);
  }

  /// Current decoding progress as a percentage (0-100).
  Future<int> getProgress() async {
    final result = await _decoderChannel.invokeMethod<int>('getProgress');
    return result ?? 0;
  }

  /// Human-readable average read speed, e.g. "12.3 KB/s".
  Future<String> getSpeed() async {
    final result = await _decoderChannel.invokeMethod<String>('getSpeed');
    return result ?? '';
  }

  /// Human-readable total scan time, e.g. "3.2s".
  Future<String> getTotalTime() async {
    final result = await _decoderChannel.invokeMethod<String>('getTotalTime');
    return result ?? '';
  }

  /// Reset the decoder for a new scanning session.
  Future<void> resetDecoder() async {
    await _decoderChannel.invokeMethod<void>('reset');
  }

  // ============ ENCODER METHODS ============

  /// Encode the given data string into fountain-coded chunks.
  /// After calling this, use [chunkCount] and [getChunk] to retrieve frames.
  Future<void> encode(String data) async {
    await _encoderChannel.invokeMethod<void>('encode', data);
  }

  /// Returns the number of encoded chunks.
  Future<int> chunkCount() async {
    final result = await _encoderChannel.invokeMethod<int>('chunkCount');
    return result ?? 0;
  }

  /// Returns the chunk at the given index.
  Future<String> getChunk(int index) async {
    final result = await _encoderChannel.invokeMethod<String>('getChunk', index);
    return result ?? '';
  }

  /// Set the chunk length for encoding. Creates a new encoder instance.
  /// Recommended values: 100-500 for reliable scanning.
  Future<void> setChunkLength(int chunkLen) async {
    await _encoderChannel.invokeMethod<void>('setChunkLength', chunkLen);
  }

  /// Set the redundancy factor for encoding.
  /// Higher values produce more chunks (more reliable but slower).
  /// Default is 2.0.
  Future<void> setRedundancyFactor(double rf) async {
    await _encoderChannel.invokeMethod<void>('setRedundancyFactor', rf);
  }
}
