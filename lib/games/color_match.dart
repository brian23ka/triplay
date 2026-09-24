import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class ColorMatchGame extends StatefulWidget {
  const ColorMatchGame({super.key});

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame> {
  final List<Map<String, dynamic>> colorPool = [
    {'name': 'CYAN', 'color': Colors.cyanAccent},
    {'name': 'PINK', 'color': Colors.pinkAccent},
    {'name': 'GREEN', 'color': Colors.greenAccent},
    {'name': 'ORANGE', 'color': Colors.orangeAccent},
    {'name': 'PURPLE', 'color': Colors.purpleAccent},
    {'name': 'YELLOW', 'color': Colors.yellowAccent},
  ];

  late String targetText;
  late Color targetColor;
  late List<Color> options;
  
  int score = 0;
  int timeLeft = 30;
  bool isPlaying = false;
  bool gameOver = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    targetText = "";
    targetColor = Colors.white;
    options = [];
  }

  void _startGame() {
    setState(() {
      score = 0;
      timeLeft = 30;
      isPlaying = true;
      gameOver = false;
      _nextRound();
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _nextRound() {
    final random = Random();
    var textData = colorPool[random.nextInt(colorPool.length)];
    var colorData = colorPool[random.nextInt(colorPool.length)];

    setState(() {
      targetText = textData['name'];
      targetColor = colorData['color'];
      
      options = colorPool.map<Color>((e) => e['color'] as Color).toList();
      options.shuffle();
    });
  }

  void _handleOptionTap(Color selectedColor) {
    if (!isPlaying) return;

    if (selectedColor == targetColor) {
      setState(() {
        score += 10;
        HapticFeedback.lightImpact();
        _nextRound();
      });
    } else {
      setState(() {
        score = max(0, score - 5);
        HapticFeedback.vibrate();
        _nextRound();
      });
    }
  }

  void _endGame() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = true;
    });
    StatsManager().recordGamePlay("COLOR DASH");
    if (score > 100) StatsManager().recordWin();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('COLOR DASH', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            onPressed: _showAbout,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const Spacer(),
          if (isPlaying) _buildGameArea(),
          if (!isPlaying) _buildStartArea(),
          const Spacer(),
          if (isPlaying) _buildOptions(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("SCORE", score.toString(), Colors.cyanAccent),
          _statItem("TIME", "${timeLeft}s", Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGameArea() {
    return Center(
      child: Column(
        children: [
          const Text("SELECT THE ACTUAL COLOR", style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 20),
          Text(
            targetText,
            style: TextStyle(
              color: targetColor,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: targetColor, blurRadius: 20)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartArea() {
    return Center(
      child: Column(
        children: [
          if (gameOver)
            Text(
              "SYNC TERMINATED",
              style: TextStyle(color: Colors.pinkAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 10)]),
            ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(gameOver ? "REBOOT" : "INITIALIZE"),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: options.map((c) {
          return GestureDetector(
            onTap: () => _handleOptionTap(c),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: c.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: c, width: 3),
                boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 15)],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT COLOR DASH", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "Test your focus! The word displayed might be 'RED' but it could be colored BLUE. Your goal is to select the circle that matches the COLOR of the word, not what the word says.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}
