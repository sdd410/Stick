/// How to stop the phone's battery saver from killing reminders. Null for
/// brands that do not need it.
String? batteryTipFor(String manufacturer) {
  final m = manufacturer.toLowerCase();
  bool any(List<String> names) => names.any(m.contains);
  if (any(['xiaomi', 'redmi', 'poco'])) {
    return 'Settings → Apps → Stick → Battery saver → No restrictions, '
        'and turn on Autostart.';
  }
  if (any(['samsung'])) {
    return 'Settings → Apps → Stick → Battery → Unrestricted.';
  }
  if (any(['oppo', 'realme'])) {
    return 'Settings → Battery → Stick → Allow background activity.';
  }
  if (any(['vivo'])) {
    return 'Settings → Battery → Background power → allow Stick.';
  }
  return null;
}
