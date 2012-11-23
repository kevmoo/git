part of test_hop;

class TaskListTests {
  static run() {
    test('dupe names are bad', () {
      final tasks = new Tasks();
      tasks.addTask('task', (ctx) => true);

      expect(() => tasks.addTask('task', (ctx) => true), throwsArgumentError);
    });

    test('reject bad task names', () {
      final tasks = new Tasks();
      final goodNames = const['a','aa','a_','a1','a_b','a_cool_test1_'];

      for(final n in goodNames) {
        tasks.addTask(n, (ctx) => true);
      }

      final badNames = const['', null, ' start white', '1 start num', '\rtest',
                             'end_white ', 'contains white', 'contains\$bad',
                             'test\r\test', 'UpperCase', 'camelCase'];

      for(final n in badNames) {
        expect(() => tasks.addTask(n, (ctx) => true), throwsArgumentError);
      }
    });

    test('reject tasks after freeze', () {
      final tasks = new Tasks();

      expect(tasks.isFrozen, isFalse);
      tasks.freeze();
      expect(tasks.isFrozen, isTrue);

      // cannot re-freeze
      expect(() => tasks.freeze(), throws);

      // cannot add task when frozen
      expect(() => tasks.addTask('task', (ctx) => true), throws);
    });
  }
}
