import 'package:dart_where39/word_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chips_input/flutter_chips_input.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

import 'where39_position.dart';
import 'widgets/marker_widget.dart';

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
              _buildMarkerLayerOptions(),
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

  MarkerLayerOptions _buildMarkerLayerOptions() {
    return MarkerLayerOptions(
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
