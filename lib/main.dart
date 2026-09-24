import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triplay/games/reaction_game.dart';
import 'package:triplay/games/pattern_memory.dart';
import 'package:triplay/games/checkers.dart';
import 'package:triplay/games/chess.dart';
import 'package:triplay/games/minesweeper.dart';
import 'package:triplay/games/snake.dart';
import 'package:triplay/games/memory_match.dart';
import 'package:triplay/games/twenty_forty_eight.dart';
import 'package:triplay/games/connect_four.dart';
import 'package:triplay/games/tic_tac_toe.dart';
import 'package:triplay/games/ping_pong.dart';
import 'package:triplay/games/brick_breaker.dart';
import 'package:triplay/games/neon_flight.dart';
import 'package:triplay/games/sliding_puzzle.dart';
import 'package:triplay/games/color_match.dart';
import 'package:triplay/games/omo_game.dart';
import 'package:triplay/games/pker.dart';
import 'package:triplay/games/sudoku.dart';
import 'package:triplay/games/globe_capture.dart';
import 'package:triplay/stats_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Triplay Games',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);

    _fadeController.forward();
    _scaleController.forward();

    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IntroWrapper()));
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'lib/assests/triplay.png',
                      height: 120,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'TRIPLAY',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                        letterSpacing: 8,
                        shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 30)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'THE THEATRE OF GAMES',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.cyanAccent.withOpacity(0.5),
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '© 23HREE',
                style: TextStyle(
                  color: Colors.white10,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroWrapper extends StatefulWidget {
  const IntroWrapper({super.key});

  @override
  State<IntroWrapper> createState() => _IntroWrapperState();
}

class _IntroWrapperState extends State<IntroWrapper> {
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name');
      isLoading = false;
    });
  }

  Future<void> _saveUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      userName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1E),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    if (userName == null) {
      return IntroScreen(onNameEntered: _saveUser);
    }
    return MainHomeScreen(userName: userName!);
  }
}

class IntroScreen extends StatelessWidget {
  final Function(String) onNameEntered;
  final TextEditingController _controller = TextEditingController();

  IntroScreen({super.key, required this.onNameEntered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'WELCOME TO TRIPLAY ARCADE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'WHAT IS YOUR NAME?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ENTER NAME',
                  hintStyle: TextStyle(color: Colors.cyanAccent.withOpacity(0.3)),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) onNameEntered(val.trim());
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    onNameEntered(_controller.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('START', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  final String userName;
  const MainHomeScreen({super.key, required this.userName});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int dailyPlayed = 0;
  int dailyWins = 0;
  String favoriteGame = 'None';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final dailyStats = await StatsManager().getDailyStats();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dailyPlayed = dailyStats['played'] ?? 0;
      dailyWins = dailyStats['wins'] ?? 0;
      favoriteGame = prefs.getString('fav_game') ?? 'None';
    });
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'GOOD MORNING';
    if (hour >= 12 && hour < 17) return 'GOOD AFTERNOON';
    if (hour >= 17 && hour < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, ${widget.userName.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatsSection(),
                  const SizedBox(height: 30),
                  const Text(
                    'GAMING ARCADE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          _buildGameGrid(context),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1E),
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset('lib/assests/triplay.png'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) => _loadStats());
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'TRIPLAY ARCADE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: Colors.cyanAccent,
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.cyanAccent.withOpacity(0.1),
                const Color(0xFF0F0F1E),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _statCard('PLAYED', dailyPlayed.toString(), Icons.play_arrow)),
        const SizedBox(width: 15),
        Expanded(child: _statCard('WINS', dailyWins.toString(), Icons.emoji_events)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    final List<Map<String, dynamic>> games = [
      {'name': 'NEON SNAKE', 'icon': Icons.lens_blur, 'color': Colors.greenAccent, 'page': const SnakeGame()},
      {'name': 'NEON MATCH', 'icon': Icons.extension, 'color': Colors.cyanAccent, 'page': const MemoryMatchGame()},
      {'name': 'CHECKERS', 'icon': Icons.grid_4x4, 'color': Colors.orangeAccent, 'page': const CheckersGame()},
      {'name': 'CHESS', 'icon': Icons.castle, 'color': Colors.purpleAccent, 'page': const ChessGame()},
      {'name': 'STREET POKER 🃏', 'icon': Icons.style, 'color': Colors.pinkAccent, 'page': const PkerGame()},
      {'name': 'NEON PONG', 'icon': Icons.sports_tennis, 'color': Colors.cyanAccent, 'page': const PingPongGame()},
      {'name': 'MINESWEEPER', 'icon': Icons.dangerous, 'color': Colors.redAccent, 'page': const MinesweeperGame()},
      {'name': '2048', 'icon': Icons.grid_view, 'color': Colors.yellowAccent, 'page': const TwentyFortyEightGame()},
      {'name': 'TIC TAC TOE', 'icon': Icons.grid_3x3, 'color': Colors.cyanAccent, 'page': const TicTacToeMenu()},
      {'name': 'STREET CONNECT', 'icon': Icons.blur_circular, 'color': Colors.cyanAccent, 'page': const ConnectFourGame()},
      {'name': 'REACTION', 'icon': Icons.speed, 'color': Colors.pinkAccent, 'page': const ReactionGame()},
      {'name': 'PATTERN', 'icon': Icons.memory, 'color': Colors.tealAccent, 'page': const PatternMemoryGame()},
      {'name': 'NEON SUDOKU', 'icon': Icons.grid_on, 'color': Colors.cyanAccent, 'page': const SudokuGame()},
      {'name': 'GLOBE CAPTURE', 'icon': Icons.public, 'color': Colors.amberAccent, 'page': const GlobeCaptureGame()},
      {'name': 'BRICK BREAKER', 'icon': Icons.grid_view_rounded, 'color': Colors.orangeAccent, 'page': const BrickBreakerGame()},
      {'name': 'NEON FLIGHT', 'icon': Icons.airplanemode_active, 'color': Colors.blueAccent, 'page': const NeonFlightGame()},
      {'name': 'SLIDING PUZZLE', 'icon': Icons.extension_rounded, 'color': Colors.tealAccent, 'page': const SlidingPuzzleGame()},
      {'name': 'COLOR DASH', 'icon': Icons.palette_rounded, 'color': Colors.pinkAccent, 'page': const ColorMatchGame()},
      {'name': 'OMO CHALLENGE', 'icon': Icons.abc_rounded, 'color': Colors.amberAccent, 'page': const OMOGame()},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = games[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => game['page']),
                ).then((_) => _loadStats());
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: game['color'].withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(game['icon'], size: 40, color: game['color']),
                    const SizedBox(height: 10),
                    Text(
                      game['name'],
                      style: TextStyle(
                        color: game['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: games.length,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsTile(Icons.delete_outline, 'CLEAR DATA', 'Reset all game progress', () async {
            await StatsManager().resetAll();
            if (context.mounted) Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: const Color(0xFF1A1A2E),
    );
  }
}
