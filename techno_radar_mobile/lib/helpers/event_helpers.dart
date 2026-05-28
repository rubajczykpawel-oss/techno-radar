import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_page.dart';

String eventDateWithDay(Map event) {
  final formattedDate = (event["formatted_date"] ?? "").toString();
  final date = (event["date"] ?? "").toString();
  final dayOfWeek = (event["day_of_week"] ?? "").toString();

  if (formattedDate.isNotEmpty) {
    return formattedDate;
  }

  if (date.isEmpty && dayOfWeek.isEmpty) {
    return "";
  }

  if (dayOfWeek.isEmpty) {
    return date;
  }

  if (date.isEmpty) {
    return dayOfWeek;
  }

  return "$date • $dayOfWeek";
}

String eventCityName(Map event) {
  final cityDisplay = (event["city_display"] ?? "").toString();
  final city = (event["city"] ?? "").toString();

  if (cityDisplay.isNotEmpty) {
    return cityDisplay;
  }

  return city;
}

String eventDaysUntil(Map event) {
  return (event["days_until"] ?? "").toString();
}

String eventSourceName(Map event) {
  final source = (event["source_name"] ?? "").toString();

  if (source == "manual") {
    return "Dodany ręcznie";
  }

  if (source == "Ticketmaster") {
    return "Ticketmaster";
  }

  if (source.isEmpty) {
    return "Nieznane źródło";
  }

  return source;
}

String eventMusicTypeName(Map event) {
  final type = (event["music_type"] ?? "").toString();

  if (type == "Electronic") {
    return "Muzyka elektroniczna";
  }

  return type;
}

Future<void> handleUnauthorized(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove("token");
  await prefs.remove("is_admin");

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Sesja wygasła. Zaloguj się ponownie."),
    ),
  );

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
