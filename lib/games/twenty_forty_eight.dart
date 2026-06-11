import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triplay/stats_manager.dart';

class TwentyFortyEightGame extends StatefulWidget {
  const TwentyFortyEightGame({super.key});

  @override
  State<TwentyFortyEightGame> createState() => _TwentyFortyEightGameState();
}

class _TwentyFortyEightGameState extends State<TwentyFortyEightGame> {
  late List<List<int>> grid;
  List<List<int>>? lastGrid;
  int score = 0;
  int lastScore = 0;
  int bestScore = 0;
  bool gameOver = false;
  bool gameWon = false;
  bool lastGameWon = false;
  bool gameContinued = false;
  bool _hasRecordedPlay = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _resetGame();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final best = await StatsManager().getBestScore("2048");
    if (mounted) {
      setState(() {
        bestScore = best ?? 0;
      });
    }
  }

  void _resetGame() {
    setState(() {
      grid = List.generate(4, (_) => List.filled(4, 0));
      lastGrid = null;
      score = 0;
      lastScore = 0;
      gameOver = false;
      gameWon = false;
      lastGameWon = false;
      gameContinued = false;
      _hasRecordedPlay = false;
      _addRandomTile();
      _addRandomTile();
    });
  }

  void _undo() {
    if (lastGrid != null && !gameOver) {
      setState(() {
        grid = List.generate(4, (r) => List.from(lastGrid![r]));
        score = lastScore;
        gameWon = lastGameWon;
        lastGrid = null;
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _addRandomTile() {
    List<List<int>> emptyCells = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (grid[r][c] == 0) emptyCells.add([r, c]);
      }
    }

    if (emptyCells.isNotEmpty) {
      var cell = emptyCells[Random().nextInt(emptyCells.length)];
      grid[cell[0]][cell[1]] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _move(int dr, int dc) {
    if (gameOver) return;

    bool moved = false;
    List<List<int>> tempGrid = List.generate(4, (r) => List.from(grid[r]));
    int tempScore = score;
    bool tempGameWon = gameWon;
    
    List<List<int>> nextGrid = List.generate(4, (r) => List.from(grid[r]));

    if (dr != 0) { // Up or Down
      for (int c = 0; c < 4; c++) {
        List<int> column = [];
        for (int r = 0; r < 4; r++) {
          if (nextGrid[r][c] != 0) column.add(nextGrid[r][c]);
        }
        
        if (dr == 1) column = column.reversed.toList(); // Down

        List<int> merged = _merge(column);
        
        if (dr == 1) merged = merged.reversed.toList();
        
        for (int r = 0; r < 4; r++) {
          if (nextGrid[r][c] != merged[r]) moved = true;
          nextGrid[r][c] = merged[r];
        }
      }
    } else { // Left or Right
      for (int r = 0; r < 4; r++) {
        List<int> row = [];
        for (int c = 0; c < 4; c++) {
          if (nextGrid[r][c] != 0) row.add(nextGrid[r][c]);
        }

        if (dc == 1) row = row.reversed.toList(); // Right

        List<int> merged = _merge(row);

        if (dc == 1) merged = merged.reversed.toList();

        for (int c = 0; c < 4; c++) {
          if (nextGrid[r][c] != merged[c]) moved = true;
          nextGrid[r][c] = merged[c];
        }
      }
    }

    if (moved) {
      if (!_hasRecordedPlay) {
        StatsManager().recordGamePlay("2048");
        _hasRecordedPlay = true;
      }
      HapticFeedback.lightImpact();
      setState(() {
        lastGrid = tempGrid;
        lastScore = tempScore;
        lastGameWon = tempGameWon;
        grid = nextGrid;
        _addRandomTile();
        if (score > bestScore) {
          bestScore = score;
          StatsManager().saveBestScore("2048", bestScore, lowerIsBetter: false);
        }
        _checkGameState();
      });
    }
  }

  List<int> _merge(List<int> line) {
    List<int> result = [];
    for (int i = 0; i < line.length; i++) {
      if (i + 1 < line.length && line[i] == line[i + 1]) {
        int newVal = line[i] * 2;
        result.add(newVal);
        score += newVal;
        if (newVal == 2048 && !gameWon) {
          gameWon = true;
          StatsManager().recordWin();
        }
        i++;
      } else {
        result.add(line[i]);
      }
    }
    while (result.length < 4) {
      result.add(0);
    }
    return result;
  }

  void _checkGameState() {
    bool hasEmpty = false;
    for (var row in grid) {
      if (row.contains(0)) {
        hasEmpty = true;
        break;
      }
    }

    if (!hasEmpty) {
      bool canMerge = false;
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          if (r + 1 < 4 && grid[r][c] == grid[r + 1][c]) canMerge = true;
          if (c + 1 < 4 && grid[r][c] == grid[r][c + 1]) canMerge = true;
        }
      }
      if (!canMerge) {
        gameOver = true;
      }
    }
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('SYSTEM PROTOCOLS', style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RuleItem(text: "SWIPE to shift all data tiles in that direction."),
              _RuleItem(text: "IDENTICAL tiles merge into their sum when they collide."),
              _RuleItem(text: "SYNTHESIZE the 2048 core tile to win."),
              _RuleItem(text: "SYSTEM OVERLOAD occurs when no merges or moves remain."),
              _RuleItem(text: "UNDO reverts the system to the previous state."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ACKNOWLEDGED', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) _move(-1, 0);
          else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) _move(1, 0);
          else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) _move(0, -1);
          else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) _move(0, 1);
          else if (event.logicalKey == LogicalKeyboardKey.keyZ && (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) _undo();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: AppBar(
          title: const Text('NEON 2048', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.cyanAccent),
              onPressed: lastGrid == null ? null : _undo,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
              onPressed: _showRules,
            ),
          ],
        ),
        body: Stack(
          children: [
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -100) _move(-1, 0);
                if (details.primaryVelocity! > 100) _move(1, 0);
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < -100) _move(0, -1);
                if (details.primaryVelocity! > 100) _move(0, 1);
              },
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildScoreBoard(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildGrid()),
                  _buildFooterHint(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            if (gameOver) _buildStatusOverlay("SYSTEM OVERLOAD", Colors.pinkAccent, true),
            if (gameWon && !gameContinued) _buildStatusOverlay("CORE ACHIEVED", Colors.greenAccent, false),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("SCORE", score.toString(), Colors.cyanAccent),
          _statItem("BEST", bestScore.toString(), Colors.yellowAccent),
          _statItem("TARGET", "2048", Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
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
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            int r = index ~/ 4;
            int c = index % 4;
            int val = grid[r][c];
            return _buildTile(r, c, val);
          },
        ),
      ),
    );
  }

  Widget _buildTile(int r, int c, int val) {
    Color color = _getTileColor(val);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Container(
        key: ValueKey('tile_${r}_${c}_$val'),
        decoration: BoxDecoration(
          color: val == 0 ? Colors.white.withOpacity(0.02) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: val == 0 ? null : Border.all(color: color, width: 2),
          boxShadow: val == 0 ? [] : [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
          ],
        ),
        child: Center(
          child: Text(
            val == 0 ? "" : val.toString(),
            style: TextStyle(
              color: color,
              fontSize: val > 10000 ? 12 : (val > 1000 ? 16 : 22),
              fontWeight: FontWeight.bold,
              shadows: val == 0 ? [] : [Shadow(color: color, blurRadius: 10)],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTileColor(int val) {
    switch (val) {
      case 2: return Colors.cyanAccent;
      case 4: return Colors.blueAccent;
      case 8: return Colors.indigoAccent;
      case 16: return Colors.purpleAccent;
      case 32: return Colors.deepPurpleAccent;
      case 64: return Colors.pinkAccent;
      case 128: return Colors.redAccent;
      case 256: return Colors.orangeAccent;
      case 512: return Colors.amberAccent;
      case 1024: return Colors.yellowAccent;
      case 2048: return Colors.greenAccent;
      case 4096: return Colors.tealAccent;
      default: return Colors.white;
    }
  }

  Widget _buildStatusOverlay(String title, Color color, bool isGameOver) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4, shadows: [Shadow(color: color, blurRadius: 20)])),
            const SizedBox(height: 40),
            if (!isGameOver)
              _overlayButton("CONTINUE", Colors.greenAccent, () => setState(() => gameContinued = true)),
            const SizedBox(height: 20),
            _overlayButton("REBOOT", Colors.cyanAccent, _resetGame),
          ],
        ),
      ),
    );
  }

  Widget _overlayButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
    );
  }

  Widget _buildFooterHint() {
    return const Text(
      "SWIPE TO MERGE SYSTEM DATA",
      style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }
}
