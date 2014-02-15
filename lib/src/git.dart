@deprecated
library git.git;

import 'dart:async';
import 'dart:io';
import 'top_level.dart' as tl;

/**
 * **DEPRECATED**.
 *
 * Use the top-level methods [isValidSha] and [runGit] instead.
 */
@deprecated
class Git {

  /**
   * **DEPRECATED**.
   *
   * Use the top-level method [tl.isValidSha].
   */
  static bool isValidSha(String value) => tl.isValidSha(value);

  /**
   * **DEPRECATED**.
   *
   * Use the top-level method [tl.runGit].
   */
  static Future<ProcessResult> runGit(List<String> args,
      {bool throwOnError: true, String processWorkingDir}) => tl.runGit(args, throwOnError: throwOnError, processWorkingDir: processWorkingDir);
}
