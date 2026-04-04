import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GuessMode { easy, medium, hard, battle }

class NumberGuessGame extends StatefulWidget {
  const NumberGuessGame({super.key});

  @override
  State<NumberGuessGame> createState() => _NumberGuessGameState();
}

class _NumberGuessGameState extends State<NumberGuessGame> with SingleTickerProviderStateMixin {
  GuessMode? selectedMode;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  int _targetNumber = 0;
  int _maxRange = 100;
  int _attempts = 0;
  int _maxAttempts = 0;
  String _message = 'GUESS THE NUMBER';
  String _subMessage = 'ENTER A VALUE';
  bool _gameOver = false;
  List<Map<String, dynamic>> _guessHistory = [];
  
  // Battle Mode
  int _p1Score = 0;
  int _p2Score = 0;
  int _currentPlayer = 1;
  
  // High Scores
  Map<GuessMode, int> _bestScores = {};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);
  }

  void _startGame(GuessMode mode) {
    setState(() {
      selectedMode = mode;
      _gameOver = false;
      _attempts = 0;
      _guessHistory = [];
      _controller.clear();
      
      switch (mode) {
        case GuessMode.easy:
          _maxRange = 50;
          _maxAttempts = 10;
          break;
        case GuessMode.medium:
          _maxRange = 100;
          _maxAttempts = 7;
          break;
        case GuessMode.hard:
          _maxRange = 250;
          _maxAttempts = 6;
          break;
        case GuessMode.battle:
          _maxRange = 100;
          _maxAttempts = 100;
          _currentPlayer = 1;
          break;
      }
      
      _targetNumber = Random().nextInt(_maxRange) + 1;
      _message = 'FIND THE NUMBER';
      _subMessage = '1 TO $_maxRange';
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  void _handleGuess() {
    if (_gameOver) return;
    
    int? guess = int.tryParse(_controller.text);
    if (guess == null || guess < 1 || guess > _maxRange) {
      HapticFeedback.heavyImpact();
      setState(() {
        _subMessage = 'OUT OF RANGE (1-$_maxRange)';
      });
      return;
    }

    setState(() {
      _attempts++;
      _guessHistory.insert(0, {
        'guess': guess,
        'player': _currentPlayer,
      });
      
      if (guess == _targetNumber) {
        _handleWin();
      } else {
        HapticFeedback.lightImpact();
        if (guess < _targetNumber) {
          _message = 'HIGHER! ↑';
          _subMessage = '$guess IS TOO LOW';
        } else {
          _message = 'LOWER! ↓';
          _subMessage = '$guess IS TOO HIGH';
        }
        
        if (selectedMode != GuessMode.battle && _attempts >= _maxAttempts) {
          _handleLoss();
        } else if (selectedMode == GuessMode.battle) {
          _currentPlayer = _currentPlayer == 1 ? 2 : 1;
        }
      }
      _controller.clear();
      _focusNode.requestFocus();
    });
  }

  void _handleWin() {
    HapticFeedback.vibrate();
    _gameOver = true;
    _message = 'CORRECT! 🔥';
    
    if (selectedMode == GuessMode.battle) {
      _subMessage = 'PLAYER $_currentPlayer WINS';
      if (_currentPlayer == 1) _p1Score++; else _p2Score++;
    } else {
      _subMessage = 'FOUND IN $_attempts ATTEMPTS';
      if (_bestScores[selectedMode!] == null || _attempts < _bestScores[selectedMode!]!) {
        _bestScores[selectedMode!] = _attempts;
      }
    }
  }

  void _handleLoss() {
    HapticFeedback.heavyImpact();
    _gameOver = true;
    _message = 'GAME OVER 💀';
    _subMessage = 'NUMBER WAS $_targetNumber';
  }

  void _showRules(GuessMode mode) {
    String title = '';
    String rules = '';
    
    switch (mode) {
      case GuessMode.easy:
        title = 'EASY MODE';
        rules = '• Range: 1 - 50\n• Attempts: 10\n• Relaxed difficulty for beginners.';
        break;
      case GuessMode.medium:
        title = 'MEDIUM MODE';
        rules = '• Range: 1 - 100\n• Attempts: 7\n• The standard challenge.';
        break;
      case GuessMode.hard:
        title = 'HARD MODE';
        rules = '• Range: 1 - 250\n• Attempts: 6\n• For master guessers only.';
        break;
      case GuessMode.battle:
        title = 'BATTLE MODE';
        rules = '• Range: 1 - 100\n• 2 Players take turns.\n• Whoever finds the number first wins the round!';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.greenAccent, width: 1)),
        title: Text(title, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        content: Text(rules, style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT', style: TextStyle(color: Colors.greenAccent))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text(
          selectedMode == null ? 'GUESS MASTER' : _getModeTitle(),
          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.greenAccent),
          onPressed: () {
            if (selectedMode != null) {
              setState(() => selectedMode = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (selectedMode != null)
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.greenAccent),
              onPressed: () => _showRules(selectedMode!),
            ),
        ],
      ),
      body: selectedMode == null ? _buildModeSelection() : _buildGameArea(),
    );
  }

  String _getModeTitle() {
    switch (selectedMode!) {
      case GuessMode.easy: return 'EASY';
      case GuessMode.medium: return 'MEDIUM';
      case GuessMode.hard: return 'HARD';
      case GuessMode.battle: return 'BATTLE';
    }
  }

  Widget _buildModeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _sectionHeader('SOLO CHALLENGE'),
          _modeCard(GuessMode.easy, 'EASY', 'Range 1-50 | 10 Tries', Icons.child_care, Colors.greenAccent),
          _modeCard(GuessMode.medium, 'MEDIUM', 'Range 1-100 | 7 Tries', Icons.person, Colors.yellowAccent),
          _modeCard(GuessMode.hard, 'HARD', 'Range 1-250 | 6 Tries', Icons.psychology, Colors.orangeAccent),
          const SizedBox(height: 30),
          _sectionHeader('MULTIPLAYER'),
          _modeCard(GuessMode.battle, '1V1 BATTLE', 'Turn-based competition', Icons.groups, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 5),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _modeCard(GuessMode mode, String title, String desc, IconData icon, Color color) {
    int? best = _bestScores[mode];
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => _startGame(mode),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              if (best != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('BEST', style: TextStyle(color: Colors.white24, fontSize: 10)),
                    Text('$best TRIES', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          if (selectedMode == GuessMode.battle) _buildBattleHeader(),
          const SizedBox(height: 30),
          _buildStatusDisplay(),
          if (selectedMode == GuessMode.battle && !_gameOver) 
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildTurnIndicator(),
            ),
          const SizedBox(height: 30),
          if (!_gameOver) _buildInputArea(),
          if (_gameOver) _buildGameOverArea(),
          const SizedBox(height: 30),
          Expanded(child: _buildGuessHistory()),
        ],
      ),
    );
  }

  Widget _buildBattleHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _playerScore('P1', _p1Score, Colors.blueAccent, _currentPlayer == 1),
          const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
          _playerScore('P2', _p2Score, Colors.pinkAccent, _currentPlayer == 2),
        ],
      ),
    );
  }

  Widget _playerScore(String label, int score, Color color, bool active) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: active ? color : Colors.white24, fontWeight: FontWeight.bold)),
        Text('$score', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        if (active && !_gameOver) 
          Container(
            margin: const EdgeInsets.only(top: 5), 
            width: 20, 
            height: 4, 
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: color, blurRadius: 5)]),
          ),
      ],
    );
  }

  Widget _buildTurnIndicator() {
    Color activeColor = _currentPlayer == 1 ? Colors.blueAccent : Colors.pinkAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withOpacity(0.3)),
      ),
      child: Text(
        "PLAYER $_currentPlayer'S TURN",
        style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: _gameOver ? Colors.greenAccent : Colors.white.withOpacity(_pulseAnimation.value),
                shadows: _gameOver ? [const Shadow(color: Colors.greenAccent, blurRadius: 20)] : [],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          _subMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 2),
        ),
        if (selectedMode != GuessMode.battle && !_gameOver)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              'ATTEMPTS REMAINING: ${_maxAttempts - _attempts}',
              style: TextStyle(color: (_maxAttempts - _attempts) <= 2 ? Colors.redAccent : Colors.white24, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildInputArea() {
    Color activeColor = selectedMode == GuessMode.battle 
        ? (_currentPlayer == 1 ? Colors.blueAccent : Colors.pinkAccent) 
        : Colors.greenAccent;

    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(color: activeColor, fontSize: 40, fontWeight: FontWeight.bold),
          cursorColor: activeColor,
          decoration: InputDecoration(
            hintText: '?',
            hintStyle: TextStyle(color: activeColor.withOpacity(0.2)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: activeColor)),
          ),
          onSubmitted: (_) => _handleGuess(),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _handleGuess,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor.withOpacity(0.1),
            foregroundColor: activeColor,
            side: BorderSide(color: activeColor),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('GUESS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _buildGameOverArea() {
    return ElevatedButton.icon(
      onPressed: () => _startGame(selectedMode!),
      icon: const Icon(Icons.refresh),
      label: const Text('PLAY AGAIN'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildGuessHistory() {
    if (_guessHistory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTORY', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _guessHistory.length,
            itemBuilder: (context, index) {
              final item = _guessHistory[index];
              int guess = item['guess'];
              int player = item['player'];
              bool isCorrect = guess == _targetNumber;
              Color pColor = player == 1 ? Colors.blueAccent : Colors.pinkAccent;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.greenAccent.withOpacity(0.1) : pColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pColor.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('P$player', style: TextStyle(color: pColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('$guess', style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold)),
                    Icon(
                      isCorrect ? Icons.check : (guess < _targetNumber ? Icons.arrow_upward : Icons.arrow_downward),
                      size: 14,
                      color: isCorrect ? Colors.greenAccent : Colors.white38,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
