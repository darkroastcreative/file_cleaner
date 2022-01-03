void deleteFiles(List message) {
  message[0].forEach((path) => path.delete(recursive: true));
}
