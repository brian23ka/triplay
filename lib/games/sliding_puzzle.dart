import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class SlidingPuzzleGame extends StatefulWidget {
  const SlidingPuzzleGame({super.key});

  @override
  State<SlidingPuzzleGame> createState() => _SlidingPuzzleGameState();
}

class _SlidingPuzzleGameState extends State<SlidingPuzzleGame> {
  static const int size = 4; // 4x4
  late List<int> tiles;
  int moves = 0;
  bool gameWon = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      tiles = List.generate(size * size, (index) => index);
      _shuffle();
      moves = 0;
      gameWon = false;
    });
  }

  void _shuffle() {
    // Perform random valid moves to ensure solvability
    Random rand = Random();
    int emptyIndex = tiles.indexOf(0);
    for (int i = 0; i < 200; i++) {
      List<int> neighbors = _getNeighbors(emptyIndex);
      int target = neighbors[rand.nextInt(neighbors.length)];
      _swap(emptyIndex, target);
      emptyIndex = target;
    }
  }

  List<int> _getNeighbors(int index) {
    List<int> neighbors = [];
    int r = index ~/ size;
    int c = index % size;

    if (r > 0) neighbors.add(index - size);
    if (r < size - 1) neighbors.add(index + size);
    if (c > 0) neighbors.add(index - 1);
    if (c < size - 1) neighbors.add(index + 1);

    return neighbors;
  }

  void _swap(int i, int j) {
    int temp = tiles[i];
    tiles[i] = tiles[j];
    tiles[j] = temp;
  }

  void _handleTap(int index) {
    if (gameWon) return;

    int emptyIndex = tiles.indexOf(0);
    List<int> neighbors = _getNeighbors(index);

    if (neighbors.contains(emptyIndex)) {
      setState(() {
        _swap(index, emptyIndex);
        moves++;
        _checkWin();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _checkWin() {
    bool won = true;
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) {
        won = false;
        break;
      }
    }
    // Last tile should be 0
    if (won && tiles.last == 0) {
      gameWon = true;
      StatsManager().recordWin();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON PUZZLE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildScoreBoard(),
          const SizedBox(height: 40),
          Expanded(child: _buildGrid()),
          _buildFooter(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const Text("TOTAL MOVES", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text(moves.toString(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 48, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: size * size,
          itemBuilder: (context, index) {
            int val = tiles[index];
            if (val == 0) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () => _handleTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10)],
                ),
                child: Center(
                  child: Text(
                    val.toString(),
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (gameWon) {
      return Column(
        children: [
          const Text(
            "SYSTEM RESTORED",
            style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
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
            child: const Text("REBOOT"),
          ),
        ],
      );
    }
    return const Text(
      "ARRANGE TILES IN SEQUENCE",
      style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
    );
  }
}
