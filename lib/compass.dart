import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Compass extends StatefulWidget {
  const Compass({Key? key}) : super(key: key);

  @override
  State<Compass> createState() => _CompassState();
}

class _CompassState extends State<Compass> {
  MagnetometerEvent _magneticEvent = MagnetometerEvent(0, 0, 0);
  StreamSubscription? subscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    subscription = magnetometerEvents.listen((event) {
      setState(() {
        _magneticEvent = event;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    subscription?.cancel();
    super.dispose();
  }

  double calculateDegrees(double x, double y) {
    double heading = atan2(x, y);
    heading = heading * 180 / pi;
    if (heading > 0) {
      heading -= 360;
    }
    return heading * -1;
  }

  @override
  Widget build(BuildContext context) {
    final degrees = calculateDegrees(_magneticEvent.x, _magneticEvent.y);
    final angle = -1 * pi / 180 * degrees;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /*Text(
          '${degrees.toStringAsFixed(0)}',
          style: TextStyle(color: Colors.white),
        ),*/
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset("assets/images/cadrant.png", scale: 7.4),
            Transform.rotate(
              angle: angle,
              child: Image.asset(
                "assets/images/compass.png",
                scale: 8.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
