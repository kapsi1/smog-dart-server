// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library app;

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';
import 'package:shelf_cors/shelf_cors.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;

part 'data_reader.dart';

bool debug = false;

main(List<String> args) async {
  var locations = await loadData();
  locations = locationsOnlyLastValues(locations);
  new Timer.periodic(new Duration(minutes: 15), (Timer timer) {
    loadData().then((locations) => locations = locationsOnlyLastValues(locations));
  });

  int port;
  if(Platform.environment.containsKey('PORT')) port = int.parse(Platform.environment['PORT']);
  else port = 8080;

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
  .addMiddleware(createCorsHeadersMiddleware())
  .addHandler(myRouter.handler);
  HttpServer server = await io.serve(handler, '0.0.0.0', port);
  server.autoCompress = true;
  print('Serving at http://${server.address.host}:${server.port}');
}