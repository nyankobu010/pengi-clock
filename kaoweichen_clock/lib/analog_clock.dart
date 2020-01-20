// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'package:flare_flutter/flare_actor.dart';

import 'container_hand.dart';
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _backgroundGardient = [
    Colors.blue[400],
    Colors.blue[600],
    Colors.blue[700],
    Colors.blue[800],
  ];
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer1;
  Timer _timer2;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateBackgroundGradient();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer1 = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  void _updateBackgroundGradient() {
    setState(() {
      // Update _timeOfDay based on the hour to determine the
      // gradient. This is not location or time of year accurate.
      var _timeOfDay = 'day';

      if (_now.hour < 4) {
        _timeOfDay = 'night';
      } else if ((4 <= _now.hour && _now.hour < 5) ||
          (21 <= _now.hour && _now.hour < 22)) {
        _timeOfDay = 'astronomical_twilight';
      } else if ((5 <= _now.hour && _now.hour < 6) ||
          (20 <= _now.hour && _now.hour < 21)) {
        _timeOfDay = 'nautical_twilight';
      } else if ((6 <= _now.hour && _now.hour < 7) ||
          (19 <= _now.hour && _now.hour < 20)) {
        _timeOfDay = 'civil_twilight';
      } else {
        _timeOfDay = 'day';
      }

      switch (_timeOfDay) {
        case 'night':
          _backgroundGardient = [
            Colors.blue[900],
            Colors.deepPurple[900],
            Colors.deepPurple[800],
            Colors.deepPurple[700],
          ];
          break;
        case 'day':
          _backgroundGardient = [
            Colors.blue[400],
            Colors.blue[600],
            Colors.blue[700],
            Colors.blue[800],
          ];
          break;
        case 'astronomical_twilight':
          _backgroundGardient = [
            Colors.blue[900],
            Colors.deepPurple[300],
            Colors.orange[200],
            Colors.orange[900],
          ];
          break;
        case 'nautical_twilight':
          _backgroundGardient = [
            Colors.deepPurple[400],
            Colors.blue[200],
            Colors.orange[100],
            Colors.orange[500],
          ];
          break;
        case 'civil_twilight':
          _backgroundGardient = [
            Colors.blue[200],
            Colors.blue[400],
            Colors.blue[500],
            Colors.orange[200],
          ];
          break;
        default:
          _backgroundGardient = [
            Colors.blue[400],
            Colors.blue[600],
            Colors.blue[700],
            Colors.blue[800],
          ];
          break;
      }

      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer2 = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateBackgroundGradient,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Colors.orange[800],
            // Minute hand.
            highlightColor: Colors.orange[600],
            // Second hand.
            accentColor: Colors.orange[300],
            backgroundColor: Color(0xFF000000),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF000000),
          );

    final characterAnimation = Theme.of(context).brightness == Brightness.light
        ? FlareActor('assets/pengi.flr', animation: 'day_mode')
        : FlareActor('assets/pengi.flr', animation: 'night_mode');

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
//        color: customTheme.backgroundColor,
        decoration: BoxDecoration(
            // Box decoration takes a gradient
            gradient: LinearGradient(
          // Where the linear gradient begins and ends
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Add one stop for each color. Stops should increase from 0 to 1
          stops: [0.1, 0.5, 0.7, 0.9],
          colors: _backgroundGardient,
        )),
        child: Stack(
          children: [
            Container(child: characterAnimation),
            // Example of a hand drawn with [CustomPainter].
            DrawnHand(
              color: customTheme.accentColor,
              thickness: 4,
              size: .8,
              angleRadians: _now.second * radiansPerTick,
            ),
            DrawnHand(
              color: customTheme.highlightColor,
              thickness: 8,
              size: 0.7,
              angleRadians: _now.minute * radiansPerTick,
            ),
            // Example of a hand drawn with [Container].
            ContainerHand(
              color: Colors.transparent,
              size: 0.3,
              angleRadians: _now.hour * radiansPerHour +
                  (_now.minute / 60) * radiansPerHour,
              child: Transform.translate(
                offset: Offset(0.0, -60.0),
                child: Container(
                  width: 16,
                  height: 150,
                  decoration: BoxDecoration(
                      color: customTheme.primaryColor,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
