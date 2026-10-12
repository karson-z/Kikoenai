import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/enums/device_type.dart';

void main() {
  test('phone landscape stays mobile while a tablet uses its current width', () {
    expect(
      DeviceType.fromSize(const Size(844, 390)),
      DeviceType.mobile,
    );
    expect(
      DeviceType.fromSize(const Size(390, 844)),
      DeviceType.mobile,
    );
    expect(
      DeviceType.fromSize(const Size(1024, 768)),
      DeviceType.laptop,
    );
    expect(
      DeviceType.fromSize(const Size(768, 1024)),
      DeviceType.tablet,
    );
    expect(
      DeviceType.fromSize(const Size(1440, 900)),
      DeviceType.desktop,
    );
  });
}
