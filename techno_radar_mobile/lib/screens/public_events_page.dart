import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_helper.dart';
import '../helpers/event_helpers.dart';
import '../helpers/dropdown_items.dart';
import '../widgets/music_background.dart';
import '../widgets/event_image.dart';
import '../widgets/empty_state.dart';
import 'event_details_page.dart';

class PublicEventsPage extends StatefulWidget {
  const PublicEventsPage({super.key});

  @override
  State<PublicEventsPage> createState() => _PublicEventsPageState();
}

class _PublicEventsPageState extends State<PublicEventsPage> {
  List events = [];
  int year = DateTime.now().year;
  int month = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPublicEvents();
  }

  Future<void> fetchPublicEvents() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse("${ApiHelper.baseUrl}/public-events?year=$year&month=$month"),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    setState(() {
      events = data is List ? data : [];
      isLoading = false;
    });
  }

  Future<void> addToMyList(int eventId) async {
    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/my-events/$eventId"),
      headers: await ApiHelper.headers(),
    );

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

    final data = jsonDecode(response.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"] ?? data["error"] ?? "Gotowe")),
    );
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
    );
  }

  Widget publicEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.74),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
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
                title: Text(
                  event["name"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    eventDaysUntil(event).isNotEmpty
                        ? "${eventCityName(event)} • ${eventDateWithDay(event)} • ${eventDaysUntil(event)}"
                        : "${eventCityName(event)} • ${eventDateWithDay(event)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
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
                      icon: const Icon(Icons.favorite),
                      label: const Text("Zapisz"),
                      onPressed: () => addToMyList(event["id"]),
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

  void changePublicYear(int? value) {
    setState(() {
      year = value ?? DateTime.now().year;
    });

    fetchPublicEvents();
  }

  void changePublicMonth(int? value) {
    setState(() {
      month = value ?? 0;
    });

    fetchPublicEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wszystkie wydarzenia"),
      ),
      body: MusicBackground(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Colors.deepPurpleAccent),
                      SizedBox(width: 8),
                      Text(
                        "Przeglądaj wydarzenia",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: year,
                    decoration: const InputDecoration(
                      labelText: "Rok",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 2024,
                        child: Text("2024"),
                      ),
                      DropdownMenuItem(
                        value: 2025,
                        child: Text("2025"),
                      ),
                      DropdownMenuItem(
                        value: 2026,
                        child: Text("2026"),
                      ),
                      DropdownMenuItem(
                        value: 2027,
                        child: Text("2027"),
                      ),
                      DropdownMenuItem(
                        value: 2028,
                        child: Text("2028"),
                      ),
                    ],
                    onChanged: changePublicYear,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: month,
                    decoration: const InputDecoration(
                      labelText: "Miesiąc",
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    items: monthDropdownItems(),
                    onChanged: changePublicMonth,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? emptyState(
                          icon: Icons.event_busy,
                          title: "Brak wydarzeń",
                          subtitle:
                              "Nie znaleziono wydarzeń dla wybranego roku lub miesiąca.",
                        )
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (_, index) {
                            return publicEventCard(events[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
