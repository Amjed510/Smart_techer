import 'package:flutter/material.dart';

class CustomPositionedElements {
  static Positioned starIconTopRight() {
    return Positioned(
      top: 0,
      right: 30,
      child: Transform.rotate(
        angle: 0.5,
        child: Icon(Icons.star, size: 50, color: Colors.orangeAccent),
      ),
    );
  }

  static Positioned taaIconTopRight() {
    return Positioned(
      top: 35,
      right: 0,
      child: Transform.rotate(
        angle: 0.3,
        child: Opacity(
          opacity: 0.2,
          child: Image.asset(
            'assets/icons/taa.png',
            width: 45,
            height: 45,
          ),
        ),
      ),
    );
  }

  static Positioned khaIconRightMiddle() {
    return Positioned(
      top: 230,
      right: 0,
      child: Opacity(
        opacity: 0.2,
        child: Transform.rotate(
          angle: 5.9,
          child: Image.asset(
            'assets/icons/kha.png',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }

  static Positioned haaIconBottomRight() {
    return Positioned(
      bottom: 100,
      right: 5,
      child: Opacity(
        opacity: 0.2,
        child: Transform.rotate(
          angle: 0.4,
          child: Image.asset(
            'assets/icons/haa.png',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }

  static Positioned fourIconTopLeft() {
    return Positioned(
      top: 0,
      left: 5,
      child: Opacity(
        opacity: 0.2,
        child: Transform.rotate(
          angle: 0.0,
          child: Image.asset(
            'assets/icons/four.png',
            width: 45,
            height: 45,
          ),
        ),
      ),
    );
  }

  static Positioned dashIconTopLeft() {
    return Positioned(
      top: 60,
      left: 0,
      child: Opacity(
        opacity: 0.2,
        child: Transform.rotate(
          angle: 0.0,
          child: Image.asset(
            'assets/icons/dash.png',
            width: 45,
            height: 45,
          ),
        ),
      ),
    );
  }

  static Positioned seenIconMiddleLeft() {
    return Positioned(
      top: 190,
      left: 5,
      child: Opacity(
        opacity: 0.4,
        child: Transform.rotate(
          angle: 5.8,
          child: Image.asset(
            'assets/icons/seen.png',
            width: 50,
            height: 50,
          ),
        ),
      ),
    );
  }

  static Positioned noonIconBottomLeft() {
    return Positioned(
      bottom: 190,
      left: 5,
      child: Opacity(
        opacity: 0.4,
        child: Transform.rotate(
          angle: 5.5,
          child: Image.asset(
            'assets/icons/noon.png',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }

  static Positioned starIconBottomLeft() {
    return Positioned(
      bottom: 10,
      left: 0,
      child: Transform.rotate(
        angle: 0.5,
        child: Icon(Icons.star, size: 50, color: Colors.blueAccent),
      ),
    );
  }
}
