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
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const productName = TextStyle(
    color: ink,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const price = TextStyle(
    color: Colors.red,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const detailTitle = TextStyle(
    color: ink,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const sectionTitle = TextStyle(
    color: ink,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    color: ink,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: 0,
  );

  static const rowTitle = TextStyle(
    color: ink,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
}
