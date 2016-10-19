part of app;

class Location {
  String name;

  Set<Pollutant> pollutants = new Set();

  Location(this.name);

  toString() => '<Location>$name';

  toJson() =>
      {
        'name': name,
        'pollutants': new Map.fromIterable(pollutants,
            key: (Pollutant p) => p.name,
            value: (Pollutant p) => p)
      };
}

class PollutantValue {
  DateTime dateTime;
  double value;

  PollutantValue(DateTime this.dateTime, double this.value);

  toJson() => {'dateTime': dateTime.toUtc().toIso8601String(), 'value': value};
}

class Pollutant {
  String name;
  Map<DateTime, double> values = {};
  PollutantValue lastValue;

  Pollutant(this.name);

  toString() => '<Pollutant>$name';

  toJson() {
    var ret = {
      'name': name,
      'lastValue': lastValue
    };
    if (values.length > 0) {
      ret['values'] = new Map.fromIterable(values.keys,
          key: (DateTime date) => date.toUtc().toIso8601String(),
          value: (DateTime date) => values[date]);
    }
    return ret;
  }

  bool operator ==(o) => o is Pollutant && name == o.name;

  int get hashCode => name.hashCode;
}

String getFormattedDate() {
  var now = new DateTime.now();
  var formatter = new DateFormat('dd.MM.yyyy');
  return formatter.format(now);
}

Future<Map<String, Location>> loadData() async {
  Map<String, Location> locations = new Map();
  Map data;

  var httpClient = new HttpClient();
  var todaysDate = getFormattedDate();
  var formData = '{"measType":"Auto","viewType":"Station","dateRange":"Day","date":"$todaysDate","viewTypeEntityId":6,"channels":[46]}';
  String encodedFormData = "query=" + Uri.encodeQueryComponent(formData);
  HttpClientRequest request = await httpClient.post(
      'monitoring.krakow.pios.gov.pl', 80, '/dane-pomiarowe/pobierz');
  request.headers.contentType =
  new ContentType("application", "x-www-form-urlencoded", charset: "utf-8");
  request.write(encodedFormData);
  HttpClientResponse response = await request.close();
  response.transform(UTF8.decoder).listen((contents) {
    var data = JSON.decode(contents)['data'];
    print(data);
    List series = data['series'][0]['data'];
    var lastDataPoint = series[series.length - 1];
    DateTime lastDateTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastDataPoint[0]) * 1000);
    var lastValue = lastDataPoint[1];
    print(lastDateTime.toIso8601String() + ' ' + lastValue);
  });

//  xmlDoc
//      .findElements('Current')
//      .single
//      .findElements('Item')
//      .forEach((xml.XmlElement item) {
//    var locationName = item
//        .findElements('City')
//        .single
//        .text;
//    locations.putIfAbsent(locationName, () => new Location(locationName));
//    var location = locations[locationName];
//
//    var pollutantName = item
//        .findElements('Pollutant')
//        .single
//        .text;
//    var pollutant = new Pollutant(pollutantName);
//    if (!location.pollutants.contains(pollutant)) {
//      location.pollutants.add(pollutant);
//    } else {
//      pollutant = location.pollutants.lookup(pollutant);
//    }
//    //source dates always in CET timezone
//    DateTime date = DateTime.parse(item
//        .findElements('Date')
//        .single
//        .text
//        .replaceAll(' ', 'T') + '.000+01');
//    //bug? musi być .000
//    var value = double.parse(item
//        .findElements('Value')
//        .single
//        .text
//        .replaceAll(',', '.'));
//    pollutant.values[date] = value;
//    if (pollutant.lastValue == null ||
//        date.isAfter(pollutant.lastValue.dateTime)) {
//      pollutant.lastValue = new PollutantValue(date, value);
//    }
//  });
  print('loadData, locations loaded: ${locations.length}');
  return locations;
}

Map<String, Location> locationsOnlyLastValues(Map<String, Location> locations) {
  /// Copy locations so the original isn't changed.
  Map<String, Location> ret = {};
  locations.forEach((name, location) {
    var l = new Location(name);

    location.pollutants.forEach((pollutant) {
      var p = new Pollutant(pollutant.name);
      p.lastValue = pollutant.lastValue;
      l.pollutants.add(p);
    });

    ret[name] = l;
  });
  return ret;
}