import 'dart:io';

void deleteFile(FileSystemEntity path) {
  path.exists().then((exists) => {
        if (exists) {path.delete()}
      });
}

void deleteFiles(List message) {
  message[0].forEach((path) => deleteFile(path));
}
