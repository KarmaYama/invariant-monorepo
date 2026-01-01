import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_keystore_platform_interface.dart';

/// An implementation of [NativeKeystorePlatform] that uses method channels.
class MethodChannelNativeKeystore extends NativeKeystorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_keystore');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
