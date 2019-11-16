import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

import '../where39_position.dart';

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
