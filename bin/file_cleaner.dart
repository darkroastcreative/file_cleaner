import 'dart:isolate';

import 'package:file_cleaner/file_cleaner.dart' as file_cleaner;
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) async {
  // Set up ArgParser for configuring and parsing command line arguments.
  ArgParser argParser = ArgParser();
  argParser.addOption('path', abbr: 'p', defaultsTo: null, mandatory: true);
  argParser.addOption('threadCount', abbr: 't', defaultsTo: null);

  // Get passed arguments.
  ArgResults passedArgs = argParser.parse(arguments);

  // Determine if a valid folder path was provided and process accordingly.
  if (passedArgs['path'] != null) {
    print('Targeted path: ${passedArgs["path"]}');

    // Determine the number of threads to use in the delete operation by default.
    print('Determining number of threads to use in delete operation.');
    int numThreads = (Platform.numberOfProcessors / 2).ceil();

    // Determine if the user provided a thread count and override default count if so.
    if (passedArgs['threadCount'] != null &&
        int.tryParse(passedArgs['threadCount']) != null) {
      numThreads = int.parse(
        passedArgs['threadCount'],
      );
    }

    print('file_cleaner will use $numThreads threads for delete operation.');

    // Define a List of FileSystemEntities to track file paths to be included in delete operation.
    print('Building list of file paths to delete.');
    List<FileSystemEntity> filePaths = [];

    try {
      // Populate paths List with detected file and directory paths in target directory.
      await Directory(passedArgs['path'])
          .list(recursive: true)
          .toList()
          .then((list) => filePaths = list.whereType<File>().toList());

      print(
          'File paths list built with ${filePaths.length} items. Proceeding to spawn threads to initiate delete operation.');

      /*
        If the number of threads was provided by the user or exceeds the number
        of files to delete, proceed with multithreaded delete. Otherwise, conduct
        a single-threaded delete.
      */
      if (passedArgs['threadCount'] != null || filePaths.length >= numThreads) {
        int pathsPerThread = (filePaths.length / numThreads).ceil();
        int startIndex = 0;
        int endIndex = 0 + pathsPerThread;

        for (int i = 0; i < numThreads; i++) {
          print(
              'Spawning thread to delete ${filePaths.sublist(startIndex, endIndex).length} files.');

          Isolate.spawn(file_cleaner.deleteFiles,
              [filePaths.sublist(startIndex, endIndex), filePaths]);

          startIndex = endIndex;
          endIndex = startIndex + pathsPerThread;

          if (endIndex > filePaths.length) {
            endIndex = filePaths.length;
          }
        }
      } else {
        print('Spawning thread to delete ${filePaths.length} files.');
        Isolate.spawn(file_cleaner.deleteFiles, [filePaths]);
      }

      /*
        This while loop is used to act as a "controller" to prevent the program
        from proceeding to delete the target path until all files have been deleted.
        This is necessary given how Islolates/"threads" are being used.
      */
      while (filePaths
          .where(
              (path) => path.existsSync() && !path.path.endsWith('.DS_Store'))
          .toList()
          .isNotEmpty) {}

      print('Files in targeted path have been deleted.');
      print('Proceeding to delete target path.');

      // Delete the target directory to complete the delete operation.
      Directory(passedArgs['path']).deleteSync(recursive: true);

      print('Targeted path deleted. Delete operation complete. ✅');
    } catch (exception) {
      print(exception);
      exit(1);
    }
  } else {
    print(
        'ERROR: No folder path provided. Please provide a valid folder path with the "-p" argument when running.');
  }
}
