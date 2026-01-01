
import 'native_keystore_platform_interface.dart';

class NativeKeystore {
  Future<String?> getPlatformVersion() {
    return NativeKeystorePlatform.instance.getPlatformVersion();
  }
}
