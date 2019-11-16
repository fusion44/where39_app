import 'package:dart_where39/where39.dart';
import 'package:dart_where39/word_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chips_input/flutter_chips_input.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Where 39',
      theme: ThemeData.dark(),
      home: MyHomePage(title: 'Where 39 Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Where39Position {
  final Where39 _w39 = Where39();
  LatLng _latLng = LatLng(52.49303704, 13.41792593); // Default Room77
  List<String> _words = ['slush', 'extend', 'until', 'layer', 'arch'];

  Where39Position.fromCoords(LatLng coords) {
    latLng = coords;
  }

  Where39Position.fromWords(List<String> wordList) {
    if (wordList.length > 5) {
      throw new ArgumentError('Length must not exceed 5');
    }
    words = wordList;
  }

  LatLng get latLng => _latLng;
  set latLng(LatLng latLng) {
    _latLng = latLng;
    _words = _w39.toWords(latLng);
  }

  List<String> get words => _words;
  set words(List<String> words) {
    _words = words;
    _latLng = _w39.fromWords(words);
  }

  @override
  String toString() {
    return '$_words // $_latLng';
  }
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _showMarker = false;
  Where39Position _pos = Where39Position.fromCoords(
    LatLng(52.49303704, 13.41792593),
  );
  List<String> _inputWords = const [];

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final _latTween = Tween<double>(
      begin: _mapController.center.latitude,
      end: destLocation.latitude,
    );
    final _lngTween = Tween<double>(
      begin: _mapController.center.longitude,
      end: destLocation.longitude,
    );
    final _zoomTween = Tween<double>(
      begin: _mapController.zoom,
      end: destZoom,
    );

    var controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _pos.latLng,
              zoom: 5.0,
              minZoom: 2.0,
              maxZoom: 19.0,
              onTap: (LatLng coords) {
                _animatedMapMove(coords, _mapController.zoom);
                setState(() {
                  _showMarker = true;
                  _pos.latLng = coords;
                  _mapController.move(_pos.latLng, _mapController.zoom);
                });
              },
            ),
            layers: [
              TileLayerOptions(
                // urlTemplate:
                //     'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                // subdomains: ['a', 'b', 'c'],
                urlTemplate: "https://api.tiles.mapbox.com/v4/"
                    "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': '',
                  'id': 'mapbox.streets',
                },
              ),
              MarkerLayerOptions(
                markers: _showMarker
                    ? [
                        Marker(
                          width: 280.0,
                          height: 160.0,
                          anchorPos: AnchorPos.align(AnchorAlign.top),
                          point: _pos.latLng,
                          builder: (ctx) => Container(
                            child: MarkerWidget(
                              _pos,
                              onClose: () {
                                setState(() {
                                  _showMarker = false;
                                });
                              },
                              onShare: () {
                                print("share");
                              },
                            ),
                          ),
                        )
                      ]
                    : const [],
              ),
            ],
          ),
          Positioned(
            bottom: 8.0,
            right: 8.0,
            child: FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: _showDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _onChipsInput(List<dynamic> words) {
    _inputWords = words.cast<String>();
  }

  void _showDialog() async {
    bool result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          content: ChipsInput(
            initialValue: [],
            decoration: InputDecoration(
              labelText: "Select Words",
            ),
            maxChips: 5,
            findSuggestions: (String query) {
              if (query.length != 0) {
                return wordList
                    .where((word) => word.startsWith(query))
                    .toList(growable: false);
              } else {
                return const [];
              }
            },
            onChanged: _onChipsInput,
            chipBuilder: (context, state, word) {
              return InputChip(
                key: ObjectKey(word),
                label: Text(word),
                onDeleted: () => state.deleteChip(word),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
            suggestionBuilder: (context, state, word) {
              return ListTile(
                key: ObjectKey(word),
                title: Text(word),
                onTap: () => state.selectSuggestion(word),
              );
            },
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Go!"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result != null && result) {
      setState(() {
        _showMarker = true;
        _pos.words = _inputWords;
        _animatedMapMove(_pos.latLng, _mapController.zoom);
      });
    }
  }
}

class MarkerWidget extends StatelessWidget {
  final Where39Position _pos;
  final Function onClose;
  final Function onShare;
  MarkerWidget(this._pos, {@required this.onClose, this.onShare});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    LatLng rounded = _pos.latLng.round(decimals: 6);
    return Stack(
      children: <Widget>[
        // Opacity(
        //   opacity: 0.2,
        //   child: Container(
        //     color: Colors.red,
        //   ),
        // ),
        Container(
          width: 280,
          height: 120,
          child: Card(
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _pos.words.toString(),
                    style: theme.textTheme.body2.copyWith(fontSize: 20.0),
                  ),
                  Divider(),
                  Text('lat: ${rounded.latitude}'),
                  Text('lng: ${rounded.longitude}'),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Icon(Icons.gps_fixed, size: 25, color: Colors.black),
        ),
        Positioned(
          right: 0.0,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        onShare != null
            ? Positioned(
                bottom: 40.0,
                right: 0.0,
                child: IconButton(
                  icon: Icon(Icons.share),
                  onPressed: onShare,
                ),
              )
            : Container(),
      ],
    );
  }
}
