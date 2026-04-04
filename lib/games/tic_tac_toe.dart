import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ultimate_tic_tac_toe.dart';

class TicTacToeMenu extends StatelessWidget {
  const TicTacToeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON TIC TAC TOE', 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _modeButton(
              context, 
              'CLASSIC NEON', 
              '10 AI Levels | PvP | Undo', 
              Icons.bolt, 
              const FuturisticTicTacToe(),
            ),
            const SizedBox(height: 30),
            _modeButton(
              context, 
              'ULTIMATE GRID', 
              'Nested Boards | Strategic', 
              Icons.grid_4x4, 
              const UltimateTicTacToeGame(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(BuildContext context, String title, String subtitle, IconData icon, Widget game) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.cyanAccent,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.cyanAccent, width: 2),
          ),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (context) => game));
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.cyanAccent.withOpacity(0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FuturisticTicTacToe extends StatefulWidget {
  const FuturisticTicTacToe({super.key});

  @override
  State<FuturisticTicTacToe> createState() => _FuturisticTicTacToeState();
}

class _FuturisticTicTacToeState extends State<FuturisticTicTacToe> {
  List<String> board = List.filled(9, '');
  bool xTurn = true;
  String winner = '';
  List<int> winningLine = [];
  bool isAiMode = true;
  int aiLevel = 5;
  List<List<String>> history = [];
  bool hasGameStarted = false;
  
  // Stats
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  
  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      xTurn = true;
      winner = '';
      winningLine = [];
      history = [List.from(board)];
      hasGameStarted = false;
    });
  }

  void _undo() {
    if (history.length > 1 && winner == '') {
      HapticFeedback.mediumImpact();
      setState(() {
        if (isAiMode && history.length > 2) {
          history.removeLast();
          history.removeLast();
        } else {
          history.removeLast();
        }
        board = List.from(history.last);
        xTurn = isAiMode ? true : (history.length % 2 == 0 ? false : true);
        if (history.length == 1) hasGameStarted = false;
      });
    }
  }

  void _handleTap(int index) {
    if (board[index] != '' || winner != '') return;

    HapticFeedback.lightImpact();
    setState(() {
      hasGameStarted = true;
      board[index] = xTurn ? 'X' : 'O';
      history.add(List.from(board));
      _checkWinner();
      
      if (winner == '') {
        xTurn = !xTurn;
        if (isAiMode && !xTurn) {
          Future.delayed(const Duration(milliseconds: 600), () => _aiMove());
        }
      }
    });
  }

  void _aiMove() {
    if (winner != '' || xTurn) return;
    
    int move;
    double perfectMoveProbability = (aiLevel - 1) / 9.0;
    
    if (Random().nextDouble() < perfectMoveProbability) {
      move = _getBestMove();
    } else {
      move = _getRandomMove();
    }

    if (move != -1) {
      setState(() {
        board[move] = 'O';
        history.add(List.from(board));
        _checkWinner();
        if (winner == '') xTurn = true;
      });
    }
  }

  int _getRandomMove() {
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') available.add(i);
    }
    return available.isEmpty ? -1 : available[Random().nextInt(available.length)];
  }

  int _getBestMove() {
    int bestScore = -1000;
    int move = -1;
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') {
        board[i] = 'O';
        int score = _minimax(board, 0, false);
        board[i] = '';
        if (score > bestScore) {
          bestScore = score;
          move = i;
        }
      }
    }
    return move;
  }

  int _minimax(List<String> b, int depth, bool isMaximizing) {
    var res = _checkWinnerState(b);
    if (res['winner'] == 'O') return 10 - depth;
    if (res['winner'] == 'X') return depth - 10;
    if (res['winner'] == 'Draw') return 0;

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        if (b[i] == '') {
          b[i] = 'O';
          bestScore = max(_minimax(b, depth + 1, false), bestScore);
          b[i] = '';
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        if (b[i] == '') {
          b[i] = 'X';
          bestScore = min(_minimax(b, depth + 1, true), bestScore);
          b[i] = '';
        }
      }
      return bestScore;
    }
  }

  Map<String, dynamic> _checkWinnerState(List<String> b) {
    List<List<int>> lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    for (var l in lines) {
      if (b[l[0]] != '' && b[l[0]] == b[l[1]] && b[l[0]] == b[l[2]]) {
        return {'winner': b[l[0]], 'line': l};
      }
    }
    if (!b.contains('')) return {'winner': 'Draw', 'line': []};
    return {'winner': '', 'line': []};
  }

  void _checkWinner() {
    var res = _checkWinnerState(board);
    if (res['winner'] != '') {
      HapticFeedback.heavyImpact();
      setState(() {
        winner = res['winner'];
        winningLine = List<int>.from(res['line']);
        if (winner == 'X') xWins++;
        else if (winner == 'O') oWins++;
        else draws++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON CLASSIC', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
          _scoreItem("PLAYER X", xWins, Colors.cyanAccent),
          _scoreItem("DRAWS", draws, Colors.yellowAccent),
          _scoreItem(isAiMode ? "CPU O" : "PLAYER O", oWins, Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
        Text("$score", style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
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
          content: const Text("This will reset your current game and scores.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isAiMode = ai;
                  xWins = 0; oWins = 0; draws = 0;
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
    String status = winner == '' 
      ? "TURN: ${xTurn ? 'X' : 'O'}" 
      : (winner == 'Draw' ? "SYSTEM DRAW" : "WINNER: $winner");
    Color statusColor = winner == '' 
      ? (xTurn ? Colors.cyanAccent : Colors.pinkAccent)
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
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            String val = board[index];
            bool isWinningCell = winningLine.contains(index);
            Color color = val == 'X' ? Colors.cyanAccent : Colors.pinkAccent;
            if (winner != '' && !isWinningCell && winner != 'Draw') color = color.withOpacity(0.2);

            return GestureDetector(
              onTap: () => _handleTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isWinningCell ? Colors.yellowAccent : (val == '' ? Colors.white10 : color),
                    width: isWinningCell ? 4 : 2,
                  ),
                  boxShadow: val == '' ? [] : [
                    BoxShadow(color: (isWinningCell ? Colors.yellowAccent : color).withOpacity(0.3), 
                      blurRadius: isWinningCell ? 15 : 8, spreadRadius: 1)
                  ],
                ),
                child: Center(
                  child: Text(
                    val,
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold, color: isWinningCell ? Colors.yellowAccent : color,
                      shadows: [Shadow(color: isWinningCell ? Colors.yellowAccent : color, blurRadius: 15)]
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _neonButton(Icons.undo, "UNDO", _undo, Colors.orangeAccent, history.length > 1 && winner == ''),
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
