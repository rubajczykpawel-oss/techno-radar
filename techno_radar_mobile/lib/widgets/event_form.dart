import 'package:flutter/material.dart';
import '../widgets/music_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/event_image.dart';

class EventForm extends StatelessWidget {
  final String title;
  final String buttonText;

  final TextEditingController name;
  final TextEditingController city;
  final TextEditingController date;
  final TextEditingController club;
  final TextEditingController musicType;
  final TextEditingController imageUrl;

  final VoidCallback onPressed;
  final VoidCallback onPickImage;
  final bool uploadingImage;

  const EventForm({
    super.key,
    required this.title,
    required this.buttonText,
    required this.name,
    required this.city,
    required this.date,
    required this.club,
    required this.musicType,
    required this.imageUrl,
    required this.onPressed,
    required this.onPickImage,
    required this.uploadingImage,
  });

  Future<void> chooseDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selectedDate != null) {
      date.text =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    const musicTypes = [
      "Techno",
      "Hard Techno",
      "Acid Techno",
      "Minimal",
      "Industrial Techno",
      "House",
      "Tech House",
      "Deep House",
      "Trance",
      "Psytrance",
      "Drum and Bass",
      "Dubstep",
      "EDM",
      "Rave",
      "Electronic",
    ];

    String? selectedMusicType;

    if (musicType.text.isNotEmpty && musicTypes.contains(musicType.text)) {
      selectedMusicType = musicType.text;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: MusicBackground(
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(18),
            child: GlassPanel(
              padding: const EdgeInsets.all(22),
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: "Nazwa wydarzenia",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(
                      labelText: "Miasto",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: date,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Data wydarzenia",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () => chooseDate(context),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: club,
                    decoration: const InputDecoration(
                      labelText: "Miejsce / klub",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMusicType,
                    decoration: const InputDecoration(
                      labelText: "Gatunek muzyki",
                    ),
                    items: musicTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type == "Electronic" ? "Muzyka elektroniczna" : type,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      musicType.text = value ?? "";
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrl,
                    decoration: const InputDecoration(
                      labelText: "Link do zdjęcia / grafiki",
                      hintText: "Możesz wkleić link albo wybrać plik",
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: uploadingImage ? null : onPickImage,
                      icon: uploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        uploadingImage
                            ? "Wysyłanie zdjęcia..."
                            : "Wybierz zdjęcie",
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  eventImage(imageUrl.text, height: 170),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: uploadingImage ? null : onPressed,
                      child: Text(buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
