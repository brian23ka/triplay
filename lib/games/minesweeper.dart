import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameMode { solo, vsAI, twoPlayer }

class MinesweeperGame extends StatefulWidget {
  const MinesweeperGame({super.key});

  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const int rows = 20;
  static const int cols = 12;
  static const int totalMines = 40;

  late List<List<Cell>> grid;
  bool gameOver = false;
  bool gameWon = false;
  bool firstTap = true;

  GameMode mode = GameMode.solo;
  int currentPlayer = 1;
  int winner = 0; // 0: Draw/None, 1: Player 1, 2: Player 2/AI
  bool isAiThinking = false;

  int scoreP1 = 0;
  int scoreP2 = 0;
  int aiDifficulty = 2;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    setState(() {
      grid = List.generate(
        rows,
        (r) => List.generate(cols, (c) => Cell(r, c)),
      );
      gameOver = false;
      gameWon = false;
      firstTap = true;
      currentPlayer = 1;
      winner = 0;
      isAiThinking = false;
      scoreP1 = 0;
      scoreP2 = 0;
    });
  }

  void _changeMode(GameMode newMode) {
    if (!firstTap) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text("Change Mode?", style: TextStyle(color: Colors.cyanAccent)),
          content: const Text("This will reset your current game.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  mode = newMode;
                });
                _initializeGrid();
              },
              child: const Text("CONFIRM")
            ),
          ],
        ),
      );
    } else {
      setState(() {
        mode = newMode;
      });
      _initializeGrid();
    }
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.cyanAccent, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text("MISSION PROTOCOLS", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ruleSection("OBJECTIVE", "Identify all safe areas. If you hit a mine, the mission fails."),
              _ruleSection("CONTROLS", "• TAP: Reveal a cell. Empty areas expand automatically.\n• LONG PRESS: Flag/Defuse suspected mines. Correct flags turn GREEN.\n• QUICK REVEAL: Tap a revealed number to open surrounding cells if you have correctly flagged the mines."),
              _ruleSection("SCORING", "• Safe Cell: +1 point.\n• Defused Mine: +5 points.\n• Mine Hit: -10 points."),
              _ruleSection("WIN CONDITION", "Reveal all non-mine cells to win the game."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ACKNOWLEDGED", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _ruleSection(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  void _generateMines(int startR, int startC) {
    int minesPlaced = 0;
    Random random = Random();

    while (minesPlaced < totalMines) {
      int r = random.nextInt(rows);
      int c = random.nextInt(cols);

      // Standard logic: First tap and its 3x3 area are never mines
      bool isNearStart = (r - startR).abs() <= 1 && (c - startC).abs() <= 1;

      if (!grid[r][c].isMine && !isNearStart) {
        grid[r][c].isMine = true;
        minesPlaced++;
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!grid[r][c].isMine) {
          grid[r][c].neighborMines = _getNeighbors(r, c).where((n) => n.isMine).length;
        }
      }
    }
  }

  void _handleTap(int r, int c) {
    if (gameOver || gameWon || isAiThinking) return;

    if (firstTap) {
      _generateMines(r, c);
      firstTap = false;
    }

    // Chording logic: If tapping a revealed number, reveal neighbors if flags match
    if (grid[r][c].isRevealed && !grid[r][c].isMine && grid[r][c].neighborMines > 0) {
      _chordCell(r, c);
      return;
    }

    if (grid[r][c].isFlagged || grid[r][c].isRevealed) return;

    _processMove(r, c);
  }

  void _chordCell(int r, int c) {
    List<Cell> neighbors = _getNeighbors(r, c);
    int flagsAround = neighbors.where((n) => n.isFlagged).length;

    if (flagsAround == grid[r][c].neighborMines) {
      bool hitMine = false;
      int newlyRevealed = 0;
      
      setState(() {
        for (var n in neighbors) {
          if (!n.isRevealed && !n.isFlagged) {
            if (n.isMine) {
              n.isRevealed = true;
              hitMine = true;
            } else {
              newlyRevealed += _revealCellRecursive(n.r, n.c);
            }
          }
        }
        
        if (currentPlayer == 1) scoreP1 += newlyRevealed;
        else scoreP2 += newlyRevealed;

        if (hitMine) {
          _endGame(false);
        } else {
          _checkWinCondition();
        }
      });
    }
  }

  void _processMove(int r, int c) {
    setState(() {
      if (grid[r][c].isMine) {
        grid[r][c].isRevealed = true;
        if (currentPlayer == 1) scoreP1 = max(0, scoreP1 - 10);
        else scoreP2 = max(0, scoreP2 - 10);
        _endGame(false);
      } else {
        int revealedCount = _revealCellRecursive(r, c);
        if (currentPlayer == 1) scoreP1 += revealedCount;
        else scoreP2 += revealedCount;
        HapticFeedback.lightImpact();
        _checkWinCondition();
      }

      if (!gameWon && !gameOver && mode != GameMode.solo) {
        currentPlayer = (currentPlayer == 1) ? 2 : 1;
        if (mode == GameMode.vsAI && currentPlayer == 2) {
          _triggerAiMove();
        }
      }
    });
  }

  int _revealCellRecursive(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols || 
        grid[r][c].isRevealed || grid[r][c].isFlagged || grid[r][c].isMine) return 0;

    grid[r][c].isRevealed = true;
    int count = 1;

    if (grid[r][c].neighborMines == 0) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          count += _revealCellRecursive(r + dr, c + dc);
        }
      }
    }
    return count;
  }

  Future<void> _triggerAiMove() async {
    setState(() => isAiThinking = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || gameOver || gameWon) {
      setState(() => isAiThinking = false);
      return;
    }
    _aiMove();
    setState(() => isAiThinking = false);
  }

  void _aiMove() {
    List<Cell> available = [];
    for (var row in grid) {
      for (var cell in row) {
        if (!cell.isRevealed && !cell.isFlagged) available.add(cell);
      }
    }
    if (available.isNotEmpty) {
      Cell choice = available[Random().nextInt(available.length)];
      _processMove(choice.r, choice.c);
    }
  }

  List<Cell> _getNeighbors(int r, int c) {
    List<Cell> neighbors = [];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          neighbors.add(grid[nr][nc]);
        }
      }
    }
    return neighbors;
  }

  void _handleLongPress(int r, int c) {
    if (gameOver || gameWon || isAiThinking || grid[r][c].isRevealed) return;
    
    if (firstTap) {
      _generateMines(r, c);
      firstTap = false;
    }

    setState(() {
      grid[r][c].isFlagged = !grid[r][c].isFlagged;
      if (grid[r][c].isFlagged && grid[r][c].isMine) {
        if (currentPlayer == 1) scoreP1 += 5;
        else scoreP2 += 5;
      } else if (!grid[r][c].isFlagged && grid[r][c].isMine) {
        if (currentPlayer == 1) scoreP1 -= 5;
        else scoreP2 -= 5;
      }
      HapticFeedback.mediumImpact();
      _checkWinCondition();
    });
  }

  void _checkWinCondition() {
    bool allSafeRevealed = true;
    for (var row in grid) {
      for (var cell in row) {
        if (!cell.isMine && !cell.isRevealed) {
          allSafeRevealed = false;
          break;
        }
      }
    }

    if (allSafeRevealed) {
      _endGame(true);
    }
  }

  void _endGame(bool won) {
    setState(() {
      if (won) {
        gameWon = true;
        if (mode != GameMode.solo) {
          if (scoreP1 > scoreP2) winner = 1;
          else if (scoreP2 > scoreP1) winner = 2;
          else winner = 0;
        }
        if (mode == GameMode.solo || (mode == GameMode.vsAI && winner == 1)) {
           StatsManager().recordWin();
        }
        HapticFeedback.heavyImpact();
      } else {
        gameOver = true;
        HapticFeedback.vibrate();
      }
      
      // Reveal all mines
      for (var row in grid) {
        for (var cell in row) {
          if (cell.isMine) cell.isRevealed = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('MINE DEFUSE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.cyanAccent),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          if (mode == GameMode.vsAI) _buildAiDifficultySelector(),
          _buildScoreHeader(),
          _buildTurnIndicator(),
          Expanded(child: _buildGrid()),
          _buildControls(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _modeToggleItem("SOLO", mode == GameMode.solo, () => _changeMode(GameMode.solo)),
          _modeToggleItem("VS AI", mode == GameMode.vsAI, () => _changeMode(GameMode.vsAI)),
          _modeToggleItem("2 PLAYER", mode == GameMode.twoPlayer, () => _changeMode(GameMode.twoPlayer)),
        ],
      ),
    );
  }

  Widget _buildAiDifficultySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("AI DIFFICULTY: ", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            _difficultyChip("EASY", 1),
            _difficultyChip("MED", 2),
            _difficultyChip("HARD", 3),
          ],
        ),
      ),
    );
  }

  Widget _difficultyChip(String label, int level) {
    bool isSelected = aiDifficulty == level;
    return GestureDetector(
      onTap: () => setState(() => aiDifficulty = level),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _modeToggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                fontSize: 12,
                letterSpacing: 1.2
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _infoItem(mode == GameMode.solo ? "SCORE" : "P1 SCORE", scoreP1.toString(), Colors.cyanAccent)),
          if (mode != GameMode.solo)
            Expanded(child: _infoItem(mode == GameMode.vsAI ? "AI SCORE" : "P2 SCORE", scoreP2.toString(), mode == GameMode.vsAI ? Colors.orangeAccent : Colors.pinkAccent)),
          Expanded(child: _infoItem("MINES", "${_getFlagCount()}/$totalMines", Colors.white54)),
        ],
      ),
    );
  }

  int _getFlagCount() {
    int count = 0;
    for (var row in grid) {
      for (var cell in row) {
        if (cell.isFlagged) count++;
      }
    }
    return count;
  }

  Widget _infoItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label, 
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)
        ),
        Text(
          value, 
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _buildTurnIndicator() {
    if (mode == GameMode.solo || gameOver || gameWon) return const SizedBox.shrink();
    
    String turnText = "";
    Color turnColor = Colors.cyanAccent;
    
    if (mode == GameMode.twoPlayer) {
      turnText = currentPlayer == 1 ? "PLAYER 1'S TURN" : "PLAYER 2'S TURN";
      turnColor = currentPlayer == 1 ? Colors.cyanAccent : Colors.pinkAccent;
    } else {
      turnText = currentPlayer == 1 ? "YOUR TURN" : "AI IS THINKING...";
      turnColor = currentPlayer == 1 ? Colors.cyanAccent : Colors.orangeAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        turnText,
        style: TextStyle(
          color: turnColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [Shadow(color: turnColor.withOpacity(0.5), blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: AspectRatio(
          aspectRatio: cols / rows,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
              ),
              itemCount: rows * cols,
              itemBuilder: (context, index) {
                int r = index ~/ cols;
                int c = index % cols;
                Cell cell = grid[r][c];
                
                bool isDefused = cell.isFlagged && cell.isMine;
                bool isHit = cell.isRevealed && cell.isMine && !cell.isFlagged;

                return GestureDetector(
                  onTap: () => _handleTap(r, c),
                  onLongPress: () => _handleLongPress(r, c),
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isDefused 
                          ? Colors.greenAccent.withOpacity(0.15)
                          : (isHit 
                              ? Colors.pinkAccent.withOpacity(0.2)
                              : (cell.isRevealed 
                                  ? Colors.cyanAccent.withOpacity(0.05)
                                  : const Color(0xFF1A1A2E))),
                      border: Border.all(
                        color: isDefused
                            ? Colors.greenAccent.withOpacity(0.4)
                            : (cell.isRevealed ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: _buildCellContent(cell),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(Cell cell) {
    if (cell.isFlagged && cell.isMine) {
      return const Icon(
        Icons.wb_iridescent, 
        color: Colors.greenAccent, 
        size: 14,
        shadows: [Shadow(color: Colors.greenAccent, blurRadius: 10)],
      );
    }
    
    if (cell.isFlagged) {
      return const Icon(Icons.flag, color: Colors.cyanAccent, size: 12);
    }
    
    if (cell.isRevealed) {
      if (cell.isMine) {
        return const Icon(Icons.wb_iridescent, color: Colors.pinkAccent, size: 12);
      } else if (cell.neighborMines > 0) {
        return Text(
          cell.neighborMines.toString(),
          style: TextStyle(
            color: _getMineColor(cell.neighborMines),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Color _getMineColor(int count) {
    switch (count) {
      case 1: return Colors.blueAccent;
      case 2: return Colors.greenAccent;
      case 3: return Colors.pinkAccent;
      case 4: return Colors.purpleAccent;
      case 5: return Colors.orangeAccent;
      case 6: return Colors.cyanAccent;
      case 7: return Colors.black;
      case 8: return Colors.grey;
      default: return Colors.white;
    }
  }

  Widget _buildControls() {
    if (gameOver || gameWon) {
      String statusText = "";
      Color statusColor = Colors.white;

      if (gameWon) {
        if (mode == GameMode.solo) {
          statusText = "MISSION SUCCESS";
          statusColor = Colors.greenAccent;
        } else {
          if (winner == 0) {
            statusText = "MISSION DRAW";
            statusColor = Colors.yellowAccent;
          } else {
            String winnerName = "";
            if (mode == GameMode.twoPlayer) winnerName = winner == 1 ? "PLAYER 1" : "PLAYER 2";
            else winnerName = winner == 1 ? "YOU WIN" : "AI WINS";
            statusText = "$winnerName VICTORIOUS";
            statusColor = winner == 1 ? Colors.cyanAccent : Colors.pinkAccent;
          }
        }
      } else if (gameOver) {
        statusText = "MISSION FAILED";
        statusColor = Colors.pinkAccent;
      }

      return Column(
        children: [
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [Shadow(color: statusColor, blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "FINAL SCORE: P1: $scoreP1 ${mode != GameMode.solo ? '| P2: $scoreP2' : ''}",
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _initializeGrid,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text("RETRY SYSTEM"),
          ),
        ],
      );
    }

    return const Text(
      "TAP TO REVEAL SAFE AREAS\nHOLD TO DEFUSE MINES",
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
    );
  }
}

class Cell {
  final int r;
  final int c;
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int neighborMines = 0;

  Cell(this.r, this.c);
}
