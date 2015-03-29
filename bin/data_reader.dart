part of app;

Map<String, Location> locations = new Map();

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

  toJson() => {
    'name': name,
    'values': new Map.fromIterable(values.keys,
                                   key: (DateTime date) => date.toIso8601String(),
                                   value: (DateTime date) => values[date]),
    'lastValue': lastValue
  };

  bool operator ==(o) => o is Pollutant && name == o.name;

  int get hashCode => name.hashCode;
}

Future<Map<String, Location>> loadData() async {
  await timezone.initializeTimeZone();
  final timezone.Location warsaw = timezone.getLocation('Europe/Warsaw');

  //  var dataUrl = 'http://www.malopolska.pl/_layouts/WrotaMalopolski/XmlData.aspx?data=2';
//  http_client.get(dataUrl)
//  .then((http_client.Response res) {
//    XmlDocument xml = parse(res.body);
//    print(xml);
//  });
  var file = new File('data-cest.xml');
  XmlDocument xml = parse(await (file.readAsString(encoding: UTF8)));

  xml.findElements('Current').single.findElements('Item').forEach((XmlElement item) {
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
}

getFullLocations() {
  locations;
}