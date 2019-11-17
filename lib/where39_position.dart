import 'package:dart_where39/where39.dart';
import 'package:latlong/latlong.dart';

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

  void shuffle(int shuffleValue) {
    _w39.shuffle = shuffleValue;
    _words = _w39.toWords(_latLng);
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
