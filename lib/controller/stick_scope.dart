import 'package:flutter/widgets.dart';

import 'stick_controller.dart';

class StickScope extends InheritedNotifier<StickController> {
  const StickScope({
    super.key,
    required StickController controller,
    required super.child,
  }) : super(notifier: controller);

  static StickController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StickScope>();
    assert(scope != null, 'No StickScope above this context');
    return scope!.notifier!;
  }
}
