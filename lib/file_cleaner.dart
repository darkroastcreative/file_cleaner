import 'dart:io';

import 'dart:isolate';

bool deleteFile(FileSystemEntity path) {
  if (path.existsSync()) {
    path.deleteSync(recursive: true);

    return !path.existsSync();
  }

  return true;
}

void deleteFiles(List message) {
  message[0].forEach((path) => deleteFile(path));
}

void prepareIsolate(
    Isolate thread, List<Isolate> threads, ReceivePort receivePort) {
  Capability pauseCapability = thread.pause();
  thread.addOnExitListener(receivePort.sendPort, response: thread.hashCode);
  threads.add(thread);
  thread.resume(pauseCapability);
}
