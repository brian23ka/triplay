import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> {
  static const int rowCount = 20;
  static const int columnCount = 15;

  List<int> snake = [45, 44, 43];
  int food = 100;
  Direction direction = Direction.right;
  Timer? timer;
  bool isPlaying = false;
  int score = 0;
  bool gameOver = false;
  int level = 1;

  void startGame() {
    if (isPlaying) return;
    
    setState(() {
      snake = [45, 44, 43];
      food = Random().nextInt(rowCount * columnCount);
      direction = Direction.right;
      score = 0;
      isPlaying = true;
      gameOver = false;
    });

    int speed = (200 - (level - 1) * 15).clamp(50, 200);

    timer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      _moveSnake();
    });
  }

  void _moveSnake() {
    setState(() {
      int head = snake.first;
      int nextHead;

      switch (direction) {
        case Direction.up:
          nextHead = head - columnCount;
          break;
        case Direction.down:
          nextHead = head + columnCount;
          break;
        case Direction.left:
          nextHead = head - 1;
          if (head % columnCount == 0) nextHead += columnCount;
          break;
        case Direction.right:
          nextHead = head + 1;
          if (nextHead % columnCount == 0) nextHead -= columnCount;
          break;
      }

      // Check walls for up/down (wrap-around for left/right is handled above)
      if (nextHead < 0) nextHead += rowCount * columnCount;
      if (nextHead >= rowCount * columnCount) nextHead -= rowCount * columnCount;

      // Check self-collision
      if (snake.contains(nextHead)) {
        _endGame();
        return;
      }

      snake.insert(0, nextHead);

      // Check food
      if (nextHead == food) {
        score += 10;
        _generateFood();
        HapticFeedback.lightImpact();
      } else {
        snake.removeLast();
      }
    });
  }

  void _generateFood() {
    int newFood;
    do {
      newFood = Random().nextInt(rowCount * columnCount);
    } while (snake.contains(newFood));
    food = newFood;
  }

  void _endGame() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
      gameOver = true;
    });
    StatsManager().recordGamePlay("NEON SNAKE");
    if (score > 50) StatsManager().recordWin();
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
        title: const Text('NEON SNAKE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
          _buildScoreBoard(),
          Expanded(child: _buildGrid()),
          _buildControls(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("LEVEL", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text(level.toString(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("TOTAL SCORE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text(score.toString(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0 && direction != Direction.up) direction = Direction.down;
        if (details.delta.dy < 0 && direction != Direction.down) direction = Direction.up;
      },
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0 && direction != Direction.left) direction = Direction.right;
        if (details.delta.dx < 0 && direction != Direction.right) direction = Direction.left;
      },
      child: AspectRatio(
        aspectRatio: columnCount / rowCount,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
            ),
            itemCount: rowCount * columnCount,
            itemBuilder: (context, index) {
              if (snake.contains(index)) {
                bool isHead = snake.first == index;
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isHead ? Colors.cyanAccent : Colors.cyanAccent.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(isHead ? 4 : 2),
                    boxShadow: isHead ? [const BoxShadow(color: Colors.cyanAccent, blurRadius: 5)] : null,
                  ),
                );
              }
              if (index == food) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.pinkAccent, blurRadius: 10)],
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (!isPlaying) {
      return Column(
        children: [
          if (gameOver)
            const Text("SYSTEM CRASHED", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 15),
          if (!gameOver) ...[
            const Text("SELECT INTENSITY", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int l = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => level = l),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: level == l ? Colors.cyanAccent.withOpacity(0.2) : Colors.transparent,
                      border: Border.all(color: level == l ? Colors.cyanAccent : Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        l.toString(),
                        style: TextStyle(
                          color: level == l ? Colors.cyanAccent : Colors.white38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
          ElevatedButton(
            onPressed: startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: Text(gameOver ? "REBOOT" : "INITIALIZE"),
          ),
          const SizedBox(height: 10),
          const Text("SWIPE TO NAVIGATE", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _directionPad(),
      ],
    );
  }

  Widget _directionPad() {
    return Column(
      children: [
        IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.white38), onPressed: () { if(direction != Direction.down) setState(() => direction = Direction.up); }),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white38), onPressed: () { if(direction != Direction.right) setState(() => direction = Direction.left); }),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.white38), onPressed: () { if(direction != Direction.left) setState(() => direction = Direction.right); }),
          ],
        ),
        IconButton(icon: const Icon(Icons.arrow_downward, color: Colors.white38), onPressed: () { if(direction != Direction.up) setState(() => direction = Direction.down); }),
      ],
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT NEON SNAKE", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "Navigate the neon snake to consume the pink energy cores. Each core increases your length and score. Don't collide with yourself! Use the swipe gestures or the directional pad to steer.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}
