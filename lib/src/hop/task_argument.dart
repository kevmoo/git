part of hop;

class TaskArgument {
  static final nameRegex = new RegExp(r'^[a-z](([a-z]|-)*[a-z])?$');

  final String name;
  final bool required;
  final bool multiple;

  TaskArgument(this.name, {this.required: false, this.multiple: false}) {
    requireArgumentNotNull(required, 'required');
    requireArgumentNotNull(multiple, 'multiple');
    requireArgumentMatches(nameRegex, name, 'name');
  }

  static void validateArgs(List<TaskArgument> args) {
    requireArgumentNotNull(args, 'args');

    bool finishRequired = false;
    for(var i = 0; i < args.length; i++) {
      final arg = args[i];
      final argName = 'args[$i]';
      requireArgumentNotNull(arg, argName);

      if(finishRequired && arg.required) {
        throw new DetailedArgumentError(argName, 'required arguments must all be at the beginning');
      }

      if(!arg.required) {
        finishRequired = true;
      }

      if(arg.multiple && i != (args.length - 1)) {
        throw new DetailedArgumentError(argName, 'only the last argument can be multiple');
      }

      for(final other in args.take(i)) {
        requireArgument(arg.name != other.name, argName, 'name ${arg.name} has already been defined');
      }
    }
  }
}
