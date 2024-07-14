// Dart Imports
import "dart:io";

// Package Imports
import "package:args/args.dart";
import "package:xml/xml.dart";

import "types_map.dart";

const String version = "0.0.1";

void main(List<String> arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);

    // Process the parsed arguments.
    if (results.wasParsed("help")) {
      printUsage(argParser);
      return;
    }

    if (results.wasParsed("path")) {
      var path = results["path"] as String;
      // extractTypeNames(path);
      splitTypes(path);
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print("");
    printUsage(argParser);
  }
}

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      "help",
      abbr: "h",
      negatable: false,
      help: "Print this usage information.",
    )

    // TODO add option for output directory
    // TODO add option for output file name
    // TODO add option for filtering by element type example: <category ..
    // TODO add option for filter by element attribute example: <category name="weapon"..
    // TODO add option for filter by element value example: <cost>100</cost>
    ..addOption(
      "path",
      abbr: "p",
      help: "Absolute path to the types.xml file.",
    );
}

void printUsage(ArgParser argParser) {
  print("Usage: dart dayz_types_seperator.dart <flags> [arguments]");
  print(argParser.usage);
}

void splitTypes(String path) {
  // parse an xml file
  var typesFile = File(path);

  if (typesFile.existsSync()) {
    var xml = typesFile.readAsStringSync();
    var document = XmlDocument.parse(xml);
    var root = document.rootElement;
    var allTypes = root.findAllElements("type");
    var sortedTypes = <String, List<XmlElement>>{};

    for (var type in allTypes) {
      var typeName = type.getAttribute("name");
      var category = typesCategories[typeName];
      if (category != null) {
        if (sortedTypes.containsKey(category)) {
          sortedTypes[category]!.add(type);
        } else {
          sortedTypes[category] = [type];
        }
      } else {
        if (sortedTypes.containsKey("missed")) {
          sortedTypes["missed"]!.add(type);
        } else {
          sortedTypes["missed"] = [type];
        }
        print("------------- MISSED type: $typeName ---------------");
      }
    }

    for (var category in sortedTypes.keys) {
      var categoryTypes = sortedTypes[category]!;

      var newDocument = XmlDocument();
      var xmlVersion = XmlProcessing(
          "xml", "version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"");
      newDocument.children.add(xmlVersion);

      var root = XmlElement(XmlName("types"));
      newDocument.children.add(root);

      for (var type in categoryTypes) {
        root.children.add(type.copy());
      }

      // add all categoryTypes to the new xml document
      var newXml = newDocument.toXmlString(pretty: true);

      if (!File("${typesFile.parent.path}/splilt_types/)").existsSync()) {
        Directory("${typesFile.parent.path}/splilt_types/").createSync();
      }

      File("${typesFile.parent.path}/splilt_types/$category.xml")
          .writeAsStringSync(newXml);
    }
  }
}

// void extractTypeNames(String path) {
//   var typesFile = File(path);

//   if (typesFile.existsSync()) {
//     var xml = typesFile.readAsStringSync();
//     var document = XmlDocument.parse(xml);
//     var root = document.rootElement;
//     var allTypes = root.findAllElements("type");
//     var categoryToType = <String, List<XmlElement>>{};
//     var typeNames = <String, String>{};

//     for (var type in allTypes) {
//       var name = type.getAttribute("name");
//       var category = type.findElements("category").firstOrNull;
//       if (name != null && name.isNotEmpty) {
//         typeNames[name] = category?.getAttribute("name") ?? "landnames";
//       }
//     }

//     for (var type in typeNames.keys) {
//       var category = typeNames[type];

//       var newXml = newDocument.toXmlString(pretty: true);
//       File("${typesFile.parent.path}/split_types/$category.xml")
//           .writeAsStringSync(newXml);
//     }
//   }
// }
