import 'package:flutter_test/flutter_test.dart';
import 'package:native_keystore/native_keystore.dart';
import 'package:native_keystore/native_keystore_platform_interface.dart';
import 'package:native_keystore/native_keystore_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeKeystorePlatform
    with MockPlatformInterfaceMixin
    implements NativeKeystorePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeKeystorePlatform initialPlatform = NativeKeystorePlatform.instance;

  test('$MethodChannelNativeKeystore is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeKeystore>());
  });

  test('getPlatformVersion', () async {
    NativeKeystore nativeKeystorePlugin = NativeKeystore();
    MockNativeKeystorePlatform fakePlatform = MockNativeKeystorePlatform();
    NativeKeystorePlatform.instance = fakePlatform;

    expect(await nativeKeystorePlugin.getPlatformVersion(), '42');
  });
}
