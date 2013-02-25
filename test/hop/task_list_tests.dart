part of test_hop;

class TaskListTests {
  static run() {
    test('dupe names are bad', () {
      final tasks = new HopConfig();
      tasks.addSync('task', (ctx) => true);

      expect(() => tasks.addSync('task', (ctx) => true), throwsArgumentError);
    });

    test('reject bad task names', () {
      final tasks = new HopConfig();
      final goodNames = const['a','aa','a_','a1','a_b','a_cool_test1_'];

      for(final n in goodNames) {
        tasks.addSync(n, (ctx) => true);
      }

      final badNames = const['', null, ' start white', '1 start num', '\rtest',
                             'end_white ', 'contains white', 'contains\$bad',
                             'test\r\test', 'UpperCase', 'camelCase'];

      for(final n in badNames) {
        expect(() => tasks.addSync(n, (ctx) => true), throwsArgumentError);
      }
    });

    test('reject tasks after freeze', () {
      final tasks = new HopConfig();

      expect(tasks.isFrozen, isFalse);
      tasks.freeze();
      expect(tasks.isFrozen, isTrue);

      // cannot re-freeze
      expect(() => tasks.freeze(), throws);

      // cannot add task when frozen
      expect(() => tasks.addSync('task', (ctx) => true), throws);
    });
  }
}
