import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarClock extends StatefulWidget {
  const BarClock(this.model);

  final ClockModel model;

  @override
  _BarClockState createState() => _BarClockState();
}

class _BarClockState extends State<BarClock> {
  static const segmentFont = 'DSEG';
  static const weatherIconFont = 'weather';

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
    final bigFontSize = MediaQuery.of(context).size.height / 6;
    final smallFontSize = MediaQuery.of(context).size.height / 16;
    final time =
        DateFormat('${widget.model.is24HourFormat ? 'HH' : 'hh'}:mm:ss')
            .format(_dateTime);
    final date = DateFormat.yMMMEd().format(_dateTime);

    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.topCenter,
              child: AspectRatio(
                  aspectRatio: 2,
                  child: CustomPaint(painter: BarPainter(_dateTime))),
            ),
            Align(
              alignment: AlignmentDirectional.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(date,
                        style: TextStyle(
                            fontFamily: segmentFont,
                            fontSize: smallFontSize,
                            color: Colors.orange)),
                  ),
                  Semantics(
                    label: ' ',
                    value: time,
                    child: Stack(children: [
                      Text('88:88:88',
                          style: TextStyle(
                              fontSize: bigFontSize,
                              fontFamily: segmentFont,
                              color: Colors.orange.withOpacity(0.2))),
                      Text(time,
                          style: TextStyle(
                              fontSize: bigFontSize,
                              fontFamily: segmentFont,
                              color: Colors.orange)),
                    ]),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Semantics(
                label: 'It is ${widget.model.weatherString} '
                    'at a temperature of ${widget.model.temperatureString}',
                value: widget.model.temperatureString,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: WeatherIcons.conditions.entries.map((e) {
                      final active = widget.model.weatherCondition == e.key;
                      final color = WeatherIcons.colors[e.value];
                      return DecoratedBox(
                        decoration: ShapeDecoration(
                            color: active ? color : Colors.transparent,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 2, color: color.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(8))),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 9,
                          height: MediaQuery.of(context).size.width / 12,
                          child: Center(
                            child: Text(String.fromCharCode(e.value),
                                style: TextStyle(
                                    fontSize: smallFontSize,
                                    fontFamily: weatherIconFont,
                                    color: active
                                        ? Colors.black
                                        : color.withOpacity(0.4))),
                          ),
                        ),
                      );
                    }).toList()),
              ),
            ),
          ],
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
    final steps = 24 * 4;
    canvas.rotate(-0.25 * pi);
    canvas.rotate(sweep / steps / 2);
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

  static const conditions = {
    WeatherCondition.sunny: WeatherIcons.sunny,
    WeatherCondition.windy: WeatherIcons.windy,
    WeatherCondition.cloudy: WeatherIcons.cloudy,
    WeatherCondition.foggy: WeatherIcons.fog,
    WeatherCondition.rainy: WeatherIcons.rain,
    WeatherCondition.thunderstorm: WeatherIcons.thunderstorm,
    WeatherCondition.snowy: WeatherIcons.snow,
  };
}
