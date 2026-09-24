import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class OMOGame extends StatefulWidget {
  const OMOGame({super.key});

  @override
  State<OMOGame> createState() => _OMOGameState();
}

class _OMOGameState extends State<OMOGame> {
  static const int gridSize = 15;
  late List<List<String>> board;
  late List<List<bool>> marked;
  bool player1Turn = true;
  int player1Score = 0;
  int player2Score = 0;
  bool isAiMode = true;
  String selectedLetter = 'O';
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      board = List.generate(gridSize, (_) => List.filled(gridSize, ''));
      marked = List.generate(gridSize, (_) => List.filled(gridSize, false));
      player1Turn = true;
      player1Score = 0;
      player2Score = 0;
      gameOver = false;
      selectedLetter = 'O';
    });
  }

  void _handleCellTap(int row, int col) {
    if (board[row][col] != '' || gameOver) return;

    setState(() {
      board[row][col] = selectedLetter;
      int points = _checkAndMarkOMO(row, col);
      if (player1Turn) {
        player1Score += points;
      } else {
        player2Score += points;
      }

      player1Turn = !player1Turn;

      if (_isBoardFull()) {
        gameOver = true;
        _recordStats();
      } else if (isAiMode && !player1Turn) {
        Future.delayed(const Duration(milliseconds: 600), () => _aiMove());
      }
    });
    HapticFeedback.lightImpact();
  }

  void _aiMove() {
    if (gameOver || player1Turn) return;

    var move = _findBestAiMove();
    setState(() {
      board[move.row][move.col] = move.letter;
      int points = _checkAndMarkOMO(move.row, move.col);
      player2Score += points;
      player1Turn = true;

      if (_isBoardFull()) {
        gameOver = true;
        _recordStats();
      }
    });
    HapticFeedback.lightImpact();
  }

  _AiMove _findBestAiMove() {
    // 1. Can AI complete an OMO?
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == '') {
          for (var letter in ['O', 'M']) {
            board[r][c] = letter;
            if (_countPotentialOMO(r, c) > 0) {
              board[r][c] = '';
              return _AiMove(r, c, letter);
            }
            board[r][c] = '';
          }
        }
      }
    }

    // 2. Can player complete an OMO next turn? (Block if possible)
    // For simplicity, just pick a random strategic spot or any empty spot
    List<_AiMove> available = [];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == '') {
          available.add(_AiMove(r, c, Random().nextBool() ? 'O' : 'M'));
        }
      }
    }
    
    // Sort random moves to favor center slightly? (Maybe not needed for 15x15)
    return available[Random().nextInt(available.length)];
  }

  int _checkAndMarkOMO(int row, int col) {
    int found = 0;
    String letter = board[row][col];
    List<List<int>> dirs = [[0, 1], [1, 0], [1, 1], [1, -1]];

    for (var d in dirs) {
      int dr = d[0];
      int dc = d[1];

      if (letter == 'M') {
        if (_isLetter(row - dr, col - dc, 'O') && _isLetter(row + dr, col + dc, 'O')) {
          found++;
          _mark(row - dr, col - dc);
          _mark(row, col);
          _mark(row + dr, col + dc);
        }
      } else {
        if (_isLetter(row + dr, col + dc, 'M') && _isLetter(row + 2 * dr, col + 2 * dc, 'O')) {
          found++;
          _mark(row, col);
          _mark(row + dr, col + dc);
          _mark(row + 2 * dr, col + 2 * dc);
        }
        if (_isLetter(row - dr, col - dc, 'M') && _isLetter(row - 2 * dr, col - 2 * dc, 'O')) {
          found++;
          _mark(row, col);
          _mark(row - dr, col - dc);
          _mark(row - 2 * dr, col - 2 * dc);
        }
      }
    }
    return found;
  }

  int _countPotentialOMO(int row, int col) {
    int count = 0;
    String letter = board[row][col];
    List<List<int>> dirs = [[0, 1], [1, 0], [1, 1], [1, -1]];
    for (var d in dirs) {
      int dr = d[0];
      int dc = d[1];
      if (letter == 'M') {
        if (_isLetter(row - dr, col - dc, 'O') && _isLetter(row + dr, col + dc, 'O')) count++;
      } else {
        if (_isLetter(row + dr, col + dc, 'M') && _isLetter(row + 2 * dr, col + 2 * dc, 'O')) count++;
        if (_isLetter(row - dr, col - dc, 'M') && _isLetter(row - 2 * dr, col - 2 * dc, 'O')) count++;
      }
    }
    return count;
  }

  bool _isLetter(int r, int c, String char) {
    if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) return false;
    return board[r][c] == char;
  }

  void _mark(int r, int c) {
    marked[r][c] = true;
  }

  bool _isBoardFull() {
    for (var row in board) {
      if (row.contains('')) return false;
    }
    return true;
  }

  void _recordStats() {
    StatsManager().recordGamePlay('OMO GAME');
    if (player1Score > player2Score) {
      StatsManager().recordWin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('OMO CHALLENGE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildScoreBoard(),
              _buildTurnIndicator(),
              _buildToolBar(),
              Expanded(child: _buildGrid()),
              const SizedBox(height: 20),
            ],
          ),
          if (gameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreItem("OPERATIVE", player1Score, Colors.cyanAccent),
          const Text("VS", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
          _scoreItem(isAiMode ? "SYSTEM" : "PLAYER 2", player2Score, Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(score.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTurnIndicator() {
    Color color = player1Turn ? Colors.cyanAccent : Colors.pinkAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Text(
        player1Turn ? "YOUR TURN" : (isAiMode ? "SYSTEM CALCULATING..." : "P2 TURN"),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
      ),
    );
  }

  Widget _buildToolBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: ['O', 'M'].map((letter) {
              bool isSelected = selectedLetter == letter;
              return GestureDetector(
                onTap: () => setState(() => selectedLetter = letter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 15),
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white10, width: 2),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10)] : [],
                  ),
                  child: Center(
                    child: Text(letter, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  ),
                ),
              );
            }).toList(),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                onPressed: _resetGame,
              ),
              const Text("RESET", style: TextStyle(color: Colors.white24, fontSize: 8)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 16, color: Colors.white38),
                Switch(
                  value: isAiMode,
                  onChanged: (val) => setState(() {
                    isAiMode = val;
                    _resetGame();
                  }),
                  activeColor: Colors.cyanAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InteractiveViewer(
        maxScale: 3.0,
        minScale: 0.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double boardWidth = constraints.maxWidth;
            double cellSize = boardWidth / gridSize;
            return GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridSize * gridSize,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
              ),
              itemBuilder: (context, index) {
                int r = index ~/ gridSize;
                int c = index % gridSize;
                String letter = board[r][c];
                bool isMarked = marked[r][c];

                return GestureDetector(
                  onTap: () => _handleCellTap(r, c),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                      color: isMarked ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: isMarked ? Colors.amberAccent : Colors.white,
                          fontSize: cellSize * 0.7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    String message = player1Score > player2Score ? "MISSION SUCCESS" : (player1Score < player2Score ? "SYSTEM OVERRIDE" : "LINK STABLE");
    Color color = player1Score > player2Score ? Colors.cyanAccent : Colors.pinkAccent;

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 10),
            Text("SCORE: $player1Score - $player2Score", style: const TextStyle(color: Colors.white70, letterSpacing: 2)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("RE-INITIALIZE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
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
        title: const Text("ABOUT OMO CHALLENGE", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "A tactical word-formation game. Place 'O' or 'M' on the grid to complete the word 'OMO'. You can form words horizontally, vertically, or diagonally. The player with the most completions wins when the grid is full.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}

class _AiMove {
  final int row;
  final int col;
  final String letter;
  _AiMove(this.row, this.col, this.letter);
}
