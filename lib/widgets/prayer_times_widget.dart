import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({super.key, PrayerTimes? PrayerTimes});

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Prayer time calculation variables
  Coordinates? _userCoordinates;
  late CalculationParameters _params;
  PrayerTimes? _authenticPrayerTimes;
  String? _currentPrayer;
  String? _nextPrayer;
  Duration? _timeUntilNextPrayer;

  // Green gradient color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initPrayerTimes();
    _determinePosition();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Location Services ---
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userCoordinates = Coordinates(position.latitude, position.longitude);
    });
    _calculateAuthenticPrayerTimes();
  }

  // --- Authentic Prayer Time Calculation ---
  void _initPrayerTimes() {
    _params = CalculationMethod.karachi.getParameters();
    _params.madhab = Madhab.hanafi;
  }

  void _calculateAuthenticPrayerTimes() {
    if (_userCoordinates == null) return;

    setState(() {
      _authenticPrayerTimes = PrayerTimes(
        _userCoordinates!,
        DateComponents(DateTime.now().year, DateTime.now().month, DateTime.now().day),
        _params,
      );
    });
    _updatePrayerTimer();
  }

  void _updatePrayerTimer() {
    if (_authenticPrayerTimes == null) return;

    final now = DateTime.now();
    final currentPrayerEnum = _authenticPrayerTimes!.currentPrayer();
    final nextPrayerEnum = _authenticPrayerTimes!.nextPrayer();

    _currentPrayer = currentPrayerEnum.name;
    _nextPrayer = nextPrayerEnum.name;

    DateTime? nextPrayerTime;
    switch (_nextPrayer) {
      case 'Fajr':
        nextPrayerTime = _authenticPrayerTimes!.fajr;
        break;
      case 'Dhuhr':
        nextPrayerTime = _authenticPrayerTimes!.dhuhr;
        break;
      case 'Asr':
        nextPrayerTime = _authenticPrayerTimes!.asr;
        break;
      case 'Maghrib':
        nextPrayerTime = _authenticPrayerTimes!.maghrib;
        break;
      case 'Isha':
        nextPrayerTime = _authenticPrayerTimes!.isha;
        break;
    }

    if (nextPrayerTime != null) {
      _timeUntilNextPrayer = nextPrayerTime.difference(now);
      if (_timeUntilNextPrayer!.isNegative) {
        nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
        _timeUntilNextPrayer = nextPrayerTime.difference(now);
      }
    } else {
      _timeUntilNextPrayer = null;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFF1F8E9),
              Color(0xFFE8F5E8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: lightGreen.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_authenticPrayerTimes != null) ...[
                _buildCurrentPrayerSection(),
                const SizedBox(height: 16),
                _buildNextPrayerSection(),
                const SizedBox(height: 20),
                _buildAllPrayerTimes(),
              ] else
                _buildLoadingState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, secondaryGreen],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prayer Times',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              Text(
                'Based on your location',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: primaryGreen.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPrayerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withOpacity(0.1),
            secondaryGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Prayer',
                  style: TextStyle(
                    color: primaryGreen.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentPrayer ?? 'N/A',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentGreen.withOpacity(0.1),
            lightGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Prayer',
                      style: TextStyle(
                        color: primaryGreen.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _nextPrayer ?? 'N/A',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_timeUntilNextPrayer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: accentGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Time remaining: ${_timeUntilNextPrayer!.inHours}h ${_timeUntilNextPrayer!.inMinutes.remainder(60)}m',
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllPrayerTimes() {
    final prayers = [
      {'name': 'Fajr', 'time': _authenticPrayerTimes!.fajr, 'icon': Icons.wb_twilight},
      {'name': 'Dhuhr', 'time': _authenticPrayerTimes!.dhuhr, 'icon': Icons.wb_sunny},
      {'name': 'Asr', 'time': _authenticPrayerTimes!.asr, 'icon': Icons.wb_sunny_outlined},
      {'name': 'Maghrib', 'time': _authenticPrayerTimes!.maghrib, 'icon': Icons.wb_twilight},
      {'name': 'Isha', 'time': _authenticPrayerTimes!.isha, 'icon': Icons.nightlight_round},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Prayer Times',
          style: TextStyle(
            color: darkGreen,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...prayers.map((prayer) => _buildPrayerTimeRow(
          prayer['name'] as String,
          prayer['time'] as DateTime,
          prayer['icon'] as IconData,
        )).toList(),
      ],
    );
  }

  Widget _buildPrayerTimeRow(String name, DateTime time, IconData icon) {
    final isCurrentPrayer = _currentPrayer == name;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentPrayer
              ? [primaryGreen.withOpacity(0.15), secondaryGreen.withOpacity(0.1)]
              : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentPrayer
              ? primaryGreen.withOpacity(0.3)
              : lightGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCurrentPrayer ? primaryGreen : lightGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: isCurrentPrayer ? Colors.white : primaryGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isCurrentPrayer ? darkGreen : primaryGreen.withOpacity(0.8),
                fontSize: 14,
                fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentPrayer
                  ? primaryGreen.withOpacity(0.1)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeString,
              style: TextStyle(
                color: darkGreen,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Calculating authentic prayer times...',
            style: TextStyle(
              color: primaryGreen.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
