import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class PingPongGame extends StatefulWidget {
  const PingPongGame({super.key});

  @override
  State<PingPongGame> createState() => _PingPongGameState();
}

class _PingPongGameState extends State<PingPongGame> {
  // Game constants
  static const double paddleWidthPx = 80;
  static const double paddleHeightPx = 15;
  static const double ballRadius = 8;
  
  // Initial speeds for Alignment system (-1.0 to 1.0)
  double initialSpeedX = 0.015;
  double initialSpeedY = 0.015;

  // Game state
  double ballX = 0;
  double ballY = 0;
  double ballDX = 0;
  double ballDY = 0;
  
  double playerX = 0;
  double aiX = 0;
  
  int playerScore = 0;
  int aiScore = 0;
  
  bool isPlaying = false;
  bool gameOver = false;
  Timer? gameTimer;

  void _startGame() {
    if (isPlaying) return;
    setState(() {
      ballX = 0;
      ballY = 0;
      ballDX = (Random().nextBool() ? 1 : -1) * initialSpeedX;
      ballDY = initialSpeedY;
      playerScore = 0;
      aiScore = 0;
      isPlaying = true;
      gameOver = false;
      playerX = 0;
      aiX = 0;
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) _updateGame();
    });
  }

  void _updateGame() {
    // Get screen width for collision math
    final double screenWidth = MediaQuery.of(context).size.width - 40; // Subtracting container margin
    // Convert paddle width from pixels to alignment units (-1 to 1 range is 2.0 total)
    final double paddleWidthAlign = (paddleWidthPx / screenWidth) * 2;
    final double halfPaddle = paddleWidthAlign / 2;

    setState(() {
      // Update ball position
      ballX += ballDX;
      ballY += ballDY;

      // Ball collision with side walls
      if (ballX <= -1.0 || ballX >= 1.0) {
        ballDX = -ballDX;
        ballX = ballX.clamp(-1.0, 1.0);
      }

      // Ball collision with AI paddle (top)
      // Top paddle is at Alignment(aiX, -0.95)
      if (ballY <= -0.9 && ballDY < 0) {
        if (ballX >= aiX - halfPaddle && ballX <= aiX + halfPaddle) {
          ballDY = -ballDY;
          // Add a bit of speed and angle variety
          ballDY *= 1.02;
          ballDX += (ballX - aiX) * 0.05; 
        }
      }

      // Ball collision with Player paddle (bottom)
      // Player paddle is at Alignment(playerX, 0.95)
      if (ballY >= 0.9 && ballDY > 0) {
        if (ballX >= playerX - halfPaddle && ballX <= playerX + halfPaddle) {
          ballDY = -ballDY;
          ballDY *= 1.02;
          ballDX += (ballX - playerX) * 0.05;
          HapticFeedback.lightImpact();
        }
      }

      // AI Movement (Smoothed tracking)
      double aiTarget = ballX;
      double aiSpeed = 0.018;
      if (ballY < 0.2) { // Only track effectively when ball is on its half
         if ((aiX - aiTarget).abs() > 0.01) {
           aiX += (aiX < aiTarget) ? aiSpeed : -aiSpeed;
         }
      }
      aiX = aiX.clamp(-0.85, 0.85);

      // Check for scoring
      if (ballY <= -1.1) {
        playerScore++;
        _resetBall(true);
        if (playerScore >= 5) _endGame(true);
      } else if (ballY >= 1.1) {
        aiScore++;
        _resetBall(false);
        if (aiScore >= 5) _endGame(false);
      }
    });
  }

  void _resetBall(bool playerScored) {
    ballX = 0;
    ballY = 0;
    // Serve to the person who just conceded
    ballDX = (Random().nextBool() ? 1 : -1) * initialSpeedX;
    ballDY = playerScored ? -initialSpeedY : initialSpeedY;
  }

  void _endGame(bool playerWon) {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = true;
    });
    StatsManager().recordGamePlay("NEON PONG");
    if (playerWon) StatsManager().recordWin();
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
        title: const Text('NEON PONG', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (!isPlaying) return;
          setState(() {
            // Sensitivity based on screen width
            playerX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
            playerX = playerX.clamp(-0.85, 0.85);
          });
        },
        child: Column(
          children: [
            _buildScoreBoard(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1A1A2E),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // AI Paddle
                      Align(
                        alignment: Alignment(aiX, -0.95),
                        child: Container(
                          width: paddleWidthPx,
                          height: paddleHeightPx,
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [BoxShadow(color: Colors.pinkAccent, blurRadius: 10)],
                          ),
                        ),
                      ),
                      // Player Paddle
                      Align(
                        alignment: Alignment(playerX, 0.95),
                        child: Container(
                          width: paddleWidthPx,
                          height: paddleHeightPx,
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 10)],
                          ),
                        ),
                      ),
                      // Ball
                      Align(
                        alignment: Alignment(ballX, ballY),
                        child: Container(
                          width: ballRadius * 2,
                          height: ballRadius * 2,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10)],
                          ),
                        ),
                      ),
                      // Center line
                      Center(
                        child: Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.white10,
                        ),
                      ),
                      if (!isPlaying) _buildStartOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text("DRAG TO MOVE PADDLE", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreDisplay("AI COMMAND", aiScore, Colors.pinkAccent),
          _scoreDisplay("OPERATIVE", playerScore, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _scoreDisplay(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        Text(score.toString(), style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStartOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gameOver) ...[
              Text(
                playerScore > aiScore ? "MISSION SUCCESS" : "MISSION FAILED",
                style: TextStyle(
                  color: playerScore > aiScore ? Colors.cyanAccent : Colors.pinkAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                playerScore > aiScore ? "STREET CRED INCREASED" : "TERMINATED BY SYSTEM",
                style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
              ),
              const SizedBox(height: 30),
            ],
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                gameOver ? "RE-INITIALIZE" : "INITIATE SYSTEM",
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
