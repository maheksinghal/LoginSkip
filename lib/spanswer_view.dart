import 'package:flutter/material.dart';
import 'dart:math';

class SpanswerView extends StatefulWidget {
  final double radius;
  final int itemCount;

  const SpanswerView({
    super.key,
    required this.radius,
    required this.itemCount,
  });

  @override
  _SpanswerViewState createState() => _SpanswerViewState();
}

class _SpanswerViewState extends State<SpanswerView> {
  double _sliderValue = 0;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: Stack(
        children: [
          ...List.generate(widget.itemCount, (index) {
            final angle = (2 * 3.141592653589793 * index) / widget.itemCount;
            final x = widget.radius + widget.radius * (0.8) * cos(angle);
            final y = widget.radius + widget.radius * (0.8) * sin(angle);

            return Positioned(
              left: x - 25,
              top: y - 25,
              //child: GestureDetector(
              //onTap: () => onIconPressed(index),
              child: const CircleAvatar(
                radius: 25, // Radius of each circular icon
                backgroundColor: Colors.blue,
                child: Icon(Icons.ac_unit),
              ),
              //),
            );
          }),
          Center(
            child: Transform.rotate(
              angle: -pi / 4, // Rotates the slider by 45 degrees (diagonal)
              child: SizedBox(
                width: widget.radius * 0.9,
                child: Slider(
                  value: _sliderValue,
                  onChanged: (newValue) {
                    setState(() {
                      _sliderValue = newValue;
                    });
                  },
                  min: 0,
                  max: 100,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
