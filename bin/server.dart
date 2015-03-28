// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

import 'package:http/http.dart' as http_client;
import 'package:xml/xml.dart';
import 'dart:collection';
//import 'package:quiver/core.dart';

class Item {
  String city;
  DateTime date;
  double value;
  String pollutant;
  String concentration;

  Item(this.city, this.date, this.value, this.pollutant, this.concentration);
}

class Location {
  String name;
  Map<String, Pollutant> pollutants = {};

  Location(this.name);

  toString() => '<Location>$name';

  bool operator ==(o) => o is Location && name == o.name;

  int get hashCode => name.hashCode;
}

class Pollutant {
  String name;
  Map<DateTime, double> values = {};

  Pollutant(this.name);

  toString() => '<Pollutant>$name';

  bool operator ==(o) => o is Pollutant && name == o.name;

  int get hashCode => name.hashCode;
}

main(List<String> args) async {
//  var dataUrl = 'http://www.malopolska.pl/_layouts/WrotaMalopolski/XmlData.aspx?data=2';
//  var file = new File('./data.xml');
  var file = new File('./datafull.xml');
  String contents = await file.readAsString(encoding: UTF8);
  XmlDocument xml = parse(await (file.readAsString(encoding: UTF8)));

  Map<String, Location> locations = new Map();
  xml.findElements('Current').single.findElements('Item').forEach((XmlElement item) {
    var locationName = item.findElements('City').single.text;
    locations.putIfAbsent(locationName, () => new Location(locationName));
    var location = locations[locationName];

    var pollutantName = item.findElements('Pollutant').single.text;
    location.pollutants.putIfAbsent(pollutantName, () => new Pollutant(pollutantName));
    var pollutant = location.pollutants[pollutantName];

    var date = DateTime.parse(item.findElements('Date').single.text);
    var value = double.parse(item.findElements('Value').single.text.replaceAll(',', '.'));
    pollutant.values[date] = value;
  });
  print(locations);

//  print(new Pollutant('aaa') == new Pollutant('aaa'));

//  Queue<Map> items = new Queue();
//  xml.findElements('Current').first.descendants.forEach((XmlNode node) {
//    print('type: ${node.nodeType}');
//    if (node is XmlElement) {
//      String name = node.name.toString();
//      print('name: "${node.name}", == Item: ${node.name.toString() == 'Item'}, text: ${node.text}');
//      if (name == 'Item') {
//        items.add(new Map());
//        //        print('added item ${items.last}');
//      } else if (items.isNotEmpty) {
//        items.last[name] = node.text;
//      }
//    }
//  });

//  Queue<Item> items = new Queue();
//  xml.findElements('Current').first.findElements('Item').forEach((XmlElement node) {
//    items.add(new Item(
//        node.findElements('City').single.text,
//        DateTime.parse(node.findElements('Date').single.text),
//        double.parse(node.findElements('Value').single.text.replaceAll(',', '.')),
//        node.findElements('Pollutant').single.text,
//        node.findElements('Concentration').single.text
//    ));
//  });

//  print('items: $items');


//  http_client.get(dataUrl)
//  .then((http_client.Response res) {
//    XmlDocument xml = parse(res.body);
//    print(xml);
//  });

//  var parser = new ArgParser()
//    ..addOption('port', abbr: 'p', defaultsTo: '8080');
//
//  var result = parser.parse(args);
//
//  var port = int.parse(result['port'], onError: (val) {
//    stdout.writeln('Could not parse port value "$val" into a number.');
//    exit(1);
//  });
//
//  var handler = const shelf.Pipeline()
//  .addMiddleware(shelf.logRequests())
//  .addHandler(_echoRequest);
//
//  io.serve(handler, 'localhost', port).then((server) {
//    print('Serving at http://${server.address.host}:${server.port}');
//  });
}

shelf.Response _echoRequest(shelf.Request request) {
  return new shelf.Response.ok('Request for "${request.url}"');
}
