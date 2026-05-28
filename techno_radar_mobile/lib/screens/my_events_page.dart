import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_helper.dart';
import '../helpers/event_helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_image.dart';
import '../widgets/music_background.dart';
import 'event_details_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List events = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMyEvents();
  }

  Future<void> fetchMyEvents() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse("${ApiHelper.baseUrl}/my-events"),
      headers: await ApiHelper.headers(),
    );

    if (!mounted) return;

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    final data = jsonDecode(response.body);

    if (!mounted) return;

    setState(() {
      events = data is List ? data : [];
      isLoading = false;
    });
  }

  Future<void> removeFromMyList(int eventId) async {
    final response = await http.delete(
      Uri.parse("${ApiHelper.baseUrl}/my-events/$eventId"),
      headers: await ApiHelper.headers(),
    );

    if (!mounted) return;

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    final data = jsonDecode(response.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"] ?? data["error"] ?? "Gotowe")),
    );

    fetchMyEvents();
  }

  void goDetails(Map event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          event: event,
          isAdmin: false,
          onDelete: () async {},
          onEdit: () async {},
        ),
      ),
    ).then((_) {
      fetchMyEvents();
    });
  }

  Widget myEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withValues(alpha: 0.74),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => goDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              eventImage(event["image_url"], height: 190),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite, color: Colors.redAccent),
                title: Text(
                  event["name"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  eventDaysUntil(event).isNotEmpty
                      ? "${eventCityName(event)} • ${eventDateWithDay(event)} • ${eventDaysUntil(event)}"
                      : "${eventCityName(event)} • ${eventDateWithDay(event)}",
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text("Szczegóły"),
                      onPressed: () => goDetails(event),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text("Usuń"),
                      onPressed: () => removeFromMyList(event["id"]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Moje wydarzenia")),
      body: MusicBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : events.isEmpty
            ? emptyState(
                icon: Icons.favorite_border,
                title: "Nie masz zapisanych wydarzeń",
                subtitle:
                    "Dodaj wydarzenie do swojej listy, aby łatwo wrócić do niego później.",
              )
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (_, index) {
                  return myEventCard(events[index]);
                },
              ),
      ),
    );
  }
}
