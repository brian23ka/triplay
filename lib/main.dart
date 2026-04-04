import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'games/tic_tac_toe.dart';
import 'games/reaction_game.dart';
import 'games/number_guess.dart';
import 'games/pattern_memory.dart';
import 'games/checkers.dart';
import 'games/chess.dart';

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
                'SYSTEM INITIALIZATION',
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
                child: const Text('INITIALIZE SYSTEM', style: TextStyle(fontWeight: FontWeight.bold)),
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
  int totalGamesPlayed = 0;
  int totalWins = 0;
  String favoriteGame = 'None';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalGamesPlayed = prefs.getInt('total_played') ?? 0;
      totalWins = prefs.getInt('total_wins') ?? 0;
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
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'TRIPLAY NEON',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('PLAYED', totalGamesPlayed.toString(), Colors.white),
              _buildStatItem('WINS', totalWins.toString(), Colors.cyanAccent),
              _buildStatItem('RATIO', totalGamesPlayed == 0 ? '0%' : '${((totalWins / totalGamesPlayed) * 100).toStringAsFixed(0)}%', Colors.greenAccent),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white10),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 10),
              Text(
                'FAVORITE: $favoriteGame',
                style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    final List<Map<String, dynamic>> games = [
      {
        'title': 'TIC TAC TOE',
        'subtitle': 'Classic & Ultimate',
        'icon': Icons.grid_3x3,
        'color': Colors.blueAccent,
        'game': const TicTacToeMenu(),
      },
      {
        'title': 'REACTION',
        'subtitle': 'Speed & F1',
        'icon': Icons.bolt,
        'color': Colors.orangeAccent,
        'game': const ReactionGame(),
      },
      {
        'title': 'GUESS MASTER',
        'subtitle': 'Number Mystery',
        'icon': Icons.question_mark,
        'color': Colors.greenAccent,
        'game': const NumberGuessGame(),
      },
      {
        'title': 'SEQUENCE',
        'subtitle': 'Memory Challenge',
        'icon': Icons.psychology,
        'color': Colors.purpleAccent,
        'game': const PatternMemoryGame(),
      },
      {
        'title': 'CHECKERS',
        'subtitle': 'Strategy Board',
        'icon': Icons.adjust,
        'color': Colors.cyanAccent,
        'game': const CheckersGame(),
      },
      {
        'title': 'CHESS',
        'subtitle': 'The Ultimate Game',
        'icon': Icons.fort,
        'color': Colors.pinkAccent,
        'game': const ChessGame(),
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = games[index];
            return _buildFeaturedGameCard(
              context,
              game['title'],
              game['subtitle'],
              game['icon'],
              game['color'],
              game['game'],
            );
          },
          childCount: games.length,
        ),
      ),
    );
  }

  Widget _buildFeaturedGameCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget gameWidget) {
    return InkWell(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        int currentPlayed = prefs.getInt('total_played') ?? 0;
        await prefs.setInt('total_played', currentPlayed + 1);
        
        // Track per-game play for favorite logic
        int gamePlayed = prefs.getInt('played_$title') ?? 0;
        await prefs.setInt('played_$title', gamePlayed + 1);
        
        // Update favorite game
        List<String> gameTitles = ['TIC TAC TOE', 'REACTION', 'GUESS MASTER', 'SEQUENCE', 'CHECKERS', 'CHESS'];
        String fav = title;
        int max = gamePlayed + 1;
        for(var t in gameTitles) {
          int count = prefs.getInt('played_$t') ?? 0;
          if(count > max) {
            max = count;
            fav = t;
          }
        }
        await prefs.setString('fav_game', fav);

        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => gameWidget)).then((_) => _loadStats());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/254116921099");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ABOUT TRIPLAY NEON',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
              ),
              child: const Text(
                'Triplay Neon is a futuristic gaming hub designed for high-end mobile experiences. Featuring classic logic games and fast-paced reaction tests with advanced AI and local multiplayer support.',
                style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'CREATOR',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _launchWhatsApp,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.message, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEET THE CREATOR',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Chat on WhatsApp',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'VERSION 1.0.0',
                style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
