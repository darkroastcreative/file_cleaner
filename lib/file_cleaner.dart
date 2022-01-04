void deleteFiles(List message) {
  message[0].forEach((path) =>
      path.exists().then((pathExists) => path.delete(recursive: true)));
}
