import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});

  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  late List<List<int>> board;
  late List<List<bool>> isOriginal;
  int? selectedRow;
  int? selectedCol;
  int difficulty = 30; // Number of cells to remove
  bool gameWon = false;

  @override
  void initState() {
    super.initState();
    _generateNewGame();
  }

  void _generateNewGame() {
    setState(() {
      board = _generateCompleteBoard();
      _removeCells();
      selectedRow = null;
      selectedCol = null;
      gameWon = false;
    });
  }

  List<List<int>> _generateCompleteBoard() {
    List<List<int>> b = List.generate(9, (_) => List.filled(9, 0));
    _solve(b);
    return b;
  }

  bool _solve(List<List<int>> b) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (b[r][c] == 0) {
          List<int> nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (int n in nums) {
            if (_isValid(b, r, c, n)) {
              b[r][c] = n;
              if (_solve(b)) return true;
              b[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValid(List<List<int>> b, int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (b[r][i] == n || b[i][c] == n) return false;
    }
    int boxR = (r ~/ 3) * 3;
    int boxC = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (b[boxR + i][boxC + j] == n) return false;
      }
    }
    return true;
  }

  void _removeCells() {
    isOriginal = List.generate(9, (_) => List.filled(9, true));
    int removed = 0;
    Random rand = Random();
    while (removed < difficulty) {
      int r = rand.nextInt(9);
      int c = rand.nextInt(9);
      if (board[r][c] != 0) {
        board[r][c] = 0;
        isOriginal[r][c] = false;
        removed++;
      }
    }
  }

  void _onCellTap(int r, int c) {
    if (isOriginal[r][c] || gameWon) return;
    setState(() {
      selectedRow = r;
      selectedCol = c;
    });
    HapticFeedback.lightImpact();
  }

  void _onNumberTap(int n) {
    if (selectedRow == null || selectedCol == null || gameWon) return;
    
    setState(() {
      board[selectedRow!][selectedCol!] = n;
      _checkWin();
    });
    HapticFeedback.mediumImpact();
  }

  void _checkWin() {
    // Check if board is full
    for (var row in board) {
      if (row.contains(0)) return;
    }

    // Check if valid
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int val = board[r][c];
        board[r][c] = 0;
        if (!_isValid(board, r, c, val)) {
          board[r][c] = val;
          return;
        }
        board[r][c] = val;
      }
    }

    setState(() => gameWon = true);
    StatsManager().recordWin();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON SUDOKU', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
          _buildBoard(),
          const Spacer(),
          _buildNumberPad(),
          const SizedBox(height: 30),
          _buildControls(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: 9,
          itemBuilder: (context, boxIndex) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: 9,
                itemBuilder: (context, cellIndex) {
                  int r = (boxIndex ~/ 3) * 3 + (cellIndex ~/ 3);
                  int c = (boxIndex % 3) * 3 + (cellIndex % 3);
                  bool isSelected = selectedRow == r && selectedCol == c;
                  bool original = isOriginal[r][c];

                  return GestureDetector(
                    onTap: () => _onCellTap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          board[r][c] == 0 ? '' : board[r][c].toString(),
                          style: TextStyle(
                            color: original ? Colors.white70 : Colors.cyanAccent,
                            fontSize: 18,
                            fontWeight: original ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      alignment: WrapAlignment.center,
      children: List.generate(9, (index) {
        int n = index + 1;
        return GestureDetector(
          onTap: () => _onNumberTap(n),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                n.toString(),
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControls() {
    if (gameWon) {
      return Column(
        children: [
          const Text("LOGIC SYNCED", style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _generateNewGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("NEW SYSTEM"),
          ),
        ],
      );
    }
    return ElevatedButton.icon(
      onPressed: _generateNewGame,
      icon: const Icon(Icons.refresh),
      label: const Text("RESET"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white38,
      ),
    );
  }
}
