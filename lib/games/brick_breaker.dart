import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class BrickBreakerGame extends StatefulWidget {
  const BrickBreakerGame({super.key});

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

class _BrickBreakerGameState extends State<BrickBreakerGame> {
  // Ball state
  double ballX = 0;
  double ballY = 0;
  double ballDX = 0.01;
  double ballDY = -0.01;

  // Paddle state
  double paddleX = 0;
  double paddleWidth = 0.4;

  // Bricks state
  late List<List<bool>> bricks;
  static const int brickRows = 5;
  static const int brickCols = 6;
  int bricksRemaining = brickRows * brickCols;

  bool isPlaying = false;
  bool gameOver = false;
  bool gameWon = false;
  int score = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      ballX = 0;
      ballY = 0.8;
      ballDX = 0.015;
      ballDY = -0.015;
      paddleX = 0;
      bricks = List.generate(brickRows, (_) => List.filled(brickCols, true));
      bricksRemaining = brickRows * brickCols;
      isPlaying = false;
      gameOver = false;
      gameWon = false;
      score = 0;
    });
    timer?.cancel();
  }

  void _startGame() {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
    });
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _update();
    });
  }

  void _update() {
    setState(() {
      // Move ball
      ballX += ballDX;
      ballY += ballDY;

      // Wall collisions
      if (ballX <= -1 || ballX >= 1) ballDX = -ballDX;
      if (ballY <= -1) ballDY = -ballDY;

      // Paddle collision
      if (ballY >= 0.85 && ballX >= paddleX - paddleWidth / 2 && ballX <= paddleX + paddleWidth / 2) {
        ballDY = -ballDY;
        // Add some spin based on where it hits the paddle
        ballDX += (ballX - paddleX) * 0.05;
        HapticFeedback.lightImpact();
      }

      // Brick collisions
      double brickAreaBottom = -0.4;
      double brickAreaTop = -0.9;
      if (ballY <= brickAreaBottom && ballY >= brickAreaTop) {
        int r = (((ballY - brickAreaTop) / (brickAreaBottom - brickAreaTop)) * brickRows).floor();
        int c = (((ballX + 1) / 2) * brickCols).floor();

        if (r >= 0 && r < brickRows && c >= 0 && c < brickCols && bricks[r][c]) {
          bricks[r][c] = false;
          ballDY = -ballDY;
          score += 10;
          bricksRemaining--;
          HapticFeedback.selectionClick();

          if (bricksRemaining == 0) {
            _endGame(true);
          }
        }
      }

      // Bottom death
      if (ballY >= 1.1) {
        _endGame(false);
      }
    });
  }

  void _endGame(bool win) {
    timer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = !win;
      gameWon = win;
    });
    StatsManager().recordGamePlay("NEON BREAKER");
    if (win) StatsManager().recordWin();
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
        title: const Text('NEON BREAKER', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            paddleX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
            paddleX = paddleX.clamp(-1.0 + paddleWidth / 2, 1.0 - paddleWidth / 2);
          });
        },
        child: Column(
          children: [
            _buildHeader(),
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
                      _buildBricks(),
                      _buildBall(),
                      _buildPaddle(),
                      if (!isPlaying) _buildOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text("DRAG TO MOVE PADDLE", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreItem("SCORE", score.toString(), Colors.cyanAccent),
          _scoreItem("REMAINING", bricksRemaining.toString(), Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBricks() {
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;
      double height = constraints.maxHeight;
      double brickWidth = (width - (brickCols + 1) * 5) / brickCols;
      double brickHeight = 25;

      return Positioned(
        top: height * 0.05,
        left: 0,
        right: 0,
        child: Column(
          children: List.generate(brickRows, (r) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(brickCols, (c) {
                return Container(
                  width: brickWidth,
                  height: brickHeight,
                  margin: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: bricks[r][c] ? Colors.cyanAccent.withOpacity(0.8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: bricks[r][c] ? [const BoxShadow(color: Colors.cyanAccent, blurRadius: 5)] : [],
                  ),
                );
              }),
            );
          }),
        ),
      );
    });
  }

  Widget _buildBall() {
    return Align(
      alignment: Alignment(ballX, ballY),
      child: Container(
        width: 15,
        height: 15,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildPaddle() {
    return Align(
      alignment: Alignment(paddleX, 0.9),
      child: Container(
        width: 100,
        height: 15,
        decoration: BoxDecoration(
          color: Colors.pinkAccent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [const BoxShadow(color: Colors.pinkAccent, blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gameOver || gameWon)
              Text(
                gameWon ? "LEVEL CLEARED" : "SYSTEM FAILURE",
                style: TextStyle(
                  color: gameWon ? Colors.greenAccent : Colors.pinkAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("INITIALIZE"),
            ),
            const SizedBox(height: 10),
            if (!gameOver && !gameWon)
              TextButton(
                onPressed: _startGame,
                child: const Text("TAP TO LAUNCH", style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }
}
