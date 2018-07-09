import 'dart:convert';
import 'dart:core';
import 'dart:ui' as UI;
import 'dart:async';

class FixtureModel {
  int id = 0;
  double width = 0.0;
  double height = 0.0;
  List<List<Product>> p = List<List<Product>>();
}

class Product {
  int id = 0;
  UI.Image image;
  String url = "";
  bool shouldBeUpdated = false;
}
