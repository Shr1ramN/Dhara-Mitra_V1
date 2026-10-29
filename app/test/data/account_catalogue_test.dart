import 'dart:io';

import 'package:dhara_mitra/core/farm_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('account-farms-'),
  );
  tearDown(() async => root.delete(recursive: true));

  test('existing local farms survive account creation and switching', () async {
    final local = FarmProfiles(root);
    final second = await local.add();
    await local.select(second);
    final before = await local.read();
    final ownerA = FarmProfiles(
      root,
      ownerId: '11111111-1111-1111-1111-111111111111',
    );
    final ownerB = FarmProfiles(
      root,
      ownerId: '22222222-2222-2222-2222-222222222222',
    );
    final a = await ownerA.read();
    final b = await ownerB.read();
    expect(a.ids, hasLength(1));
    expect(a.ids, isNot(contains('default')));
    expect(a.ids.toSet().intersection(b.ids.toSet()), isEmpty);
    expect(a.ids.toSet().intersection(before.ids.toSet()), isEmpty);
    await ownerA.add();
    expect((await local.read()).ids, before.ids);
    expect((await local.read()).active, before.active);
    expect((await ownerB.read()).ids, b.ids);
    final reopened = FarmProfiles(root, ownerId: ownerA.ownerId);
    expect((await reopened.read()).ids, (await ownerA.read()).ids);
  });

  test(
    'account catalogue rejects invalid identities before filesystem access',
    () {
      for (final id in ['../local', 'default', '', 'bad']) {
        expect(() => FarmProfiles(root, ownerId: id), throwsArgumentError);
      }
    },
  );
}
