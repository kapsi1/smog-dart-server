part of app;

class Location {
  String name;

  Set<Pollutant> pollutants = new Set();

  Location(this.name);

  toString() => '<Location>$name';

  toJson() => {
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

  toJson() => {'dateTime': dateTime.toIso8601String(), 'value': value};
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
                                           key: (DateTime date) => date.toIso8601String(),
                                           value: (DateTime date) => values[date]);
    }
    return ret;
  }

  bool operator ==(o) => o is Pollutant && name == o.name;

  int get hashCode => name.hashCode;
}

var client = new http.Client();

Future<Map<String, Location>> loadData() async {
  print('loadData ' + new DateTime.now().toString());
  Map<String, Location> locations = new Map();
  xml.XmlDocument xmlDoc;

  if (debug) {
    var file = new File('datafull.xml');
    xmlDoc = xml.parse(await (file.readAsString(encoding: UTF8)));
  } else {
    var dataUrl = 'http://www.malopolska.pl/_layouts/WrotaMalopolski/XmlData.aspx?data=2';
    http.Response response = await client.get(dataUrl);
    client.close();
    response.headers['content-type'] = 'text/xml; charset=utf-8';
    xmlDoc = xml.parse(response.body);
  }
  xmlDoc.findElements('Current').single.findElements('Item').forEach((xml.XmlElement item) {
    var locationName = item.findElements('City').single.text;
    locations.putIfAbsent(locationName, () => new Location(locationName));
    var location = locations[locationName];

    var pollutantName = item.findElements('Pollutant').single.text;
    var pollutant = new Pollutant(pollutantName);
    if (!location.pollutants.contains(pollutant)) {
      location.pollutants.add(pollutant);
    } else {
      pollutant = location.pollutants.lookup(pollutant);
    }

    DateTime date = timezone.TZDateTime.parse(warsaw, item.findElements('Date').single.text);
    var value = double.parse(item.findElements('Value').single.text.replaceAll(',', '.'));
    pollutant.values[date] = value;
    if (pollutant.lastValue == null || date.isAfter(pollutant.lastValue.dateTime)) {
      pollutant.lastValue = new PollutantValue(date, value);
    }
  });
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