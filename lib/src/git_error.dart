library git.git_error;

class GitError extends Error {
  final String message;

  GitError(this.message);

  String toString() => message;
}
