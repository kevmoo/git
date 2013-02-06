part of hop;

abstract class TaskLogger {

  // level 500
  void fine(String message) {
    log(Level.FINE, message);
  }

  // level 800
  void info(String message) {
    log(Level.INFO, message);
  }

  // level 900
  void warning(String message) {
    log(Level.WARNING, message);
  }

  // level 1000
  void severe(String message) {
    log(Level.SEVERE, message);
  }

  void log(Level logLevel, String message);
}
