// screens/representative/masjid_event_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming the following services and widgets are in their respective files.
// For a standalone example, we can mock them.
import 'package:namaz_clock_app/services/firestore_service.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';


// AppColors class from masjid_representative_screen.dart
class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
}

// A mock FirestoreService for this example
class MockFirestoreService {
  Future<List<Map<String, dynamic>>> getMasjidEvents(String masjidId) async {
    // Mocking a successful API call with some dummy data
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'eventName': 'Weekly Quranic Circle',
        'description': 'Join us for a weekly study of the Quran.',
        'dateTime': '21-08-2025 19:00',
        'day': 'Wednesday',
      },
      {
        'eventName': 'Community Iftar',
        'description': 'Breaking fast together during Ramadan.',
        'dateTime': '28-08-2025 18:30',
        'day': 'Wednesday',
      },
    ];
  }

  Future<void> addMasjidEvent({
    required String masjidId,
    required String eventName,
    required String description,
    required String dateTime,
    required String day,
  }) async {
    // Mocking adding an event
    await Future.delayed(const Duration(milliseconds: 500));
    print('Event added: $eventName');
  }
}

class MasjidEventScreen extends StatefulWidget {
  const MasjidEventScreen({super.key});

  @override
  State<MasjidEventScreen> createState() => _MasjidEventScreenState();
}

class _MasjidEventScreenState extends State<MasjidEventScreen> {
  // Event Management Controllers
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventDayController = TextEditingController();
  final GlobalKey<FormState> _eventFormKey = GlobalKey<FormState>();

  // Mocking the services and data from the parent screen
  final MockFirestoreService _firestoreService = MockFirestoreService();
  String? _userMasjidId = 'mock_masjid_id';
  bool _isAddingEvent = false;
  List<Map<String, dynamic>> _masjidEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchMasjidEvents();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventDateController.dispose();
    _eventDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchMasjidEvents() async {
    if (_userMasjidId == null) return;
    try {
      final events = await _firestoreService.getMasjidEvents(_userMasjidId!);
      if (mounted) {
        setState(() {
          _masjidEvents = events;
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGreen,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryGreen,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.darkGreen,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final formattedDate = DateFormat(
          'dd-MM-yyyy HH:mm',
        ).format(selectedDateTime);
        final formattedDay = DateFormat('EEEE').format(selectedDateTime);
        controller.text = formattedDate;
        _eventDayController.text = formattedDay;
      }
    }
  }

  Future<void> _addMasjidEvent() async {
    if (_eventFormKey.currentState!.validate() && _userMasjidId != null) {
      setState(() {
        _isAddingEvent = true;
      });

      try {
        await _firestoreService.addMasjidEvent(
          masjidId: _userMasjidId!,
          eventName: _eventNameController.text,
          description: _eventDescriptionController.text,
          dateTime: _eventDateController.text,
          day: _eventDayController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added successfully!')),
          );
          _eventNameController.clear();
          _eventDescriptionController.clear();
          _eventDateController.clear();
          _eventDayController.clear();
          await _fetchMasjidEvents(); // Refresh the list
        }
      } catch (e) {
        print('Error adding event: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add event: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAddingEvent = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Events'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Management Card (Form to add new events)
            EventManagementCard(
              formKey: _eventFormKey,
              eventNameController: _eventNameController,
              eventDescriptionController: _eventDescriptionController,
              eventDateController: _eventDateController,
              eventDayController: _eventDayController,
              onSelectDate: _selectDate,
              onAddEvent: _addMasjidEvent,
              isAddingEvent: _isAddingEvent,
              // Assuming a fade animation is not needed for a simple screen
              fadeAnimation: const AlwaysStoppedAnimation<double>(1.0),
            ),
            const SizedBox(height: 30),
            // Event List Card (Displays existing events)
            EventListCard(
              events: _masjidEvents,
              // Assuming a fade animation is not needed for a simple screen
              fadeAnimation: const AlwaysStoppedAnimation<double>(1.0),
            ),
          ],
        ),
      ),
    );
  }
}

// Below are mock widgets to make the code runnable as a standalone example.
// In a real application, you would import these from your widgets folder.

class EventManagementCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController eventNameController;
  final TextEditingController eventDescriptionController;
  final TextEditingController eventDateController;
  final TextEditingController eventDayController;
  final Future<void> Function(TextEditingController) onSelectDate;
  final Future<void> Function() onAddEvent;
  final bool isAddingEvent;
  final Animation<double> fadeAnimation;

  const EventManagementCard({
    super.key,
    required this.formKey,
    required this.eventNameController,
    required this.eventDescriptionController,
    required this.eventDateController,
    required this.eventDayController,
    required this.onSelectDate,
    required this.onAddEvent,
    required this.isAddingEvent,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Event',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: eventNameController,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an event name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: eventDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: eventDateController,
                  readOnly: true,
                  onTap: () => onSelectDate(eventDateController),
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date and time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAddingEvent ? null : onAddEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isAddingEvent
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))
                        : const Text('Add Event'),
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

class EventListCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Animation<double> fadeAnimation;

  const EventListCard({
    super.key,
    required this.events,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 16),
              if (events.isEmpty)
                const Center(
                  child: Text(
                    'No upcoming events.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(
                        event['eventName']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${event['day']}, ${event['dateTime']}',
                      ),
                      trailing: const Icon(
                        Icons.event,
                        color: AppColors.primaryGreen,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}