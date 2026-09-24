import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class CheckersGame extends StatefulWidget {
  const CheckersGame({super.key});

  @override
  State<CheckersGame> createState() => _CheckersGameState();
}

class _CheckersGameState extends State<CheckersGame> {
  late List<List<String>> board;
  bool isCyanTurn = true;
  String? winner;
  bool isAiThinking = false;
  
  int? selectedRow;
  int? selectedCol;
  List<List<int>> validMoves = [];
  
  bool isAiMode = true;
  int aiLevel = 5; 
  bool hasGameStarted = false;
  
  int cyanCaptures = 0;
  int pinkCaptures = 0;

  List<List<List<String>>> history = [];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      board = _createInitialBoard();
      isCyanTurn = true;
      winner = null;
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      cyanCaptures = 0;
      pinkCaptures = 0;
      isAiThinking = false;
      history = [_copyBoard(board)];
      hasGameStarted = false;
    });
  }

  List<List<String>> _createInitialBoard() {
    return List.generate(8, (r) {
      return List.generate(8, (c) {
        if ((r + c) % 2 != 0) {
          if (r < 3) return 'P'; // Pink (AI)
          if (r > 4) return 'C'; // Cyan (Player)
        }
        return '';
      });
    });
  }

  List<List<String>> _copyBoard(List<List<String>> original) {
    return original.map((row) => List<String>.from(row)).toList();
  }

  void _undo() {
    if (history.length > 1 && winner == null && !isAiThinking) {
      HapticFeedback.mediumImpact();
      setState(() {
        if (isAiMode && history.length > 2) {
          history.removeLast();
          history.removeLast();
        } else {
          history.removeLast();
        }
        board = _copyBoard(history.last);
        isCyanTurn = isAiMode ? true : (history.length % 2 != 0);
        
        // Recalculate captures based on current board state
        int cPieces = 0;
        int pPieces = 0;
        for (var row in board) {
          for (var cell in row) {
            if (cell.startsWith('C')) cPieces++;
            if (cell.startsWith('P')) pPieces++;
          }
        }
        cyanCaptures = 12 - pPieces;
        pinkCaptures = 12 - cPieces;

        if (history.length == 1) hasGameStarted = false;
      });
    }
  }

  void _handleTap(int r, int c) {
    if (winner != null || isAiThinking) return;
    
    String cell = board[r][c];
    String currentPrefix = isCyanTurn ? 'C' : 'P';

    if (cell.startsWith(currentPrefix)) {
      setState(() {
        selectedRow = r;
        selectedCol = c;
        validMoves = _getValidMovesForPiece(board, r, c, mustJump: _mustJump(board, isCyanTurn));
      });
      HapticFeedback.lightImpact();
    } else if (selectedRow != null && selectedCol != null) {
      bool isValid = validMoves.any((m) => m[0] == r && m[1] == c);
      if (isValid) {
        _makeMove(selectedRow!, selectedCol!, r, c);
      } else {
        setState(() {
          selectedRow = null;
          selectedCol = null;
          validMoves = [];
        });
      }
    }
  }

  void _makeMove(int fromR, int fromC, int toR, int toC) {
    HapticFeedback.mediumImpact();
    setState(() {
      hasGameStarted = true;
      _executeMove(board, fromR, fromC, toR, toC);
      history.add(_copyBoard(board));
      
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      
      _checkGameState();
      
      if (winner == null) {
        isCyanTurn = !isCyanTurn;
        if (isAiMode && !isCyanTurn) {
          isAiThinking = true;
          // Reduced delay from 600ms to 200ms for faster play
          Future.delayed(const Duration(milliseconds: 200), () => _aiMove());
        }
      }
    });
  }

  void _executeMove(List<List<String>> b, int fromR, int fromC, int toR, int toC) {
    String piece = b[fromR][fromC];

    if ((toR - fromR).abs() == 2) {
      int midR = (fromR + toR) ~/ 2;
      int midC = (fromC + toC) ~/ 2;
      b[midR][midC] = '';
    }
    
    b[toR][toC] = piece;
    b[fromR][fromC] = '';

    if (piece == 'C' && toR == 0) b[toR][toC] = 'CK';
    if (piece == 'P' && toR == 7) b[toR][toC] = 'PK';
  }

  void _checkGameState() {
    // Recalculate captures based on current board state to avoid corruption during AI simulation
    int cPieces = 0;
    int pPieces = 0;
    for (var row in board) {
      for (var cell in row) {
        if (cell.startsWith('C')) cPieces++;
        if (cell.startsWith('P')) pPieces++;
      }
    }
    cyanCaptures = 12 - pPieces;
    pinkCaptures = 12 - cPieces;

    bool cyanHasMoves = _getAllValidMoves(board, true).isNotEmpty;
    bool pinkHasMoves = _getAllValidMoves(board, false).isNotEmpty;

    if (cyanCaptures >= 12 || !pinkHasMoves) {
      winner = 'CYAN';
      StatsManager().recordWin();
    } else if (pinkCaptures >= 12 || !cyanHasMoves) {
      winner = 'PINK';
    }
  }

  void _aiMove() {
    if (winner != null || isCyanTurn) {
      setState(() => isAiThinking = false);
      return;
    }
    
    List<List<int>> bestMove;
    int depth;
    // Adjusted depths for faster performance while maintaining challenge
    if (aiLevel == 10) depth = 8;
    else if (aiLevel == 9) depth = 7;
    else if (aiLevel == 8) depth = 7;
    else if (aiLevel == 7) depth = 6;
    else if (aiLevel == 6) depth = 6;
    else if (aiLevel == 5) depth = 5;
    else if (aiLevel >= 3) depth = 4;
    else depth = 3;
    
    if (aiLevel < 4 && Random().nextDouble() > (aiLevel / 5.0)) {
      bestMove = _getRandomMove();
    } else {
      bestMove = _getBestMove(depth);
    }

    if (bestMove.isNotEmpty) {
      setState(() => isAiThinking = false);
      _makeMove(bestMove[0][0], bestMove[0][1], bestMove[1][0], bestMove[1][1]);
    } else {
      setState(() {
        isAiThinking = false;
        _checkGameState();
      });
    }
  }

  List<List<int>> _getRandomMove() {
    List<List<List<int>>> allMoves = _getAllValidMoves(board, false);
    if (allMoves.isEmpty) return [];
    return allMoves[Random().nextInt(allMoves.length)];
  }

  List<List<int>> _getBestMove(int depth) {
    double bestValue = -1000000;
    List<List<int>> move = [];
    var allMoves = _getAllValidMoves(board, false);

    allMoves.sort((a, b) {
      bool aIsJump = (a[0][0] - a[1][0]).abs() == 2;
      bool bIsJump = (b[0][0] - b[1][0]).abs() == 2;
      if (aIsJump && !bIsJump) return -1;
      if (!aIsJump && bIsJump) return 1;
      return 0;
    });

    for (var m in allMoves) {
      var tempBoard = _copyBoard(board);
      _executeMove(tempBoard, m[0][0], m[0][1], m[1][0], m[1][1]);
      double boardValue = _minimax(tempBoard, depth - 1, -1000000, 1000000, false);
      if (boardValue > bestValue) {
        bestValue = boardValue;
        move = m;
      }
    }
    return move;
  }

  double _minimax(List<List<String>> b, int depth, double alpha, double beta, bool isMaximizing) {
    if (depth == 0) return _evaluateBoard(b);
    
    var moves = _getAllValidMoves(b, !isMaximizing);
    if (moves.isEmpty) return isMaximizing ? -100000 : 100000;

    if (isMaximizing) {
      double best = -1000000;
      for (var m in moves) {
        var nextB = _copyBoard(b);
        _executeMove(nextB, m[0][0], m[0][1], m[1][0], m[1][1]);
        best = max(best, _minimax(nextB, depth - 1, alpha, beta, false));
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      double best = 1000000;
      for (var m in moves) {
        var nextB = _copyBoard(b);
        _executeMove(nextB, m[0][0], m[0][1], m[1][0], m[1][1]);
        best = min(best, _minimax(nextB, depth - 1, alpha, beta, true));
        beta = min(beta, best);
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  double _evaluateBoard(List<List<String>> b) {
    double score = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String p = b[r][c];
        if (p == '') continue;

        bool isPink = p.startsWith('P');
        bool isKing = p.endsWith('K');
        double val = isKing ? 500 : 100;

        // Position bonuses
        if (c >= 2 && c <= 5 && r >= 2 && r <= 5) val += 20; // Center control
        if (c == 0 || c == 7) val += 15; // Edge safety (harder to jump)
        
        if (!isKing) {
          // Progress bonus
          val += isPink ? r * 10 : (7 - r) * 10;
          
          // Back row protection (preventing enemy kings)
          if (isPink && r == 0) val += 50;
          if (!isPink && r == 7) val += 50;
        }

        if (isPink) score += val;
        else score -= val;
      }
    }
    return score;
  }

  bool _mustJump(List<List<String>> b, bool forCyan) {
    String prefix = forCyan ? 'C' : 'P';
    for (int r=0; r<8; r++) {
      for (int c=0; c<8; c++) {
        if (b[r][c].startsWith(prefix)) {
          var moves = _getValidMovesForPiece(b, r, c);
          if (moves.any((m) => (m[0] - r).abs() == 2)) return true;
        }
      }
    }
    return false;
  }
  
  List<List<List<int>>> _getAllValidMoves(List<List<String>> b, bool forCyan) {
    List<List<List<int>>> allMoves = [];
    String prefix = forCyan ? 'C' : 'P';
    bool mustJump = _mustJump(b, forCyan);
    
    for (int r=0; r<8; r++) {
      for (int c=0; c<8; c++) {
        if (b[r][c].startsWith(prefix)) {
          var moves = _getValidMovesForPiece(b, r, c, mustJump: mustJump);
          for (var m in moves) {
            allMoves.add([[r,c], m]);
          }
        }
      }
    }
    return allMoves;
  }

  List<List<int>> _getValidMovesForPiece(List<List<String>> b, int r, int c, {bool mustJump = false}) {
    List<List<int>> moves = [];
    List<List<int>> jumps = [];
    String piece = b[r][c];
    if (piece == '') return [];
    bool isKing = piece.endsWith('K');
    bool isCyan = piece.startsWith('C');
    
    List<int> rowDirs = isKing ? [-1, 1] : [isCyan ? -1 : 1];
    for (int rd in rowDirs) {
      for (int cd in [-1, 1]) {
        int nr = r + rd;
        int nc = c + cd;
        if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8 && b[nr][nc] == '') {
          moves.add([nr, nc]);
        }
        
        int endR = r + 2 * rd;
        int endC = c + 2 * cd;
        if (endR >= 0 && endR < 8 && endC >= 0 && endC < 8) {
          String midPiece = b[r + rd][c + cd];
          if (midPiece != '' && !midPiece.startsWith(isCyan ? 'C' : 'P') && b[endR][endC] == '') {
            jumps.add([endR, endC]);
          }
        }
      }
    }
    return mustJump ? jumps : (jumps.isNotEmpty ? jumps : moves);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON CHECKERS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildScoreBoard(),
            const SizedBox(height: 10),
            _buildModeSelector(),
            if (isAiMode) _buildDifficultySelector(),
            const SizedBox(height: 20),
            _buildStatusHeader(),
            const SizedBox(height: 10),
            _buildBoard(),
            const SizedBox(height: 20),
            _buildControls(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreItem("CYAN CAPTURES", cyanCaptures, Colors.cyanAccent),
          _scoreItem("PINK CAPTURES", pinkCaptures, Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
        Text("$score / 12", style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _modeToggleItem("VS AI", isAiMode, () => _changeMode(true)),
          _modeToggleItem("2 PLAYER", !isAiMode, () => _changeMode(false)),
        ],
      ),
    );
  }

  Widget _modeToggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                letterSpacing: 1.2
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeMode(bool ai) {
    if (hasGameStarted) {
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
                  isAiMode = ai;
                });
                _resetGame();
              }, 
              child: const Text("CONFIRM")
            ),
          ],
        ),
      );
    } else {
      setState(() => isAiMode = ai);
    }
  }

  Widget _buildDifficultySelector() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AI DIFFICULTY", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("LEVEL $aiLevel", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withOpacity(0.2),
            ),
            child: Slider(
              value: aiLevel.toDouble(),
              min: 1, max: 10, divisions: 9,
              onChanged: (val) {
                if (!hasGameStarted) {
                  setState(() => aiLevel = val.toInt());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    if (isAiThinking) {
      return const Column(
        children: [
          Text("AI IS THINKING...", style: TextStyle(fontSize: 20, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          SizedBox(width: 150, child: LinearProgressIndicator(color: Colors.pinkAccent, backgroundColor: Colors.white10)),
        ],
      );
    }

    String status = winner == null 
      ? "TURN: ${isCyanTurn ? 'CYAN' : 'PINK'}" 
      : "WINNER: $winner";
    Color statusColor = winner == null 
      ? (isCyanTurn ? Colors.cyanAccent : Colors.pinkAccent)
      : Colors.yellowAccent;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        status,
        key: ValueKey(status),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: statusColor, shadows: [
          Shadow(color: statusColor, blurRadius: 10)
        ]),
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            int r = index ~/ 8;
            int c = index % 8;
            bool isDark = (r + c) % 2 != 0;
            bool isSelected = selectedRow == r && selectedCol == c;
            bool isValidMove = validMoves.any((m) => m[0] == r && m[1] == c);
            
            return GestureDetector(
              onTap: () => isDark ? _handleTap(r, c) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white10,
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isValidMove)
                      Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withOpacity(0.5),
                        ),
                      ),
                    if (board[r][c] != '') 
                      _buildPiece(board[r][c]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPiece(String piece) {
    Color color = piece.startsWith('C') ? Colors.cyanAccent : Colors.pinkAccent;
    bool isKing = piece.endsWith('K');
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.8),
        border: Border.all(color: Colors.black45, width: 2),
        boxShadow: [BoxShadow(color: color, blurRadius: 10)],
      ),
      child: isKing ? const Icon(Icons.workspace_premium, color: Colors.white, size: 20) : null,
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _neonButton(Icons.undo, "UNDO", _undo, Colors.orangeAccent, history.length > 1 && winner == null && !isAiThinking),
        _neonButton(Icons.refresh, "RESET", _resetGame, Colors.cyanAccent, !isAiThinking),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT NEON CHECKERS", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "A futuristic take on the classic game of Checkers. Move your pieces diagonally to capture enemy tokens. Reach the last row to become a King! Play against the system AI with adjustable difficulty or a local opponent.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}
