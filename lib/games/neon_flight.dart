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

  // Obstacle state
  static double barrierX1 = 1;
  static double barrierX2 = barrierX1 + 1.5;
  double barrierWidth = 0.4;
  List<double> barrierHeights = [0.6, 0.4, 0.5, 0.3]; // Heights for top barriers

  void jump() {
    setState(() {
      time = 0;
      initialHeight = birdY;
    });
    HapticFeedback.lightImpact();
  }

  void startGame() {
    gameStarted = true;
    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      time += 0.05;
      height = -4.9 * time * time + 2.8 * time;
      setState(() {
        birdY = initialHeight - height;
      });

      // Move barriers
      setState(() {
        if (barrierX1 < -2) {
          barrierX1 += 3;
          barrierHeights[0] = (Random().nextInt(5) + 2) / 10;
        } else {
          barrierX1 -= 0.05;
        }

        if (barrierX2 < -2) {
          barrierX2 += 3;
          barrierHeights[1] = (Random().nextInt(5) + 2) / 10;
        } else {
          barrierX2 -= 0.05;
        }
      });

      // Check collision
      if (birdY > 1 || birdY < -1 || _checkCollision()) {
        timer.cancel();
        _endGame();
      }

      // Update score
      if (barrierX1 < -0.2 && barrierX1 > -0.25 || barrierX2 < -0.2 && barrierX2 > -0.25) {
        setState(() {
          score++;
        });
      }
    });
  }

  bool _checkCollision() {
    // Collision logic for barriers
    if (barrierX1 < 0.2 && barrierX1 > -0.2) {
      if (birdY < -1 + barrierHeights[0] || birdY > -1 + barrierHeights[0] + 0.4) {
        return true;
      }
    }
    if (barrierX2 < 0.2 && barrierX2 > -0.2) {
      if (birdY < -1 + barrierHeights[1] || birdY > -1 + barrierHeights[1] + 0.4) {
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
      barrierX1 = 1;
      barrierX2 = barrierX1 + 1.5;
      score = 0;
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
                  _buildBarrier(barrierX1, 1 - barrierHeights[0] - 0.4, false),
                  _buildBarrier(barrierX2, barrierHeights[1], true),
                  _buildBarrier(barrierX2, 1 - barrierHeights[1] - 0.4, false),

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

  Widget _buildBarrier(double x, double h, bool isTop) {
    return AnimatedContainer(
      alignment: Alignment(x, isTop ? -1.1 : 1.1),
      duration: const Duration(milliseconds: 0),
      child: Container(
        width: MediaQuery.of(context).size.width * barrierWidth / 2,
        height: MediaQuery.of(context).size.height * 3 / 4 * h / 2,
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withOpacity(0.8),
          border: Border.all(color: Colors.pinkAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10)],
        ),
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
