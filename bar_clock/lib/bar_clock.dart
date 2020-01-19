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

const segmentFont = 'DSEG';
const weatherIconFont = 'weather';

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
        const Duration(seconds: 1) -
            Duration(milliseconds: _dateTime.millisecond),
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
    final semanticDate = DateFormat.yMMMMEEEEd().format(_dateTime);

    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Align(
              alignment: AlignmentDirectional.topCenter,
              child: AspectRatio(
                  aspectRatio: 2,
                  child: CustomPaint(
                      painter: BarPainter(
                          _dateTime, MediaQuery.of(context).size.height / 7))),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Today is $semanticDate',
                  value: semanticDate,
                  child: Text(date,
                      style: TextStyle(
                          fontFamily: segmentFont,
                          fontSize: smallFontSize,
                          color: Colors.orange)),
                ),
                Semantics(
                  label: 'The time is $time',
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
            Semantics(
              label: 'It is ${widget.model.weatherString} '
                  'at a temperature of ${widget.model.temperatureString}',
              value: widget.model.temperatureString,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: SizedBox(
                                      height: smallFontSize,
                                      child: CustomPaint(
                                          painter: TemperatureBarPainter(
                                              widget.model.low,
                                              widget.model.high,
                                              widget.model.temperature,
                                              widget.model.unitString)),
                                    )),
                              ),
                            ])),
                  ),
                  Row(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemperatureBarPainter extends CustomPainter {
  final num low;
  final num high;
  final num current;
  final String unit;

  TemperatureBarPainter(this.low, this.high, this.current, this.unit);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final textHeight = size.height * 0.7;
    final lowText = TextPainter(
        text: TextSpan(
            text: '${low.round()}$unit',
            style: TextStyle(
                color: Colors.blueAccent,
                fontSize: textHeight,
                fontFamily: segmentFont)),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr)
      ..layout();
    lowText.paint(
        canvas, Offset(-lowText.width - 4, (size.height - textHeight) / 2));
    final highText = TextPainter(
        text: TextSpan(
            text: '${high.round()}$unit',
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: textHeight,
                fontFamily: segmentFont)),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr)
      ..layout();
    highText.paint(
        canvas, Offset(size.width + 4, (size.height - textHeight) / 2));

    _drawBar(canvas, size, paint);
    canvas.clipRect(Rect.fromLTWH(
        0,
        0,
        high > low ? size.width * (current - low) / (high - low) : 0,
        size.height));
    _drawBar(canvas, size, paint..color = Colors.yellow);
  }

  void _drawBar(Canvas canvas, Size size, Paint paint) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(2)),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      !(oldDelegate is TemperatureBarPainter &&
          oldDelegate.low == low &&
          oldDelegate.high != high &&
          oldDelegate.current != current);
}

class BarPainter extends CustomPainter {
  final DateTime dateTime;
  final double barWidth;
  BarPainter(this.dateTime, this.barWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final halfWidth = size.width / 2;
    final halfBar = barWidth / 2;
    final paint = Paint()
      ..strokeWidth = barWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..color = Colors.red.withOpacity(0.7);
    final base = Rect.fromLTRB(0, 0, size.width, size.width);
    const sweep = pi * 0.7;
    const angle = pi * 1.5 - sweep / 2;
    const segmentWidth = 0.5;
    const steps = 24 * 4;
    canvas.drawArc(base, angle, sweep, false, paint);
    for (var step in Iterable<int>.generate(steps)) {
      if (step % 8 == 0) {
        canvas.save();
        canvas.translate(halfWidth, halfWidth);
        canvas.rotate(
            angle + pi * 0.5 + (segmentWidth / 2 + step) * sweep / steps);
        paint.color = Colors.white;
        final textPainter = TextPainter(
            text: TextSpan(
                text: '${step ~/ 4}', style: const TextStyle(fontSize: 12)),
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(-textPainter.width / 2, -halfWidth + halfBar + 4));
        canvas.drawLine(Offset(0, -halfWidth + halfBar),
            Offset(0, -halfWidth + halfBar + 4), paint..strokeWidth = 1);
        canvas.restore();
      }
      if (dateTime.hour * 60 + dateTime.minute >= step * 15) {
        final bold = step % 4 == 0;
        paint.color = bold ? Colors.yellow : Colors.yellow.withOpacity(0.8);
        canvas.drawArc(
            base,
            angle + (bold ? (step - 0.05) : step) * sweep / steps,
            (bold ? 1.2 : 1) * sweep / steps * segmentWidth,
            false,
            paint..strokeWidth = barWidth);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      !(oldDelegate is BarPainter &&
          oldDelegate.dateTime == dateTime &&
          oldDelegate.barWidth != barWidth);
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
