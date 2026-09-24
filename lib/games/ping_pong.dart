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

  // Level state
  int currentLevel = 1;
  static const int maxLevels = 5;
  bool isAiMode = true;

  // Game state
  double ballX = 0;
  double ballY = 0;
  double ballDX = 0;
  double ballDY = 0;
  
  double playerX = 0;
  double aiX = 0; // In 2-player mode, this is Player 2's position
  
  int playerScore = 0;
  int aiScore = 0; // In 2-player mode, this is Player 2's score
  
  bool isPlaying = false;
  bool gameOver = false;
  Timer? gameTimer;

  void _toggleMode(bool ai) {
    if (isPlaying) return;
    setState(() {
      isAiMode = ai;
      _resetGame();
    });
  }

  void _resetGame() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = false;
      playerScore = 0;
      aiScore = 0;
      ballX = 0;
      ballY = 0;
      playerX = 0;
      aiX = 0;
    });
  }

  void _startGame() {
    if (isPlaying) return;
    setState(() {
      ballX = 0;
      ballY = 0;
      
      // Speed scales with level
      double speedMultiplier = 1.0 + (currentLevel - 1) * 0.15;
      ballDX = (Random().nextBool() ? 1 : -1) * initialSpeedX * speedMultiplier;
      ballDY = initialSpeedY * speedMultiplier;
      
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

      // Ball collision with Top paddle (AI or Player 2)
      if (ballY <= -0.9 && ballDY < 0) {
        if (ballX >= aiX - halfPaddle && ballX <= aiX + halfPaddle) {
          ballDY = -ballDY;
          ballDY *= 1.02;
          ballDX += (ballX - aiX) * 0.05; 
          HapticFeedback.lightImpact();
        }
      }

      // Ball collision with Bottom paddle (Player 1)
      if (ballY >= 0.9 && ballDY > 0) {
        if (ballX >= playerX - halfPaddle && ballX <= playerX + halfPaddle) {
          ballDY = -ballDY;
          ballDY *= 1.02;
          ballDX += (ballX - playerX) * 0.05;
          HapticFeedback.lightImpact();
        }
      }

      // AI Movement (Only if enabled)
      if (isAiMode) {
        double aiTarget = ballX;
        double aiSpeed = 0.016 + (currentLevel * 0.003);
        if (ballY < 0.3) { 
           if ((aiX - aiTarget).abs() > 0.01) {
             aiX += (aiX < aiTarget) ? aiSpeed : -aiSpeed;
           }
        }
        aiX = aiX.clamp(-0.85, 0.85);
      }

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
    double speedMultiplier = 1.0 + (currentLevel - 1) * 0.15;
    ballDX = (Random().nextBool() ? 1 : -1) * initialSpeedX * speedMultiplier;
    ballDY = playerScored ? -initialSpeedY * speedMultiplier : initialSpeedY * speedMultiplier;
  }

  void _endGame(bool playerWon) {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = true;
    });
    StatsManager().recordGamePlay("NEON PONG");
    if (isAiMode && playerWon) StatsManager().recordWin();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            onPressed: _showAbout,
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          if (!isPlaying) return;
          final double screenHeight = MediaQuery.of(context).size.height;
          final double y = details.localPosition.dy;
          
          setState(() {
            if (y > screenHeight / 2) {
              // Bottom half - Player 1
              playerX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
              playerX = playerX.clamp(-0.85, 0.85);
            } else if (!isAiMode) {
              // Top half - Player 2 (Only in 2P mode)
              aiX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
              aiX = aiX.clamp(-0.85, 0.85);
            }
          });
        },
        child: Column(
          children: [
            _buildScoreBoard(),
            _buildModeSelector(),
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
    String p2Label = isAiMode ? "AI COMMAND" : "OPERATIVE 2";
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreDisplay(p2Label, aiScore, Colors.pinkAccent),
          _scoreDisplay(isAiMode ? "OPERATIVE" : "OPERATIVE 1", playerScore, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _modeToggleItem("SYSTEM AI", isAiMode, () => _toggleMode(true)),
          _modeToggleItem("DUAL LINK", !isAiMode, () => _toggleMode(false)),
        ],
      ),
    );
  }

  Widget _modeToggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.cyanAccent : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.2
              ),
            ),
          ),
        ),
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
    String p1WinMsg = isAiMode ? "MISSION SUCCESS" : "PLAYER 1 DOMINATES";
    String p2WinMsg = isAiMode ? "MISSION FAILED" : "PLAYER 2 DOMINATES";
    
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gameOver) ...[
              Text(
                playerScore > aiScore ? p1WinMsg : p2WinMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: playerScore > aiScore ? Colors.cyanAccent : Colors.pinkAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                playerScore > aiScore ? "SYSTEM BYPASS COMPLETE" : "TERMINATED BY SYSTEM",
                style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
              ),
              const SizedBox(height: 30),
            ],
            
            Text(
              isAiMode ? "LEVEL $currentLevel" : "GAME INTENSITY",
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const SizedBox(height: 20),
            
            // Level/Speed Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxLevels, (index) {
                int level = index + 1;
                bool isSelected = currentLevel == level;
                return GestureDetector(
                  onTap: () => setState(() => currentLevel = level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24, width: 2),
                      color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        level.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.cyanAccent : Colors.white24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            if (!isAiMode) ...[
              const SizedBox(height: 10),
              const Text(
                "2 PLAYER BATTLE",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ],
              
            const SizedBox(height: 40),

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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT NEON PONG", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "A futuristic high-speed table tennis battle. \n\nSOLO MODE: Defeat the AI system by reaching 5 points. Difficulty increases with level.\n\nDUAL LINK: Face off against a local opponent. Drag the bottom half of the screen for P1, top half for P2.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}
