// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library app;

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';
import 'package:xml/xml.dart';
import 'package:timezone/standalone.dart' as timezone;

part 'data_reader.dart';

main(List<String> args) async {
  await loadData();
  var locations = getFullLocations();
  var parser = new ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8080');

  var port = int.parse(parser.parse(args)['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });
  var headers = {'Content-Type': 'application/json; charset=utf-8'};
  var myRouter = router()
    ..get('/', (r) => new shelf.Response.ok(JSON.encode(locations), headers:headers))
    ..get('/{location}', (request) {
    var location = locations[getPathParameter(request, 'location')];
    var jsonLocation = JSON.encode(location);
    return new shelf.Response.ok(jsonLocation, headers:headers);
  });

  var handler = const shelf.Pipeline()
  .addMiddleware(shelf.logRequests())
  .addHandler(myRouter.handler);
  io.serve(handler, 'localhost', port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}