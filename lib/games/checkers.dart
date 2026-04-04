import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckersGame extends StatefulWidget {
  const CheckersGame({super.key});

  @override
  State<CheckersGame> createState() => _CheckersGameState();
}

class _CheckersGameState extends State<CheckersGame> {
  late List<List<String>> board;
  bool isCyanTurn = true;
  String? winner;
  
  int? selectedRow;
  int? selectedCol;
  List<List<int>> validMoves = [];
  
  bool isAiMode = true;
  int aiLevel = 5; // 1 to 10
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
    if (history.length > 1 && winner == null) {
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
        if (history.length == 1) hasGameStarted = false;
      });
    }
  }

  void _handleTap(int r, int c) {
    if (winner != null) return;
    
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
          Future.delayed(const Duration(milliseconds: 400), () => _aiMove());
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
      if (isCyanTurn) cyanCaptures++; else pinkCaptures++;
    }
    
    b[toR][toC] = piece;
    b[fromR][fromC] = '';

    if (piece == 'C' && toR == 0) b[toR][toC] = 'CK';
    if (piece == 'P' && toR == 7) b[toR][toC] = 'PK';
  }

  void _checkGameState() {
    bool cyanHasMoves = _getAllValidMoves(board, true).isNotEmpty;
    bool pinkHasMoves = _getAllValidMoves(board, false).isNotEmpty;

    if (cyanCaptures == 12 || !pinkHasMoves) {
      winner = 'CYAN';
    } else if (pinkCaptures == 12 || !cyanHasMoves) {
      winner = 'PINK';
    }
  }

  void _aiMove() {
    if (winner != null || isCyanTurn) return;
    
    List<List<int>> bestMove;
    
    // Michael Carson's Depth Scaling
    int depth;
    if (aiLevel >= 10) depth = 10;
    else if (aiLevel >= 9) depth = 9;
    else if (aiLevel >= 8) depth = 8;
    else if (aiLevel >= 6) depth = 6;
    else if (aiLevel >= 4) depth = 4;
    else depth = 3;
    
    if (aiLevel < 8 && Random().nextDouble() > (aiLevel / 10.0)) {
      bestMove = _getRandomMove();
    } else {
      bestMove = _getBestMove(depth);
    }

    if (bestMove.isNotEmpty) {
      _makeMove(bestMove[0][0], bestMove[0][1], bestMove[1][0], bestMove[1][1]);
    } else {
      setState(() => winner = 'CYAN');
    }
  }

  List<List<int>> _getRandomMove() {
    List<List<List<int>>> allMoves = _getAllValidMoves(board, false);
    if (allMoves.isEmpty) return [];
    return allMoves[Random().nextInt(allMoves.length)];
  }

  List<List<int>> _getBestMove(int depth) {
    double bestValue = -double.infinity;
    List<List<int>> move = [];
    var allMoves = _getAllValidMoves(board, false);

    // Heuristic Move Ordering (Michael Carson style)
    allMoves.sort((a, b) {
      // Prioritize jumps
      bool aIsJump = (a[0][0] - a[1][0]).abs() == 2;
      bool bIsJump = (b[0][0] - b[1][0]).abs() == 2;
      if (aIsJump && !bIsJump) return -1;
      if (!aIsJump && bIsJump) return 1;
      
      // Prioritize moves to edges
      bool aToEdge = a[1][1] == 0 || a[1][1] == 7;
      bool bToEdge = b[1][1] == 0 || b[1][1] == 7;
      if (aToEdge && !bToEdge) return -1;
      if (!aToEdge && bToEdge) return 1;

      return 0;
    });

    for (var m in allMoves) {
      var tempBoard = _copyBoard(board);
      _executeMove(tempBoard, m[0][0], m[0][1], m[1][0], m[1][1]);
      double boardValue = _minimax(tempBoard, depth - 1, -100000, 100000, false);
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
    if (moves.isEmpty) return isMaximizing ? -10000 : 10000;

    if (isMaximizing) {
      double best = -double.infinity;
      for (var m in moves) {
        var nextB = _copyBoard(b);
        _executeMove(nextB, m[0][0], m[0][1], m[1][0], m[1][1]);
        best = max(best, _minimax(nextB, depth - 1, alpha, beta, false));
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      double best = double.infinity;
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
    
    // Piece weights
    const double pawnVal = 100;
    const double kingVal = 300;
    const double bridgeVal = 40; // Protection of back row
    const double centerVal = 20; // Center control
    const double mobilityVal = 5; // Possible moves
    
    int pinkPieces = 0;
    int cyanPieces = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String p = b[r][c];
        if (p == '') continue;

        bool isPink = p.startsWith('P');
        bool isKing = p.endsWith('K');
        
        if (isPink) pinkPieces++; else cyanPieces++;

        double val = isKing ? kingVal : pawnVal;

        // Michael Carson's Heuristics:
        
        // 1. Center Control
        if (c >= 2 && c <= 5 && r >= 2 && r <= 5) val += centerVal;
        
        // 2. Edge Safety (but less control)
        if (c == 0 || c == 7) val += 10;

        // 3. Advancement (Michael Carson's 'Tempos')
        if (!isKing) {
          if (isPink) val += (r * 15);
          else val += ((7 - r) * 15);
        }

        // 4. Back Row Bridge (Crucial defensive technique)
        if (!isKing) {
          if (isPink && r == 0) val += bridgeVal;
          if (!isPink && r == 7) val += bridgeVal;
        }

        // 5. Corner Trap squares (Aura of vulnerability)
        if (isKing) {
          if ((r == 0 && c == 7) || (r == 7 && c == 0)) val -= 20;
        }

        if (isPink) score += val;
        else score -= val;
      }
    }

    // 6. Mobility (Michael Carson's technique: active pieces are better)
    score += (_getAllValidMoves(b, false).length * mobilityVal);
    score -= (_getAllValidMoves(b, true).length * mobilityVal);

    return score;
  }

  bool _mustJump(List<List<String>> b, bool forCyan) {
    return _getAllValidMoves(b, forCyan).any((m) => (m[0][0] - m[1][0]).abs() == 2);
  }
  
  List<List<List<int>>> _getAllValidMoves(List<List<String>> b, bool forCyan) {
    List<List<List<int>>> allMoves = [];
    String prefix = forCyan ? 'C' : 'P';
    bool mustJump = false;
    
    for (int r=0; r<8; r++) {
      for (int c=0; c<8; c++) {
        if (b[r][c].startsWith(prefix)) {
           var moves = _getValidMovesForPiece(b, r, c);
           if (moves.any((m) => (m[0] - r).abs() == 2)) {
             mustJump = true;
             break;
           }
        }
      }
      if(mustJump) break;
    }
    
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
    bool isKing = piece.endsWith('K');
    bool isCyan = piece.startsWith('C');
    int dir = isCyan ? -1 : 1;
    
    List<int> rowDirs = isKing ? [-1, 1] : [dir];
    for (int rd in rowDirs) {
      for (int cd in [-1, 1]) {
        int nr = r + rd;
        int nc = c + cd;
        if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8 && b[nr][nc] == '') {
          moves.add([nr, nc]);
        }
        
        int midR = r + rd;
        int midC = c + cd;
        int endR = r + 2 * rd;
        int endC = c + 2 * cd;
        if (endR >= 0 && endR < 8 && endC >= 0 && endC < 8) {
          String midPiece = b[midR][midC];
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
        title: const Text('NEON CHECKERS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        Text("$score / 12", style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
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
              child: Container(
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
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
      child: isKing ? const Icon(Icons.star, color: Colors.white, size: 20) : null,
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _neonButton(Icons.undo, "UNDO", _undo, Colors.orangeAccent, history.length > 1 && winner == null),
        _neonButton(Icons.refresh, "RESET", _resetGame, Colors.cyanAccent, true),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
