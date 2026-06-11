import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UltimateTicTacToeGame extends StatefulWidget {
  const UltimateTicTacToeGame({super.key});

  @override
  State<UltimateTicTacToeGame> createState() => _UltimateTicTacToeGameState();
}

class _UltimateTicTacToeGameState extends State<UltimateTicTacToeGame> {
  late List<List<String>> boards;
  late List<String> boardWinners;
  bool xTurn = true;
  String overallWinner = '';
  int? nextBoardIndex; 
  
  bool isAiMode = true;
  int aiLevel = 5;
  List<Map<String, dynamic>> history = [];
  bool hasGameStarted = false;

  int? _previewBIdx;
  int? _previewCIdx;

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
      boards = List.generate(9, (_) => List.filled(9, ''));
      boardWinners = List.filled(9, '');
      xTurn = true;
      overallWinner = '';
      nextBoardIndex = null;
      _previewBIdx = null;
      _previewCIdx = null;
      hasGameStarted = false;
      history = [_saveState()];
    });
  }

  Map<String, dynamic> _saveState() {
    return {
      'boards': boards.map((b) => List<String>.from(b)).toList(),
      'boardWinners': List<String>.from(boardWinners),
      'xTurn': xTurn,
      'overallWinner': overallWinner,
      'nextBoardIndex': nextBoardIndex,
    };
  }

  void _loadState(Map<String, dynamic> state) {
    boards = (state['boards'] as List).map((b) => List<String>.from(b)).toList();
    boardWinners = List<String>.from(state['boardWinners']);
    xTurn = state['xTurn'];
    overallWinner = state['overallWinner'];
    nextBoardIndex = state['nextBoardIndex'];
    _previewBIdx = null;
    _previewCIdx = null;
  }

  void _undo() {
    if (history.length > 1 && overallWinner == '') {
      HapticFeedback.mediumImpact();
      setState(() {
        if (isAiMode && history.length > 2) {
          history.removeLast();
          history.removeLast();
        } else {
          history.removeLast();
        }
        _loadState(history.last);
        if (history.length == 1) hasGameStarted = false;
      });
    }
  }

  void _handleTap(int bIdx, int cIdx) {
    if (overallWinner != '') return;
    if (nextBoardIndex != null && nextBoardIndex != bIdx) return;
    if (boards[bIdx][cIdx] != '' || boardWinners[bIdx] != '') return;

    HapticFeedback.lightImpact();
    if (_previewBIdx != bIdx || _previewCIdx != cIdx) {
      setState(() {
        _previewBIdx = bIdx;
        _previewCIdx = cIdx;
      });
      return;
    }

    _confirmMove(bIdx, cIdx);
  }

  void _confirmMove(int bIdx, int cIdx) {
    setState(() {
      hasGameStarted = true;
      boards[bIdx][cIdx] = xTurn ? 'X' : 'O';
      
      String bWinner = _checkWinnerStatic(boards[bIdx]);
      if (bWinner != '') {
        boardWinners[bIdx] = bWinner;
        overallWinner = _checkWinnerStatic(boardWinners);
      }

      if (boardWinners[cIdx] == '' && boards[cIdx].contains('')) {
        nextBoardIndex = cIdx;
      } else {
        nextBoardIndex = null;
      }

      if (overallWinner != '') {
        HapticFeedback.heavyImpact();
        if (overallWinner == 'X') xWins++;
        else if (overallWinner == 'O') oWins++;
        else draws++;
      } else {
        xTurn = !xTurn;
        _previewBIdx = null;
        _previewCIdx = null;
        history.add(_saveState());

        if (isAiMode && !xTurn) {
          // Reduced delay from 600ms to 200ms for faster play
          Future.delayed(const Duration(milliseconds: 200), () => _aiMove());
        }
      }
    });
  }

  void _aiMove() {
    if (overallWinner != '') return;

    int bIdx = nextBoardIndex ?? _selectRandomBoard();
    int cIdx;

    double perfectMoveProbability = (aiLevel - 1) / 9.0;
    if (Random().nextDouble() < perfectMoveProbability) {
      cIdx = _getSmartMove(bIdx);
    } else {
      cIdx = _getRandomMove(bIdx);
    }

    if (cIdx != -1) {
      _confirmMove(bIdx, cIdx);
    }
  }

  int _selectRandomBoard() {
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (boardWinners[i] == '' && boards[i].contains('')) available.add(i);
    }
    return available[Random().nextInt(available.length)];
  }

  int _getRandomMove(int bIdx) {
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (boards[bIdx][i] == '') available.add(i);
    }
    return available.isEmpty ? -1 : available[Random().nextInt(available.length)];
  }

  int _getSmartMove(int bIdx) {
    for (int i = 0; i < 9; i++) {
      if (boards[bIdx][i] == '') {
        boards[bIdx][i] = 'O';
        if (_checkWinnerStatic(boards[bIdx]) == 'O') {
          boards[bIdx][i] = '';
          return i;
        }
        boards[bIdx][i] = '';
      }
    }
    for (int i = 0; i < 9; i++) {
      if (boards[bIdx][i] == '') {
        boards[bIdx][i] = 'X';
        if (_checkWinnerStatic(boards[bIdx]) == 'X') {
          boards[bIdx][i] = '';
          return i;
        }
        boards[bIdx][i] = '';
      }
    }
    List<int> prefs = [4, 0, 2, 6, 8, 1, 3, 5, 7];
    for (int i in prefs) {
      if (boards[bIdx][i] == '') {
        if (boardWinners[i] == '' && !_isCloseToWinning(i, 'X')) return i;
      }
    }
    return _getRandomMove(bIdx);
  }

  bool _isCloseToWinning(int bIdx, String player) {
    for (int i = 0; i < 9; i++) {
      if (boards[bIdx][i] == '') {
        boards[bIdx][i] = player;
        if (_checkWinnerStatic(boards[bIdx]) == player) {
          boards[bIdx][i] = '';
          return true;
        }
        boards[bIdx][i] = '';
      }
    }
    return false;
  }

  String _checkWinnerStatic(List<String> b) {
    List<List<int>> lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    for (var l in lines) {
      if (b[l[0]] != '' && b[l[0]] == b[l[1]] && b[l[0]] == b[l[2]]) return b[l[0]];
    }
    if (!b.contains('')) return 'Draw';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('ULTIMATE NEON', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
            _buildInstructionText(),
            const SizedBox(height: 10),
            _buildBigBoard(),
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
          title: const Text("Reset Game?", style: TextStyle(color: Colors.cyanAccent)),
          content: const Text("Changing mode will restart the match and scores.", style: TextStyle(color: Colors.white70)),
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
            ),
            child: Slider(
              value: aiLevel.toDouble(),
              min: 1, max: 10, divisions: 9,
              onChanged: (val) {
                if (!hasGameStarted) setState(() => aiLevel = val.toInt());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    String status = overallWinner == '' 
      ? "TURN: ${xTurn ? 'X' : 'O'}" 
      : (overallWinner == 'Draw' ? "SYSTEM DRAW" : "WINNER: $overallWinner");
    Color color = overallWinner == '' 
      ? (xTurn ? Colors.cyanAccent : Colors.pinkAccent)
      : Colors.yellowAccent;

    return Text(
      status,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, shadows: [Shadow(color: color, blurRadius: 10)]),
    );
  }

  Widget _buildInstructionText() {
    if (overallWinner != '') return const SizedBox(height: 20);
    String text = _previewBIdx == null 
      ? (nextBoardIndex == null ? "Play anywhere" : "Play in highlighted board")
      : "Confirm move to open Board ${_previewCIdx! + 1}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(text, style: TextStyle(color: _previewBIdx != null ? Colors.orangeAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBigBoard() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, bIdx) => _buildSmallBoard(bIdx),
        ),
      ),
    );
  }

  Widget _buildSmallBoard(int bIdx) {
    bool isPlayable = overallWinner == '' && (nextBoardIndex == null || nextBoardIndex == bIdx) && boardWinners[bIdx] == '';
    bool isPreviewTarget = _previewCIdx == bIdx && _previewBIdx != null;
    Color borderColor = isPreviewTarget ? Colors.orangeAccent : (isPlayable ? Colors.cyanAccent : Colors.white10);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: (isPlayable || isPreviewTarget) ? 2 : 1),
        boxShadow: (isPlayable || isPreviewTarget) ? [BoxShadow(color: borderColor.withOpacity(0.2), blurRadius: 5)] : [],
      ),
      child: Stack(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: 9,
            itemBuilder: (context, cIdx) {
              String val = boards[bIdx][cIdx];
              bool isSelected = _previewBIdx == bIdx && _previewCIdx == cIdx;
              Color cellColor = val == 'X' ? Colors.cyanAccent : Colors.pinkAccent;
              
              return GestureDetector(
                onTap: () => _handleTap(bIdx, cIdx),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                    color: isSelected ? Colors.orangeAccent.withOpacity(0.2) : null,
                  ),
                  child: Center(
                    child: Text(
                      val,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cellColor, shadows: val == '' ? [] : [Shadow(color: cellColor, blurRadius: 5)]),
                    ),
                  ),
                ),
              );
            },
          ),
          if (boardWinners[bIdx] != '')
            Center(
              child: Text(
                boardWinners[bIdx],
                style: TextStyle(
                  fontSize: 50, fontWeight: FontWeight.bold,
                  color: (boardWinners[bIdx] == 'X' ? Colors.cyanAccent : Colors.pinkAccent).withOpacity(0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _neonButton(Icons.undo, "UNDO", _undo, Colors.orangeAccent, history.length > 1 && overallWinner == ''),
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
