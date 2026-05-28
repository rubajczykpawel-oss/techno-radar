import 'package:flutter/material.dart';

List<DropdownMenuItem<int>> yearDropdownItems() {
  return const [
    DropdownMenuItem(value: 0, child: Text("Wszystkie lata")),
    DropdownMenuItem(value: 2024, child: Text("2024")),
    DropdownMenuItem(value: 2025, child: Text("2025")),
    DropdownMenuItem(value: 2026, child: Text("2026")),
    DropdownMenuItem(value: 2027, child: Text("2027")),
    DropdownMenuItem(value: 2028, child: Text("2028")),
  ];
}

List<DropdownMenuItem<int>> monthDropdownItems() {
  return const [
    DropdownMenuItem(value: 0, child: Text("Wszystkie miesiące")),
    DropdownMenuItem(value: 1, child: Text("Styczeń")),
    DropdownMenuItem(value: 2, child: Text("Luty")),
    DropdownMenuItem(value: 3, child: Text("Marzec")),
    DropdownMenuItem(value: 4, child: Text("Kwiecień")),
    DropdownMenuItem(value: 5, child: Text("Maj")),
    DropdownMenuItem(value: 6, child: Text("Czerwiec")),
    DropdownMenuItem(value: 7, child: Text("Lipiec")),
    DropdownMenuItem(value: 8, child: Text("Sierpień")),
    DropdownMenuItem(value: 9, child: Text("Wrzesień")),
    DropdownMenuItem(value: 10, child: Text("Październik")),
    DropdownMenuItem(value: 11, child: Text("Listopad")),
    DropdownMenuItem(value: 12, child: Text("Grudzień")),
  ];
}
