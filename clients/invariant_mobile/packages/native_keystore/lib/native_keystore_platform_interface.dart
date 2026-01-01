import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_keystore_method_channel.dart';

abstract class NativeKeystorePlatform extends PlatformInterface {
  /// Constructs a NativeKeystorePlatform.
  NativeKeystorePlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeKeystorePlatform _instance = MethodChannelNativeKeystore();

  /// The default instance of [NativeKeystorePlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeKeystore].
  static NativeKeystorePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeKeystorePlatform] when
  /// they register themselves.
  static set instance(NativeKeystorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
