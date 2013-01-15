part of hop;

class BaseConfig {
  static final RegExp _validNameRegExp = new RegExp(r'^[a-z][a-z0-9_]*$');
  static const _reservedTasks = const[Runner.RAW_TASK_LIST_CMD];
  final Map<String, Task> _tasks = new Map();
  ReadOnlyCollection<String> _sortedTaskNames;

  BaseConfig();

  /// Can only be accessed when frozen
  /// Always sorted
  List<String> get taskNames {
    requireFrozen();
    return _sortedTaskNames;
  }

  bool hasTask(String taskName) {
    requireFrozen();
    return _tasks.containsKey(taskName);
  }

  Task _getTask(String taskName) {
    return _tasks[taskName];
  }

  void addSync(String name, Func1<TaskContext, bool> func) {
    addTask(name, new Task.sync(func));
  }

  void addAsync(String name, TaskDefinition execFuture) {
    addTask(name, new Task.async(execFuture));
  }

  void addTask(String name, Task task) {
    require(!isFrozen, "Cannot add a task. Frozen.");
    requireArgumentNotNullOrEmpty(name, 'name');
    requireArgument(_validNameRegExp.hasMatch(name), 'name',
        '"$name" is not a valid name');
    requireArgument(!_reservedTasks.contains(name), 'task',
        'The provided task has a reserved name');
    requireArgument(!_tasks.containsKey(name), 'task',
        'A task with name ${name} already exists');

    requireArgumentNotNull(task, 'task');
    _tasks[name] = task;
  }

  void requireFrozen() {
    if(!isFrozen) {
      throw "not frozen!";
    }
  }

  void freeze() {
    require(!isFrozen, "Already frozen.");
    final list = new List<String>.from(_tasks.keys);
    list.sort();
    _sortedTaskNames = new ReadOnlyCollection<String>.wrap(list);
  }

  bool get isFrozen => _sortedTaskNames != null;
}
