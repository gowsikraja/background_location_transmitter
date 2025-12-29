
import 'background_location_transmitter_platform_interface.dart';

class BackgroundLocationTransmitter {
  Future<String?> getPlatformVersion() {
    return BackgroundLocationTransmitterPlatform.instance.getPlatformVersion();
  }
}
