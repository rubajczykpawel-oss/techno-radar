import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_helper.dart';
import '../helpers/event_helpers.dart';
import '../widgets/event_image.dart';
import '../widgets/glass_panel.dart';
import '../widgets/music_background.dart';
import '../widgets/neon_tag.dart';

class EventDetailsPage extends StatelessWidget {
  final Map event;
  final bool isAdmin;
  final Future<void> Function() onDelete;
  final Future<void> Function() onEdit;

  const EventDetailsPage({
    super.key,
    required this.event,
    required this.isAdmin,
    required this.onDelete,
    required this.onEdit,
  });

  Widget detailRow(String label, String value, IconData icon) {
    return Card(
      color: Colors.black.withValues(alpha: 0.68),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value.isEmpty ? "Brak informacji" : value),
      ),
    );
  }

  Future<void> addToMyList(BuildContext context) async {
    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/my-events/${event["id"]}"),
      headers: await ApiHelper.headers(),
    );

    if (!context.mounted) return;

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    final data = jsonDecode(response.body);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data["message"] ?? data["error"] ?? "Gotowe"),
      ),
    );
  }

  Future<void> openTicketLink(BuildContext context) async {
    final sourceUrl = (event["source_url"] ?? "").toString().trim();

    if (sourceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Brak linku do biletów")),
      );
      return;
    }

    final uri = Uri.tryParse(sourceUrl);

    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Niepoprawny link do biletów: $sourceUrl")),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: "_blank",
      );

      if (!context.mounted) return;

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nie udało się otworzyć linku")),
        );
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd otwierania linku: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicType = eventMusicTypeName(event);
    final sourceUrl = (event["source_url"] ?? "").toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Szczegóły wydarzenia"),
      ),
      body: MusicBackground(
        child: Center(
          child: Container(
            width: 620,
            padding: const EdgeInsets.all(18),
            child: ListView(
              children: [
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eventImage(event["image_url"], height: 300),
                      const SizedBox(height: 18),
                      Text(
                        event["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          neonTag(
                            text: eventCityName(event),
                            icon: Icons.location_city,
                            color: Colors.deepPurpleAccent,
                          ),
                          neonTag(
                            text: musicType,
                            icon: Icons.music_note,
                            color: Colors.cyanAccent,
                          ),
                          if (eventDaysUntil(event).isNotEmpty)
                            neonTag(
                              text: eventDaysUntil(event),
                              icon: Icons.hourglass_bottom,
                              color: Colors.greenAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      detailRow(
                        "Miasto",
                        eventCityName(event),
                        Icons.location_city,
                      ),
                      detailRow(
                        "Data wydarzenia",
                        eventDateWithDay(event),
                        Icons.calendar_month,
                      ),
                      if (eventDaysUntil(event).isNotEmpty)
                        detailRow(
                          "Czas do wydarzenia",
                          eventDaysUntil(event),
                          Icons.hourglass_bottom,
                        ),
                      detailRow(
                        "Miejsce",
                        event["club"] ?? "",
                        Icons.apartment,
                      ),
                      detailRow(
                        "Gatunek muzyki",
                        musicType,
                        Icons.music_note,
                      ),
                      detailRow(
                        "Źródło informacji",
                        eventSourceName(event),
                        Icons.confirmation_number,
                      ),
                      if (sourceUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Text(
                            "To wydarzenie pochodzi z Ticketmastera. Kliknij poniżej, aby przejść do strony wydarzenia i sprawdzić bilety.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.66),
                              height: 1.35,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => addToMyList(context),
                          icon: const Icon(Icons.favorite),
                          label: const Text("Dodaj do moich wydarzeń"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: sourceUrl.isEmpty
                              ? null
                              : () => openTicketLink(context),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Kup / zobacz bilety"),
                        ),
                      ),
                      if (isAdmin) const SizedBox(height: 20),
                      if (isAdmin)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await onEdit();

                                  if (!context.mounted) return;

                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Edytuj"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await onDelete();

                                  if (!context.mounted) return;

                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text("Usuń"),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}