import 'dart:async';
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
  int currentLevel = 1;
  bool gameWon = false;
  
  // Timer state
  Timer? _timer;
  int _seconds = 0;

  final Map<int, int> levelDifficulty = {
    1: 20, // SIMPLEST
    2: 32, // EASY
    3: 42, // MEDIUM
    4: 50, // ADVANCED
    5: 56, // HARD
    6: 61, // EXPERT
    7: 64, // MASTER
    8: 68, // IMPOSSIBLE
    9: 72, // INSANE
    10: 77, // UNSOLVABLE
  };

  String get levelLabel {
    if (currentLevel == 1) return "SYSTEM: SIMPLEST";
    if (currentLevel == 7) return "SYSTEM: MASTER";
    if (currentLevel == 10) return "SYSTEM: UNSOLVABLE";
    return "SYSTEM: LVL $currentLevel";
  }

  @override
  void initState() {
    super.initState();
    StatsManager().recordGamePlay('NEON SUDOKU');
    _generateNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!gameWon) {
        setState(() => _seconds++);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _generateNewGame() {
    setState(() {
      board = _generateCompleteBoard();
      _removeCells();
      selectedRow = null;
      selectedCol = null;
      gameWon = false;
    });
    _startTimer();
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
    int target = levelDifficulty[currentLevel] ?? 30;
    Random rand = Random();
    while (removed < target) {
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
    setState(() {
      selectedRow = r;
      selectedCol = c;
    });
    HapticFeedback.lightImpact();
  }

  void _onNumberTap(int n) {
    if (selectedRow == null || selectedCol == null || isOriginal[selectedRow!][selectedCol!] || gameWon) return;
    
    setState(() {
      board[selectedRow!][selectedCol!] = n;
      _checkWin();
    });
    HapticFeedback.mediumImpact();
  }

  void _onEraseTap() {
    if (selectedRow == null || selectedCol == null || isOriginal[selectedRow!][selectedCol!] || gameWon) return;
    setState(() {
      board[selectedRow!][selectedCol!] = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _checkWin() {
    for (var row in board) {
      if (row.contains(0)) return;
    }

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

  bool _isCellConflict(int r, int c) {
    int val = board[r][c];
    if (val == 0) return false;
    
    for (int i = 0; i < 9; i++) {
      if (i != c && board[r][i] == val) return true;
      if (i != r && board[i][c] == val) return true;
    }
    
    int boxR = (r ~/ 3) * 3;
    int boxC = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int rr = boxR + i;
        int cc = boxC + j;
        if ((rr != r || cc != c) && board[rr][cc] == val) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON SUDOKU', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderStats(),
            const SizedBox(height: 10),
            _buildLevelSelector(),
            const SizedBox(height: 10),
            Expanded(child: Center(child: _buildBoard())),
            _buildNumberPad(),
            const SizedBox(height: 20),
            _buildControls(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("TIME", _formatTime(_seconds)),
          Text(
            levelLabel,
            style: TextStyle(
              color: currentLevel == 10 ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.5),
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: currentLevel == 10 ? [const Shadow(color: Colors.redAccent, blurRadius: 10)] : [],
            ),
          ),
          _statItem("STATUS", gameWon ? "SYNCED" : "LIVE"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 10,
        itemBuilder: (context, index) {
          int lvl = index + 1;
          bool isSelected = currentLevel == lvl;
          return GestureDetector(
            onTap: () {
              if (currentLevel != lvl) {
                setState(() {
                  currentLevel = lvl;
                  _generateNewGame();
                });
                HapticFeedback.selectionClick();
              }
            },
            child: Container(
              width: 35,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.white10,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  lvl.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.cyanAccent : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoard() {
    int? selectedVal = (selectedRow != null && selectedCol != null) ? board[selectedRow!][selectedCol!] : null;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: List.generate(3, (boxRow) {
            return Expanded(
              child: Row(
                children: List.generate(3, (boxCol) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
                      ),
                      child: Column(
                        children: List.generate(3, (cellRowInBox) {
                          return Expanded(
                            child: Row(
                              children: List.generate(3, (cellColInBox) {
                                int r = boxRow * 3 + cellRowInBox;
                                int c = boxCol * 3 + cellColInBox;
                                
                                bool isSelected = selectedRow == r && selectedCol == c;
                                bool isRelated = selectedRow == r || selectedCol == c;
                                bool isSameVal = selectedVal != 0 && selectedVal == board[r][c];
                                bool original = isOriginal[r][c];
                                bool hasConflict = _isCellConflict(r, c);

                                Color cellColor = Colors.transparent;
                                if (isSelected) {
                                  cellColor = Colors.cyanAccent.withOpacity(0.25);
                                } else if (isSameVal) {
                                  cellColor = Colors.cyanAccent.withOpacity(0.15);
                                } else if (isRelated) {
                                  cellColor = Colors.white.withOpacity(0.03);
                                }

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _onCellTap(r, c),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        border: Border.all(color: Colors.white10.withOpacity(0.05), width: 0.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          board[r][c] == 0 ? '' : board[r][c].toString(),
                                          style: TextStyle(
                                            color: hasConflict 
                                              ? Colors.redAccent 
                                              : (original ? Colors.white : Colors.cyanAccent),
                                            fontSize: 20,
                                            fontWeight: original ? FontWeight.w400 : FontWeight.bold,
                                            shadows: (original || hasConflict) ? [] : [const Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(9, (index) {
              int n = index + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onNumberTap(n),
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        n.toString(),
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _onEraseTap,
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.backspace_outlined, color: Colors.pinkAccent, size: 16),
                SizedBox(width: 8),
                Text("ERASE", style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (gameWon) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Text(
              "SYSTEM STABILIZED",
              style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _generateNewGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withOpacity(0.1),
                foregroundColor: Colors.greenAccent,
                side: const BorderSide(color: Colors.greenAccent),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("INITIALIZE NEW SYSTEM", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    return TextButton.icon(
      onPressed: _generateNewGame,
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text("REBOOT GRID", style: TextStyle(fontSize: 11, letterSpacing: 1)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white24,
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT NEON SUDOKU", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "Complete the 9x9 grid so that each row, each column, and each of the nine 3x3 subgrids contain all of the digits from 1 to 9. Features 10 levels of difficulty from Simplest to Unsolvable.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}
