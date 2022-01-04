void deleteFiles(List message) {
  message[0].forEach((path) => path.exists().then(
      (pathExists) => pathExists ? path.delete(recursive: true) : print('')));
}
