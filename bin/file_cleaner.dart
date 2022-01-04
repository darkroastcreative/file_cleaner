import 'dart:isolate';

import 'package:file_cleaner/file_cleaner.dart' as file_cleaner;
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) async {
  // Set up ArgParser for configuring and parsing command line arguments.
  ArgParser argParser = ArgParser();
  argParser.addOption('path', abbr: 'p', defaultsTo: null);

  // Get passed arguments.
  ArgResults passedArgs = argParser.parse(arguments);

  // Determine if a valid folder path was provided and process accordingly.
  if (passedArgs['path'] != null) {
    print('Targeted path: ${passedArgs["path"]}');

    // Determine number of threads to use during delete operation.
    print('Determining number of threads to use in delete operation.');
    int numThreads = (Platform.numberOfProcessors / 2).ceil();
    print('file_cleaner will use $numThreads threads for delete operation.');

    // Define a List of FileSystemEntities to track paths to be included in delete operation.
    print('Building list of paths to delete.');
    List<FileSystemEntity> paths = [];

    try {
      // Populate paths List with detected file and directory paths in target directory.
      await Directory(passedArgs['path'])
          .list(recursive: true)
          .toList()
          .then((list) => paths = list);

      // Sort List of paths alphabetically.
      paths.sort((a, b) => a.path.compareTo(b.path));

      print(
          'Paths list built. Proceeding to spawn threads to initiate delete operation.');

      if (paths.length >= numThreads) {
        int pathsPerThread = (paths.length / numThreads).ceil();
        int startIndex = 0;
        int endIndex = 0 + pathsPerThread;

        for (int i = 0; i < numThreads; i++) {
          print(
              'Spawning thread to delete ${paths.sublist(startIndex, endIndex).length} files.');

          Isolate.spawn(
              file_cleaner.deleteFiles, [paths.sublist(startIndex, endIndex)]);

          startIndex = endIndex;
          endIndex = startIndex + pathsPerThread;

          if (endIndex > paths.length) {
            endIndex = paths.length;
          }
        }
      } else {
        Isolate.spawn(file_cleaner.deleteFiles, [paths]);
      }

      // print('Files in targeted path have been deleted.');
      // print('Proceeding to delete target path.');

      // // Delete target directory.
      // Directory(passedArgs['path']).deleteSync(recursive: true);

      // print('Targeted path deleted. Delete operation complete.');
    } catch (exception) {
      print(exception);
    }
  } else {
    print(
        'ERROR: No folder path provided. Please provide a valid folder path with the "-p" argument when running.');
  }
}
