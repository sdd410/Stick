import 'package:device_info_plus/device_info_plus.dart';

/// The phone maker, or '' when it cannot be read. Never throws.
Future<String> readDeviceManufacturer() async {
  try {
    return (await DeviceInfoPlugin().androidInfo).manufacturer;
  } catch (_) {
    return '';
  }
}
