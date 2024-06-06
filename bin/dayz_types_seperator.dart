// Dart Imports
import 'dart:io';

// Package Imports
import 'package:args/args.dart';
import 'package:xml/xml.dart';

const String version = '0.0.1';

void main(List<String> arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);

    // Process the parsed arguments.
    if (results.wasParsed('help')) {
      printUsage(argParser);
      return;
    }

    if (results.wasParsed('path')) {
      var path = results['path'] as String;
      splitTypes(path);
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )

    // TODO add option for output directory
    // TODO add option for output file name
    // TODO add option for filtering by element type example: <category ..
    // TODO add option for filter by element attribute example: <category name="weapon"..
    // TODO add option for filter by element value example: <cost>100</cost>
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Absolute path to the types.xml file.',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: dart dayz_types_seperator.dart <flags> [arguments]');
  print(argParser.usage);
}

void splitTypes(String path) {
  // parse an xml file
  var typesFile = File(path);

  if (typesFile.existsSync()) {
    var xml = typesFile.readAsStringSync();
    var document = XmlDocument.parse(xml);
    var root = document.rootElement;
    var allTypes = root.findAllElements('type');
    var categoryToType = <String, List<XmlElement>>{};

    for (var type in allTypes) {
      var category = type.findElements('category').firstOrNull;
      if (category == null) {
        continue;
      }

      var categoryName = category.getAttribute('name');
      if (categoryName == null || categoryName.isEmpty) {
        categoryName = 'unknown';
      }

      if (categoryToType.containsKey(categoryName)) {
        categoryToType[categoryName]?.add(type);
      } else {
        categoryToType[categoryName] = [type];
      }
    }

    for (var category in categoryToType.keys) {
      var categoryTypes = categoryToType[category]!;
      // create new xml document with root element types
      var newDocument = XmlDocument();

      var xmlVersion = XmlProcessing(
          'xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
      newDocument.children.add(xmlVersion);

      var root = XmlElement(XmlName('types'));
      newDocument.children.add(root);

      for (var type in categoryTypes) {
        root.children.add(type.copy());
      }

      // add all categoryTypes to the new xml document
      var newXml = newDocument.toXmlString(pretty: true);

      File('${typesFile.parent.path}/$category.xml').writeAsStringSync(newXml);
    }
  }
}
