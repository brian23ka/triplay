import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChessGame extends StatefulWidget {
  const ChessGame({super.key});

  @override
  State<ChessGame> createState() => _ChessGameState();
}

class _ChessGameState extends State<ChessGame> {
  late List<List<String>> board;
  bool isWhiteTurn = true;
  String? winner;
  
  int? selectedRow;
  int? selectedCol;
  List<List<int>> validMoves = [];
  
  bool isAiMode = true;
  int aiLevel = 5; // 1 to 10
  bool hasGameStarted = false;
  
  int whiteWins = 0;
  int blackWins = 0;

  List<String> cyanCaptured = []; // Pieces captured BY Cyan (White)
  List<String> pinkCaptured = []; // Pieces captured BY Pink (Black)

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      board = _createInitialBoard();
      isWhiteTurn = true;
      winner = null;
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      cyanCaptured = [];
      pinkCaptured = [];
      history = [{
        'board': _copyBoard(board),
        'cyanCaptured': List<String>.from(cyanCaptured),
        'pinkCaptured': List<String>.from(pinkCaptured),
      }];
      hasGameStarted = false;
    });
  }

  List<List<String>> _createInitialBoard() {
    List<List<String>> b = List.generate(8, (_) => List.filled(8, ''));
    List<String> pieces = ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R'];
    for (int i = 0; i < 8; i++) {
      b[0][i] = 'b${pieces[i]}';
      b[7][i] = 'w${pieces[i]}';
      b[1][i] = 'bP';
      b[6][i] = 'wP';
    }
    return b;
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
        var state = history.last;
        board = _copyBoard(state['board']);
        cyanCaptured = List<String>.from(state['cyanCaptured']);
        pinkCaptured = List<String>.from(state['pinkCaptured']);
        isWhiteTurn = isAiMode ? true : (history.length % 2 != 0);
        if (history.length == 1) hasGameStarted = false;
      });
    }
  }

  void _handleTap(int r, int c) {
    if (winner != null) return;
    
    String cell = board[r][c];
    String currentPrefix = isWhiteTurn ? 'w' : 'b';

    if (cell.startsWith(currentPrefix)) {
      setState(() {
        selectedRow = r;
        selectedCol = c;
        validMoves = _getValidMoves(board, r, c);
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
      
      history.add({
        'board': _copyBoard(board),
        'cyanCaptured': List<String>.from(cyanCaptured),
        'pinkCaptured': List<String>.from(pinkCaptured),
      });
      
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      
      _checkGameState();
      
      if (winner == null) {
        isWhiteTurn = !isWhiteTurn;
        if (isAiMode && !isWhiteTurn) {
          Future.delayed(const Duration(milliseconds: 400), () => _aiMove());
        }
      }
    });
  }

  void _executeMove(List<List<String>> b, int fromR, int fromC, int toR, int toC) {
    String piece = b[fromR][fromC];
    String target = b[toR][toC];

    if (target != '') {
      if (target.startsWith('w')) {
        pinkCaptured.add(target.substring(1));
      } else {
        cyanCaptured.add(target.substring(1));
      }
    }

    if (piece == 'wP' && toR == 0) piece = 'wQ';
    if (piece == 'bP' && toR == 7) piece = 'bQ';
    
    b[toR][toC] = piece;
    b[fromR][fromC] = '';
  }

  void _checkGameState() {
    bool whiteKing = false;
    bool blackKing = false;
    for (var row in board) {
      for (var cell in row) {
        if (cell == 'wK') whiteKing = true;
        if (cell == 'bK') blackKing = true;
      }
    }

    if (!whiteKing) {
      winner = 'PINK';
      blackWins++;
    } else if (!blackKing) {
      winner = 'CYAN';
      whiteWins++;
    }
  }

  void _aiMove() {
    if (winner != null || isWhiteTurn) return;
    
    List<List<int>> bestMove;
    int depth = 3;
    if (aiLevel >= 8) depth = 4;
    if (aiLevel >= 10) depth = 5;
    
    if (aiLevel < 7 && Random().nextDouble() > (aiLevel / 10.0)) {
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
    List<List<List<int>>> allMoves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c].startsWith('b')) {
          var moves = _getValidMoves(board, r, c);
          for (var m in moves) {
            allMoves.add([[r, c], m]);
          }
        }
      }
    }
    if (allMoves.isEmpty) return [];
    return allMoves[Random().nextInt(allMoves.length)];
  }

  List<List<int>> _getBestMove(int depth) {
    double bestValue = -99999;
    List<List<int>> move = [];
    
    var allPossible = <List<List<int>> >[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c].startsWith('b')) {
          var moves = _getValidMoves(board, r, c);
          for (var m in moves) {
            allPossible.add([[r, c], m]);
          }
        }
      }
    }

    allPossible.sort((a, b) {
      String targetA = board[a[1][0]][a[1][1]];
      String targetB = board[b[1][0]][b[1][1]];
      if (targetA != '' && targetB == '') return -1;
      if (targetA == '' && targetB != '') return 1;
      return 0;
    });

    for (var m in allPossible) {
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
    
    if (isMaximizing) {
      double best = -99999;
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (b[r][c].startsWith('b')) {
            var moves = _getValidMoves(b, r, c);
            for (var m in moves) {
              var nextB = _copyBoard(b);
              _executeMove(nextB, r, c, m[0], m[1]);
              best = max(best, _minimax(nextB, depth - 1, alpha, beta, false));
              alpha = max(alpha, best);
              if (beta <= alpha) break;
            }
          }
        }
      }
      return best;
    } else {
      double best = 99999;
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (b[r][c].startsWith('w')) {
            var moves = _getValidMoves(b, r, c);
            for (var m in moves) {
              var nextB = _copyBoard(b);
              _executeMove(nextB, r, c, m[0], m[1]);
              best = min(best, _minimax(nextB, depth - 1, alpha, beta, true));
              beta = min(beta, best);
              if (beta <= alpha) break;
            }
          }
        }
      }
      return best;
    }
  }

  double _evaluateBoard(List<List<String>> b) {
    double total = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String p = b[r][c];
        if (p == '') continue;
        bool isWhite = p.startsWith('w');
        double val = 0;
        switch (p.substring(1)) {
          case 'P': val = 1; break;
          case 'N': val = 3; break;
          case 'B': val = 3; break;
          case 'R': val = 5; break;
          case 'Q': val = 9; break;
          case 'K': val = 100; break;
        }
        total += isWhite ? -val : val;
      }
    }
    return total;
  }

  List<List<int>> _getValidMoves(List<List<String>> b, int r, int c) {
    String piece = b[r][c];
    if (piece == '') return [];
    String type = piece.substring(1);
    bool isWhite = piece.startsWith('w');
    List<List<int>> moves = [];

    void addIfValid(int nr, int nc) {
      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        if (b[nr][nc] == '' || b[nr][nc].startsWith(isWhite ? 'b' : 'w')) {
          moves.add([nr, nc]);
        }
      }
    }

    switch (type) {
      case 'P':
        int dir = isWhite ? -1 : 1;
        if (r + dir >= 0 && r + dir < 8 && b[r + dir][c] == '') {
          moves.add([r + dir, c]);
          if ((isWhite && r == 6) || (!isWhite && r == 1)) {
            if (b[r + 2 * dir][c] == '') moves.add([r + 2 * dir, c]);
          }
        }
        for (int dc in [-1, 1]) {
          int nr = r + dir;
          int nc = c + dc;
          if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
            if (b[nr][nc] != '' && b[nr][nc].startsWith(isWhite ? 'b' : 'w')) {
              moves.add([nr, nc]);
            }
          }
        }
        break;
      case 'N':
        List<List<int>> jumps = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]];
        for (var j in jumps) addIfValid(r + j[0], c + j[1]);
        break;
      case 'B':
        _addSlidingMoves(b, r, c, [[-1,-1],[-1,1],[1,-1],[1,1]], moves, isWhite);
        break;
      case 'R':
        _addSlidingMoves(b, r, c, [[-1,0],[1,0],[0,-1],[0,1]], moves, isWhite);
        break;
      case 'Q':
        _addSlidingMoves(b, r, c, [[-1,-1],[-1,1],[1,-1],[1,1],[-1,0],[1,0],[0,-1],[0,1]], moves, isWhite);
        break;
      case 'K':
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr != 0 || dc != 0) addIfValid(r + dr, c + dc);
          }
        }
        break;
    }
    return moves;
  }

  void _addSlidingMoves(List<List<String>> b, int r, int c, List<List<int>> dirs, List<List<int>> moves, bool isWhite) {
    for (var d in dirs) {
      int nr = r + d[0];
      int nc = c + d[1];
      while (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        if (b[nr][nc] == '') {
          moves.add([nr, nc]);
        } else {
          if (b[nr][nc].startsWith(isWhite ? 'b' : 'w')) moves.add([nr, nc]);
          break;
        }
        nr += d[0];
        nc += d[1];
      }
    }
  }

  int _calculateMaterial(List<String> captured) {
    int total = 0;
    for (var p in captured) {
      switch (p) {
        case 'P': total += 1; break;
        case 'N': total += 3; break;
        case 'B': total += 3; break;
        case 'R': total += 5; break;
        case 'Q': total += 9; break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    int cyanMaterial = _calculateMaterial(cyanCaptured);
    int pinkMaterial = _calculateMaterial(pinkCaptured);
    int advantage = cyanMaterial - pinkMaterial;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON CHESS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildScoreBoard(advantage),
            _buildCaptureBoard(),
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

  Widget _buildScoreBoard(int advantage) {
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
          _scoreItem("CYAN", whiteWins, Colors.cyanAccent, advantage > 0 ? "+$advantage" : ""),
          _scoreItem("PINK", blackWins, Colors.pinkAccent, advantage < 0 ? "+${advantage.abs()}" : ""),
        ],
      ),
    );
  }

  Widget _buildCaptureBoard() {
    Map<String, int> cyanGroups = {};
    for (var p in cyanCaptured) cyanGroups[p] = (cyanGroups[p] ?? 0) + 1;
    Map<String, int> pinkGroups = {};
    for (var p in pinkCaptured) pinkGroups[p] = (pinkGroups[p] ?? 0) + 1;

    List<String> order = ['Q', 'R', 'B', 'N', 'P'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              spacing: 4,
              children: order.where((type) => cyanGroups.containsKey(type)).map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCapturedPieceIcon(type, Colors.cyanAccent),
                    if (cyanGroups[type]! > 1) 
                      Text('x${cyanGroups[type]}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: order.where((type) => pinkGroups.containsKey(type)).map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pinkGroups[type]! > 1) 
                      Text('x${pinkGroups[type]}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    _buildCapturedPieceIcon(type, Colors.pinkAccent),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedPieceIcon(String type, Color color) {
    IconData icon;
    switch (type) {
      case 'P': icon = Icons.person; break;
      case 'R': icon = Icons.fort; break;
      case 'N': icon = Icons.psychology; break;
      case 'B': icon = Icons.navigation; break;
      case 'Q': icon = Icons.diamond; break;
      default: icon = Icons.circle;
    }
    return Icon(icon, color: color.withOpacity(0.6), size: 18);
  }

  Widget _scoreItem(String label, int score, Color color, String materialAdv) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("$score", style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            if (materialAdv.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(materialAdv, style: TextStyle(color: Colors.greenAccent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
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
                setState(() => isAiMode = ai);
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
      ? "TURN: ${isWhiteTurn ? 'CYAN' : 'PINK'}" 
      : "WINNER: $winner";
    Color statusColor = winner == null 
      ? (isWhiteTurn ? Colors.cyanAccent : Colors.pinkAccent)
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
          itemCount: 64,
          itemBuilder: (context, index) {
            int r = index ~/ 8;
            int c = index % 8;
            bool isDark = (r + c) % 2 != 0;
            String piece = board[r][c];
            bool isSelected = selectedRow == r && selectedCol == c;
            bool isValidMove = validMoves.any((m) => m[0] == r && m[1] == c);

            return GestureDetector(
              onTap: () => _handleTap(r, c),
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
                        width: 12, height: 12,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                    if (piece != '') _buildPieceIcon(piece),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPieceIcon(String p) {
    Color color = p.startsWith('w') ? Colors.cyanAccent : Colors.pinkAccent;
    String type = p.substring(1);
    IconData icon;
    switch (type) {
      case 'P': icon = Icons.person; break; // Pawn
      case 'R': icon = Icons.fort; break; // Rook
      case 'N': icon = Icons.psychology; break; // Knight (using extension as a puzzle piece/horse substitute)
      case 'B': icon = Icons.navigation; break; // Bishop
      case 'Q': icon = Icons.diamond; break; // Queen
      case 'K': icon = Icons.stars; break; // King
      default: icon = Icons.circle;
    }
    
    if (type == 'N') {
      return Transform.rotate(angle: -0.5, child: Icon(Icons.psychology, color: color, size: 24));
    }

    return Icon(icon, color: color, size: 24, shadows: [Shadow(color: color, blurRadius: 10)]);
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
