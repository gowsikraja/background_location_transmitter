import 'package:flutter_test/flutter_test.dart';
import 'package:background_location_transmitter/background_location_transmitter.dart';
import 'package:background_location_transmitter/background_location_transmitter_platform_interface.dart';
import 'package:background_location_transmitter/background_location_transmitter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBackgroundLocationTransmitterPlatform
    with MockPlatformInterfaceMixin
    implements BackgroundLocationTransmitterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BackgroundLocationTransmitterPlatform initialPlatform = BackgroundLocationTransmitterPlatform.instance;

  test('$MethodChannelBackgroundLocationTransmitter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBackgroundLocationTransmitter>());
  });

  test('getPlatformVersion', () async {
    BackgroundLocationTransmitter backgroundLocationTransmitterPlugin = BackgroundLocationTransmitter();
    MockBackgroundLocationTransmitterPlatform fakePlatform = MockBackgroundLocationTransmitterPlatform();
    BackgroundLocationTransmitterPlatform.instance = fakePlatform;

    expect(await backgroundLocationTransmitterPlugin.getPlatformVersion(), '42');
  });
}
