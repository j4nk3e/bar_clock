import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  text,
  shadow,
}

final _lightTheme = {
  _Element.background: Colors.white,
  _Element.text: Colors.black,
  _Element.shadow: Colors.grey,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _Element.shadow: Colors.grey
};

final _weatherIcons = {
  WeatherCondition.sunny: WeatherIcons.sunny,
  WeatherCondition.windy: WeatherIcons.windy,
  WeatherCondition.cloudy: WeatherIcons.cloudy,
  WeatherCondition.foggy: WeatherIcons.fog,
  WeatherCondition.rainy: WeatherIcons.rain,
  WeatherCondition.thunderstorm: WeatherIcons.thunderstorm,
  WeatherCondition.snowy: WeatherIcons.snow,
};

class BarClock extends StatefulWidget {
  const BarClock(this.model);

  final ClockModel model;

  @override
  _BarClockState createState() => _BarClockState();
}

class _BarClockState extends State<BarClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(BarClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        //  Theme.of(context).brightness == Brightness.light
        //     ? _lightTheme :
        _darkTheme;
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);
    final second = DateFormat('ss').format(_dateTime);
    final date = DateFormat.yMMMEd().format(_dateTime);
    final weatherMeta =
        'It is ${widget.model.weatherString} at ${widget.model.temperatureString}';
    final barHeight = MediaQuery.of(context).size.height / 7;
    final textStyle =
        TextStyle(color: colors[_Element.text], fontSize: barHeight);

    return Container(
      color: colors[_Element.background],
      child: Center(
        child: DefaultTextStyle(
          style: textStyle,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AspectRatio(
                  aspectRatio: 8,
                  child: CustomPaint(painter: BarPainter(_dateTime))),
              Stack(children: [
                Text('88:88:88',
                    style: TextStyle(
                        fontFamily: 'DSEG',
                        color: Colors.orange.withOpacity(0.4))),
                Text('$hour:$minute:$second',
                    style: TextStyle(fontFamily: 'DSEG', color: Colors.orange)),
              ]),
              Text('$date',
                  style: TextStyle(
                      fontFamily: 'DSEG', fontSize: 16, color: Colors.orange)),
              Semantics(
                label: weatherMeta,
                value: widget.model.temperatureString,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _weatherIcons.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(String.fromCharCode(e.value),
                            textScaleFactor: 1,
                            style: TextStyle(
                                fontFamily: 'weather',
                                fontSize: 28,
                                color: widget.model.weatherCondition == e.key
                                    ? WeatherIcons.colors[e.value]
                                    : Colors.white.withOpacity(0.6))),
                      );
                    }).toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarPainter extends CustomPainter {
  final DateTime dateTime;
  BarPainter(this.dateTime);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 52.0;
    final halfWidth = size.width / 2;
    final halfBar = barWidth / 2;
    final paint = Paint()
      ..strokeWidth = barWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..color = Colors.red.withOpacity(0.7);
    final base = Rect.fromLTRB(0, 0, size.width, size.width);
    var angle = pi * 1.25;
    final sweep = pi * 0.5;
    canvas.drawArc(base, angle, sweep, false, paint);
    canvas.save();
    canvas.translate(halfWidth, halfWidth);
    final steps = 24 * 4 + 1;
    canvas.rotate(-0.25 * pi);
    for (var step in Iterable.generate(steps)) {
      if (step % 4 == 0) {
        paint.color = Colors.white;
        var textPainter = TextPainter(
            text: TextSpan(text: '${step ~/ 4}'),
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(-textPainter.width / 2, -halfWidth + halfBar + 4));
        canvas.drawLine(Offset(0, -halfWidth + halfBar),
            Offset(0, -halfWidth + halfBar + 4), paint..strokeWidth = 1);
        paint.color = Colors.yellow;
      } else {
        paint.color = Colors.yellow.withOpacity(0.8);
      }
      if (dateTime.hour * 60 + dateTime.minute >= step * 15) {
        canvas.drawLine(Offset(0, -halfWidth + halfBar),
            Offset(0, -halfWidth - halfBar), paint..strokeWidth = 3);
      }
      canvas.rotate(sweep / steps);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class WeatherIcons {
  static const int sunny = 0xf00d;
  static const int cloudy = 0xf002;
  static const int fog = 0xf003;
  static const int rain = 0xf008;
  static const int snow = 0xf00a;
  static const int thunderstorm = 0xf010;
  static const int windy = 0xf085;

  static const colors = {
    sunny: Colors.green,
    cloudy: Colors.green,
    windy: Colors.green,
    fog: Colors.yellow,
    rain: Colors.yellow,
    thunderstorm: Colors.red,
    snow: Colors.red
  };
}
