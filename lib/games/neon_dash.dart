import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class NeonDashGame extends StatefulWidget {
  const NeonDashGame({super.key});

  @override
  State<NeonDashGame> createState() => _NeonDashGameState();
}

class _NeonDashGameState extends State<NeonDashGame> {
  // Game state
  double playerY = 0;
  double playerVelocity = 0;
  double gravity = 0.002;
  double jumpStrength = -0.05;
  
  bool isPlaying = false;
  bool gameOver = false;
  int score = 0;
  
  List<Obstacle> obstacles = [];
  Timer? gameTimer;
  double gameSpeed = 0.015;

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      playerY = 0;
      playerVelocity = 0;
      isPlaying = true;
      gameOver = false;
      score = 0;
      obstacles = [];
      gameSpeed = 0.015;
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _update();
    });
  }

  void _update() {
    setState(() {
      // Physics
      playerVelocity += gravity;
      playerY += playerVelocity;

      // Floor and Ceiling
      if (playerY > 0.8) {
        playerY = 0.8;
        playerVelocity = 0;
      }
      if (playerY < -0.8) {
        playerY = -0.8;
        playerVelocity = 0;
      }

      // Move obstacles
      for (var obs in obstacles) {
        obs.x -= gameSpeed;
      }

      // Add obstacles
      if (obstacles.isEmpty || obstacles.last.x < 0.5) {
        obstacles.add(Obstacle(
          x: 1.2,
          y: Random().nextBool() ? 0.8 : -0.8,
          isTop: Random().nextBool(),
        ));
      }

      // Check collisions
      for (var obs in obstacles) {
        if (obs.x < 0.1 && obs.x > -0.1) {
          double obsY = obs.isTop ? -0.8 : 0.8;
          if ((playerY - obsY).abs() < 0.2) {
            _endGame();
          }
        }
      }

      // Score and cleanup
      obstacles.removeWhere((obs) {
        if (obs.x < -1.2) {
          score++;
          gameSpeed += 0.0001; // Increase speed
          return true;
        }
        return false;
      });
    });
  }

  void _jump() {
    if (!isPlaying) return;
    setState(() {
      playerVelocity = jumpStrength * (playerY > 0 ? 1 : -1);
    });
    HapticFeedback.lightImpact();
  }

  void _endGame() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = true;
    });
    StatsManager().recordGamePlay("NEON DASH");
    if (score > 15) StatsManager().recordWin();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON DASH', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: _jump,
        child: Column(
          children: [
            _buildScoreBoard(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Tracks
                      _buildTrack(-0.8),
                      _buildTrack(0.8),
                      
                      // Player
                      Align(
                        alignment: Alignment(0, playerY),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 15)],
                          ),
                        ),
                      ),
                      
                      // Obstacles
                      ...obstacles.map((obs) => Align(
                        alignment: Alignment(obs.x, obs.isTop ? -0.8 : 0.8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 10)],
                          ),
                        ),
                      )),
                      
                      if (!isPlaying) _buildOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text("TAP TO SWITCH SIDES", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrack(double y) {
    return Align(
      alignment: Alignment(0, y),
      child: Container(
        height: 2,
        width: double.infinity,
        color: Colors.white10,
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text("DASH SCORE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text(score.toString(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 48, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gameOver)
              const Text(
                "DASH INTERRUPTED",
                style: TextStyle(color: Colors.pinkAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(gameOver ? "REBOOT DASH" : "START DASH"),
            ),
          ],
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;
  bool isTop;
  Obstacle({required this.x, required this.y, required this.isTop});
}
