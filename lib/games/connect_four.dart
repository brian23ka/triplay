import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triplay/stats_manager.dart';

class ConnectFourGame extends StatefulWidget {
  const ConnectFourGame({super.key});

  @override
  State<ConnectFourGame> createState() => _ConnectFourGameState();
}

class _ConnectFourGameState extends State<ConnectFourGame> with TickerProviderStateMixin {
  static const int rows = 6;
  static const int cols = 7;
  
  late List<List<int>> board; // 0: empty, 1: Operative, 2: Street Boss
  List<List<List<int>>> history = [];
  List<Point<int>> moveHistory = [];
  bool isCyanTurn = true;
  String? winner;
  List<int> winningLine = [];
  bool isAiThinking = false;
  bool hasGameStarted = false;
  int? hoveredColumn; 
  int? lastMoveRow;
  int? lastMoveCol;
  
  int cyanWins = 0;
  int pinkWins = 0;
  int draws = 0;
  
  bool isAiMode = true;
  int aiLevel = 5;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _pulseController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _resetGame();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      board = List.generate(rows, (_) => List.filled(cols, 0));
      history = [];
      moveHistory = [];
      isCyanTurn = true;
      winner = null;
      winningLine = [];
      isAiThinking = false;
      hasGameStarted = false;
      hoveredColumn = null;
      lastMoveRow = null;
      lastMoveCol = null;
    });
  }

  void _confirmReset() {
    if (hasGameStarted && winner == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text("TERMINATE SESSION?", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
          content: const Text("Current tactical data will be purged from the grid.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              }, 
              child: const Text("CONFIRM", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      );
    } else {
      _resetGame();
    }
  }

  void _undo() {
    if (history.isNotEmpty && !isAiThinking) {
      setState(() {
        if (isAiMode) {
          if (winner != null) {
            board = history.removeLast();
            moveHistory.removeLast();
            if (!isCyanTurn && history.isNotEmpty) {
              board = history.removeLast();
              moveHistory.removeLast();
            }
          } else {
            board = history.removeLast();
            moveHistory.removeLast();
            if (history.isNotEmpty) {
              board = history.removeLast();
              moveHistory.removeLast();
            }
          }
          isCyanTurn = true;
        } else {
          board = history.removeLast();
          moveHistory.removeLast();
          isCyanTurn = !isCyanTurn;
        }
        
        winner = null;
        winningLine = [];
        
        if (moveHistory.isNotEmpty) {
          lastMoveRow = moveHistory.last.x;
          lastMoveCol = moveHistory.last.y;
        } else {
          lastMoveRow = null;
          lastMoveCol = null;
          hasGameStarted = false;
        }
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _dropDisc(int col) {
    if (winner != null || isAiThinking || col < 0 || col >= cols) return;

    int row = _getEmptyRow(board, col);
    if (row != -1) {
      HapticFeedback.mediumImpact();
      if (!hasGameStarted) {
        StatsManager().recordGamePlay("STREET CONNECT");
      }
      
      setState(() {
        hasGameStarted = true;
        history.add(List.generate(rows, (r) => List.from(board[r])));
        
        board[row][col] = isCyanTurn ? 1 : 2;
        moveHistory.add(Point(row, col));
        lastMoveRow = row;
        lastMoveCol = col;
        
        List<int>? line = _getWinningLine(board, row, col);
        if (line != null) {
          winningLine = line;
          winner = isCyanTurn ? "OPERATIVE" : "STREET BOSS";
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.heavyImpact());
          
          if (isCyanTurn) {
            cyanWins++;
            StatsManager().recordWin();
          } else {
            pinkWins++;
          }
        } else if (_isBoardFull()) {
          winner = "DRAW";
          draws++;
        } else {
          isCyanTurn = !isCyanTurn;
          if (isAiMode && !isCyanTurn) {
            _startAiThinkingSequence();
          }
        }
      });
    }
  }

  void _startAiThinkingSequence() async {
    setState(() => isAiThinking = true);
    // Slow down for tactical feel
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) _aiMove();
  }

  int _getEmptyRow(List<List<int>> b, int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (b[r][col] == 0) return r;
    }
    return -1;
  }

  bool _isBoardFull() {
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == 0) return false;
    }
    return true;
  }

  List<int>? _getWinningLine(List<List<int>> b, int r, int c) {
    int player = b[r][c];
    if (player == 0) return null;

    List<List<int>> directions = [[0, 1], [1, 0], [1, 1], [1, -1]];
    for (var dir in directions) {
      List<int> line = [r * cols + c];
      for (int i = 1; i < 4; i++) {
        int nr = r + dir[0] * i, nc = c + dir[1] * i;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && b[nr][nc] == player) {
          line.add(nr * cols + nc);
        } else break;
      }
      for (int i = 1; i < 4; i++) {
        int nr = r - dir[0] * i, nc = c - dir[1] * i;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && b[nr][nc] == player) {
          line.add(nr * cols + nc);
        } else break;
      }
      if (line.length >= 4) return line;
    }
    return null;
  }

  void _aiMove() {
    if (winner != null) {
      if (mounted) setState(() => isAiThinking = false);
      return;
    }
    
    int depth = aiLevel >= 9 ? 6 : (aiLevel >= 7 ? 5 : (aiLevel >= 5 ? 4 : (aiLevel >= 3 ? 3 : 2)));
    int bestCol = _getBestMove(depth);
    if (mounted) {
      setState(() => isAiThinking = false);
      if (bestCol != -1) _dropDisc(bestCol);
    }
  }

  int _getBestMove(int depth) {
    int bestScore = -1000000;
    int bestCol = -1;
    List<int> availableCols = [];
    for (int c = 0; c < cols; c++) if (board[0][c] == 0) availableCols.add(c);
    
    availableCols.sort((a, b) => (a - 3).abs().compareTo((b - 3).abs()));

    for (int c in availableCols) {
      int r = _getEmptyRow(board, c);
      board[r][c] = 2;
      int score = _minimax(board, depth - 1, -1000000, 1000000, false, r, c);
      board[r][c] = 0;
      if (score > bestScore) { 
        bestScore = score; 
        bestCol = c; 
      }
    }
    return bestCol;
  }

  int _minimax(List<List<int>> b, int d, int alpha, int beta, bool isMax, int lr, int lc) {
    List<int>? line = _getWinningLine(b, lr, lc);
    if (line != null) return isMax ? -100000 : 100000;
    if (d == 0) return _evaluateBoard(b);

    List<int> avail = [];
    for (int c = 0; c < cols; c++) if (b[0][c] == 0) avail.add(c);
    if (avail.isEmpty) return 0;

    if (isMax) {
      int maxEval = -1000000;
      for (int c in avail) {
        int r = _getEmptyRow(b, c); 
        b[r][c] = 2;
        int eval = _minimax(b, d - 1, alpha, beta, false, r, c);
        b[r][c] = 0; 
        maxEval = max(maxEval, eval); 
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 1000000;
      for (int c in avail) {
        int r = _getEmptyRow(b, c); 
        b[r][c] = 1;
        int eval = _minimax(b, d - 1, alpha, beta, true, r, c);
        b[r][c] = 0; 
        minEval = min(minEval, eval); 
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  int _evaluateBoard(List<List<int>> b) {
    int score = 0;
    for (int r = 0; r < rows; r++) {
      if (b[r][3] == 2) score += 4; 
      else if (b[r][3] == 1) score -= 4;
    }
    score += _scorePos(b, 2) - _scorePos(b, 1);
    return score;
  }

  int _scorePos(List<List<int>> b, int p) {
    int s = 0;
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols - 3; c++) s += _evalWin([b[r][c], b[r][c+1], b[r][c+2], b[r][c+3]], p);
    for (int c = 0; c < cols; c++) for (int r = 0; r < rows - 3; r++) s += _evalWin([b[r][c], b[r+1][c], b[r+2][c], b[r+3][c]], p);
    for (int r = 0; r < rows - 3; r++) for (int c = 0; c < cols - 3; c++) s += _evalWin([b[r][c], b[r+1][c+1], b[r+2][c+2], b[r+3][c+3]], p);
    for (int r = 0; r < rows - 3; r++) for (int c = 3; c < cols; c++) s += _evalWin([b[r][c], b[r+1][c-1], b[r+2][c-2], b[r+3][c-3]], p);
    return s;
  }

  int _evalWin(List<int> w, int p) {
    int s = 0, opp = p == 1 ? 2 : 1;
    int pC = w.where((x) => x == p).length, eC = w.where((x) => x == 0).length, oC = w.where((x) => x == opp).length;
    if (pC == 4) s += 10000; 
    else if (pC == 3 && eC == 1) s += 120; 
    else if (pC == 2 && eC == 2) s += 20;
    
    if (oC == 3 && eC == 1) s -= 980; 
    return s;
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('STREET CONNECT: PROTOCOLS', style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            _RuleItem(text: "Drop data discs into the 7-column grid."),
            _RuleItem(text: "Connect 4 discs in a straight vector."),
            _RuleItem(text: "Vectors: Horizontal, Vertical, or Diagonal."),
            _RuleItem(text: "VS BOSS: 10 levels of strategic depth."),
            _RuleItem(text: "Keys 1-7 for deployment, Ctrl+Z to revert."),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ACKNOWLEDGED', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode, autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.digit1) _dropDisc(0);
          else if (key == LogicalKeyboardKey.digit2) _dropDisc(1);
          else if (key == LogicalKeyboardKey.digit3) _dropDisc(2);
          else if (key == LogicalKeyboardKey.digit4) _dropDisc(3);
          else if (key == LogicalKeyboardKey.digit5) _dropDisc(4);
          else if (key == LogicalKeyboardKey.digit6) _dropDisc(5);
          else if (key == LogicalKeyboardKey.digit7) _dropDisc(6);
          else if (key == LogicalKeyboardKey.keyZ && HardwareKeyboard.instance.isControlPressed) _undo();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: AppBar(
          title: const Text('STREET CONNECT', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent), onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(icon: const Icon(Icons.info_outline, color: Colors.cyanAccent), onPressed: _showRules),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildScoreBoard(),
                const SizedBox(height: 10),
                _buildModeSelector(),
                if (isAiMode) _buildDifficultySelector(),
                const SizedBox(height: 10),
                _buildStatusHeader(),
                const SizedBox(height: 10),
                Expanded(child: _buildBoard()),
                const Text("KEYS 1-7 TO DEPLOY DISCS", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildControls(),
                const SizedBox(height: 20),
              ],
            ),
            if (winner != null) _buildStatusOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("OPERATIVE", cyanWins.toString(), Colors.cyanAccent),
          _statItem("DRAWS", draws.toString(), Colors.yellowAccent),
          _statItem("STREET BOSS", pinkWins.toString(), Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))),
      child: Row(children: [
        _modeToggleItem("STREET BOSS", isAiMode, () {
          if (hasGameStarted && winner == null) _changeMode(true);
          else setState(() { isAiMode = true; _resetGame(); });
        }),
        _modeToggleItem("LOCAL VERSUS", !isAiMode, () {
          if (hasGameStarted && winner == null) _changeMode(false);
          else setState(() { isAiMode = false; _resetGame(); });
        }),
      ]),
    );
  }

  void _changeMode(bool ai) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("CHANGE PROTOCOL?", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: const Text("Changing modes will terminate the current session.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { isAiMode = ai; _resetGame(); });
            }, 
            child: const Text("CONFIRM", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _modeToggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isActive ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(title, style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 10))))));
  }

  Widget _buildDifficultySelector() {
    return Container(
      margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TACTICAL DEPTH", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)), Text("LEVEL $aiLevel", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold))]),
        SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: Colors.cyanAccent, inactiveTrackColor: Colors.white10, thumbColor: Colors.cyanAccent, overlayColor: Colors.cyanAccent.withOpacity(0.2), trackHeight: 2), child: Slider(value: aiLevel.toDouble(), min: 1, max: 10, divisions: 9, onChanged: (val) { if (!hasGameStarted) setState(() => aiLevel = val.toInt()); })),
      ]),
    );
  }

  Widget _buildStatusHeader() {
    if (isAiThinking) return Column(children: [const Text("SCANNING GRID VECTORS...", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)), const SizedBox(height: 8), const SizedBox(width: 150, child: LinearProgressIndicator(color: Colors.pinkAccent, backgroundColor: Colors.white10, minHeight: 2))]);
    
    String status = winner == null ? "VECTOR SCAN: ${isCyanTurn ? 'OPERATIVE' : (isAiMode ? 'STREET BOSS' : 'PLAYER 2')}" : (winner == "DRAW" ? "SYSTEM DRAW" : "WINNER: $winner");
    Color color = isCyanTurn ? Colors.cyanAccent : Colors.pinkAccent;
    if (winner != null) color = Colors.yellowAccent;
    return Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: color, blurRadius: 10)], letterSpacing: 2));
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: cols / rows,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.white10), 
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20)]
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return Positioned(
                    top: _scanController.value * (rows * 50.0), 
                    left: 0, right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
                      ),
                    ),
                  );
                },
              ),
              if (hoveredColumn != null && winner == null && !isAiThinking)
                Positioned.fill(
                  child: Row(
                    children: List.generate(cols, (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: hoveredColumn == index ? Colors.white.withOpacity(0.03) : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    )),
                  ),
                ),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: rows * cols,
                itemBuilder: (context, index) {
                  int r = index ~/ cols, c = index % cols, cell = board[r][c];
                  bool isWinningDisc = winningLine.contains(index);
                  bool isLast = lastMoveRow == r && lastMoveCol == c;
                  
                  return MouseRegion(
                    onEnter: (_) => setState(() => hoveredColumn = c),
                    onExit: (_) => setState(() => hoveredColumn = null),
                    child: GestureDetector(
                      onTap: () => _dropDisc(c),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle, border: Border.all(color: isWinningDisc ? Colors.yellowAccent : (isLast ? Colors.white54 : Colors.white10), width: isWinningDisc ? 2 : (isLast ? 1.5 : 1))),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                            child: cell == 0 ? const SizedBox.shrink() : _buildDisc(cell, isWinningDisc, isLast),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisc(int player, bool isWinning, bool isLast) {
    Color color = player == 1 ? Colors.cyanAccent : Colors.pinkAccent;
    if (isWinning) color = Colors.yellowAccent;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double pulse = isWinning ? 1.0 + (_pulseController.value * 0.18) : 1.0;
        return Transform.scale(
          scale: pulse,
          child: Container(
            key: ValueKey('disc_${player}_${isWinning}_$isLast'),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(isWinning ? 0.9 : 1.0),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color, blurRadius: isWinning ? 20 : 10, spreadRadius: isWinning ? 2 : 1),
                if (isLast && !isWinning) BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 6, spreadRadius: 1),
              ],
            ),
            child: isLast && !isWinning ? Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _neonButton(Icons.undo, "REVERT", _undo, Colors.orangeAccent, history.isNotEmpty && !isAiThinking),
        _neonButton(Icons.refresh, "RESET", _confirmReset, Colors.cyanAccent, !isAiThinking),
      ],
    );
  }

  Widget _neonButton(IconData icon, String label, VoidCallback onPressed, Color color, bool enabled) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    Color color = winner == "DRAW" ? Colors.yellowAccent : (winner == "OPERATIVE" ? Colors.cyanAccent : Colors.pinkAccent);
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner == "DRAW" ? "SYSTEM DRAW" : "$winner VECTOR SECURED", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 4, shadows: [Shadow(color: color, blurRadius: 20)])
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _resetGame, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, 
                foregroundColor: color, 
                side: BorderSide(color: color, width: 2), 
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ), 
              child: const Text("REBOOT GRID", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("• ", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)), Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)))]));
}
