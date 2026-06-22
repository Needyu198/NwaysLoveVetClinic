import 'package:flutter/material.dart';

class ProductStyles {
  const ProductStyles._();

  static const background = Color(0xFFF8F8F8);
  static const mint = Color(0xFFC2FBE3);
  static const red = Color(0xFFFF6C73);
  static const green = Color(0xFF06C957);
  static const ink = Colors.black;
  static const muted = Color(0xFF667085);

  static const pageTitle = TextStyle(
    color: ink,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const productName = TextStyle(
    color: ink,
    fontSize: 17,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const price = TextStyle(
    color: Colors.red,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const detailTitle = TextStyle(
    color: ink,
    fontSize: 31,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const sectionTitle = TextStyle(
    color: ink,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    color: ink,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
  );

  static const rowTitle = TextStyle(
    color: ink,
    fontSize: 21,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const caption = TextStyle(
    color: muted,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
