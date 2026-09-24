import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class NeonFlightGame extends StatefulWidget {
  const NeonFlightGame({super.key});

  @override
  State<NeonFlightGame> createState() => _NeonFlightGameState();
}

class _NeonFlightGameState extends State<NeonFlightGame> {
  // Game state
  double birdY = 0;
  double time = 0;
  double height = 0;
  double initialHeight = 0;
  bool gameStarted = false;
  bool gameOver = false;
  int score = 0;
  int highscore = 0;
  int currentLevel = 1;
  bool passedBarrier1 = false;
  bool passedBarrier2 = false;

  // Obstacle state
  static double barrierX1 = 1.5;
  static double barrierX2 = barrierX1 + 1.5;
  double barrierWidth = 0.3;
  double barrierGap = 0.55; 
  List<double> barrierHeights = [0.1, 0.4]; // Y alignment centers for gaps

  void jump() {
    if (gameOver) return;
    setState(() {
      time = 0;
      initialHeight = birdY;
    });
    HapticFeedback.lightImpact();
  }

  void startGame() {
    gameStarted = true;
    gameOver = false;
    score = 0;
    birdY = 0;
    time = 0;
    initialHeight = 0;
    barrierX1 = 1.5;
    barrierX2 = barrierX1 + 1.5;
    passedBarrier1 = false;
    passedBarrier2 = false;
    
    // Scale speed and gap with level
    double speedScale = 0.03 + (currentLevel - 1) * 0.005;
    double gapScale = (0.55 - (currentLevel - 1) * 0.02).clamp(0.35, 0.55);
    setState(() {
      barrierGap = gapScale;
    });

    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      time += 0.035;
      height = -4.9 * time * time + 2.5 * time;
      setState(() {
        birdY = (initialHeight - height).clamp(-1.1, 1.1);
      });

      // Move barriers
      setState(() {
        barrierX1 -= speedScale;
        barrierX2 -= speedScale;

        if (barrierX1 < -1.5) {
          barrierX1 = 1.5;
          barrierHeights[0] = (Random().nextDouble() * 1.2) - 0.6; // Random gap center
          passedBarrier1 = false;
        }

        if (barrierX2 < -1.5) {
          barrierX2 = 1.5;
          barrierHeights[1] = (Random().nextDouble() * 1.2) - 0.6;
          passedBarrier2 = false;
        }
      });

      // Check collision
      if (birdY >= 1.0 || birdY <= -1.0 || _checkCollision()) {
        timer.cancel();
        _endGame();
      }

      // Update score and check for level up
      if (!passedBarrier1 && barrierX1 < 0) {
        setState(() {
          score++;
          passedBarrier1 = true;
          if (score % 10 == 0) {
            currentLevel++;
            HapticFeedback.mediumImpact();
          }
        });
      }
      if (!passedBarrier2 && barrierX2 < 0) {
        setState(() {
          score++;
          passedBarrier2 = true;
          if (score % 10 == 0) {
            currentLevel++;
            HapticFeedback.mediumImpact();
          }
        });
      }
    });
  }

  bool _checkCollision() {
    // Collision logic for barrier 1
    if (barrierX1 < 0.15 && barrierX1 > -0.15) {
      if (birdY < barrierHeights[0] - barrierGap / 2 || birdY > barrierHeights[0] + barrierGap / 2) {
        return true;
      }
    }
    // Collision logic for barrier 2
    if (barrierX2 < 0.15 && barrierX2 > -0.15) {
      if (birdY < barrierHeights[1] - barrierGap / 2 || birdY > barrierHeights[1] + barrierGap / 2) {
        return true;
      }
    }
    return false;
  }

  void _endGame() {
    setState(() {
      gameStarted = false;
      gameOver = true;
    });
    StatsManager().recordGamePlay("NEON FLIGHT");
    if (score > 10) StatsManager().recordWin();
    HapticFeedback.heavyImpact();
  }

  void resetGame() {
    setState(() {
      birdY = 0;
      gameStarted = false;
      gameOver = false;
      time = 0;
      initialHeight = 0;
      barrierX1 = 1.5;
      barrierX2 = barrierX1 + 1.5;
      score = 0;
      currentLevel = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: GestureDetector(
        onTap: () {
          if (gameStarted) {
            jump();
          } else if (!gameOver) {
            startGame();
          }
        },
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF0F0F1E), Colors.cyanAccent.withOpacity(0.05)],
                      ),
                    ),
                  ),
                  // Bird
                  AnimatedContainer(
                    alignment: Alignment(0, birdY),
                    duration: const Duration(milliseconds: 0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.airplanemode_active, color: Colors.black, size: 24),
                    ),
                  ),
                  // Barriers
                  _buildBarrier(barrierX1, barrierHeights[0], true),
                  _buildBarrier(barrierX1, barrierHeights[0], false),
                  _buildBarrier(barrierX2, barrierHeights[1], true),
                  _buildBarrier(barrierX2, barrierHeights[1], false),

                  // Score
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        score.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, letterSpacing: 4),
                      ),
                    ),
                  ),
                  // Instructions/GameOver
                  if (!gameStarted) _buildOverlay(),
                  
                  // Back button
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // About button
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white54),
                      onPressed: _showAbout,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 15,
              color: Colors.pinkAccent,
            ),
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFF1A1A2E),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem("LEVEL", currentLevel.toString(), Colors.yellowAccent),
                      _statItem("SCORE", score.toString(), Colors.cyanAccent),
                      _statItem("HIGH", highscore.toString(), Colors.pinkAccent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarrier(double x, double gapCenter, bool isTop) {
    double barrierHeight = 1.0 - (barrierGap / 2) + (isTop ? gapCenter : -gapCenter);
    
    return AnimatedContainer(
      alignment: Alignment(x, isTop ? -1.1 : 1.1),
      duration: const Duration(milliseconds: 0),
      child: Container(
        width: MediaQuery.of(context).size.width * barrierWidth / 2,
        height: MediaQuery.of(context).size.height * 3 / 4 * (barrierHeight / 2),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withOpacity(0.8),
          border: Border.all(color: Colors.pinkAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10)],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT NEON FLIGHT", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "Pilot your craft through the system barriers. Tap to gain altitude. Don't crash into the pink walls or the floor/ceiling.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gameOver)
            const Text(
              "SYSTEM CRASHED",
              style: TextStyle(color: Colors.pinkAccent, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: gameOver ? resetGame : startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(gameOver ? "REBOOT" : "INITIALIZE FLIGHT", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (!gameOver)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("TAP TO GAIN ALTITUDE", style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 2)),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
