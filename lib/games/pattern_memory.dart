import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PatternMode { solo, battle }
enum Difficulty { easy, medium, hard }

class PatternMemoryGame extends StatefulWidget {
  const PatternMemoryGame({super.key});

  @override
  State<PatternMemoryGame> createState() => _PatternMemoryGameState();
}

class _PatternMemoryGameState extends State<PatternMemoryGame> with TickerProviderStateMixin {
  PatternMode? selectedMode;
  Difficulty soloDifficulty = Difficulty.medium;

  // Game State
  List<int> sequence = [];
  List<int> userSequence = [];
  bool isPlayingSequence = false;
  bool isGameOver = false;
  int score = 0;
  int bestScore = 0;
  int? activePad;

  // Battle State
  int p1Wins = 0;
  int p2Wins = 0;
  bool isP1Turn = true;
  String? battleWinner;

  final List<Color> padColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
  ];

  void _startGame(PatternMode mode) {
    setState(() {
      selectedMode = mode;
      isGameOver = false;
      battleWinner = null;
      sequence = [];
      userSequence = [];
      score = 0;
      if (mode == PatternMode.solo) {
        _nextRoundSolo();
      } else {
        isP1Turn = true;
        _nextRoundBattle();
      }
    });
  }

  // --- Solo Logic ---
  void _nextRoundSolo() {
    setState(() {
      userSequence = [];
      sequence.add(Random().nextInt(4));
    });
    _playSequence();
  }

  void _playSequence() async {
    setState(() => isPlayingSequence = true);
    await Future.delayed(const Duration(milliseconds: 800));

    int speed = 500;
    if (selectedMode == PatternMode.solo) {
      speed = soloDifficulty == Difficulty.easy ? 800 : (soloDifficulty == Difficulty.medium ? 500 : 300);
    }

    for (int pad in sequence) {
      if (!mounted) return;
      setState(() => activePad = pad);
      HapticFeedback.mediumImpact();
      await Future.delayed(Duration(milliseconds: speed));
      setState(() => activePad = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() => isPlayingSequence = false);
  }

  void _handlePadTap(int player, int index) {
    if (isPlayingSequence || isGameOver || battleWinner != null) return;
    
    // Check if it's the correct player's turn in Battle mode
    if (selectedMode == PatternMode.battle) {
      if ((isP1Turn && player != 1) || (!isP1Turn && player != 2)) return;
    }

    setState(() {
      activePad = index;
      userSequence.add(index);
    });
    
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => activePad = null);
    });

    if (userSequence[userSequence.length - 1] != sequence[userSequence.length - 1]) {
      if (selectedMode == PatternMode.solo) {
        _handleGameOverSolo();
      } else {
        _handleBattleEnd(isP1Turn ? 2 : 1);
      }
    } else if (userSequence.length == sequence.length) {
      if (selectedMode == PatternMode.solo) {
        setState(() => score++);
        Timer(const Duration(milliseconds: 500), _nextRoundSolo);
      } else {
        if (isP1Turn) {
          setState(() {
            isP1Turn = false;
            userSequence = [];
          });
          Future.delayed(const Duration(milliseconds: 800), () => _playSequence());
        } else {
          setState(() {
            isP1Turn = true;
            score++; // Current level/round
          });
          Future.delayed(const Duration(milliseconds: 800), () => _nextRoundBattle());
        }
      }
    }
  }

  void _handleGameOverSolo() {
    HapticFeedback.vibrate();
    setState(() {
      isGameOver = true;
      if (score > bestScore) bestScore = score;
    });
  }

  void _handleBattleEnd(int winner) {
    HapticFeedback.vibrate();
    setState(() {
      battleWinner = "PLAYER $winner WINS!";
      if (winner == 1) p1Wins++; else p2Wins++;
    });
  }

  void _nextRoundBattle() {
    setState(() {
      userSequence = [];
      sequence.add(Random().nextInt(4));
    });
    _playSequence();
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent)),
        title: const Text('NEON SEQUENCE RULES', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Watch the pattern carefully.\n'
          '2. Repeat it exactly.\n'
          '3. 1v1 Battle: Both players must repeat the SAME sequence correctly.\n'
          '4. First to make a mistake loses the round!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT', style: TextStyle(color: Colors.purpleAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: selectedMode == PatternMode.battle ? null : AppBar(
        title: Text(selectedMode == null ? 'NEON SEQUENCE' : 'SOLO MEMORY', 
          style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.purpleAccent),
          onPressed: () {
            if (selectedMode != null) {
              setState(() => selectedMode = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline, color: Colors.purpleAccent), onPressed: _showRules),
        ],
      ),
      body: selectedMode == null ? _buildModeSelection() : (selectedMode == PatternMode.solo ? _buildSoloGame() : _buildBattleGame()),
    );
  }

  Widget _buildModeSelection() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SOLO TRAINING'),
          _modeCard('EASY', 'Slower speed sequence.', Icons.child_care, Colors.greenAccent, () {
            soloDifficulty = Difficulty.easy;
            _startGame(PatternMode.solo);
          }),
          _modeCard('MEDIUM', 'Standard speed challenge.', Icons.person, Colors.purpleAccent, () {
            soloDifficulty = Difficulty.medium;
            _startGame(PatternMode.solo);
          }),
          _modeCard('HARD', 'Lightning fast pattern.', Icons.bolt, Colors.redAccent, () {
            soloDifficulty = Difficulty.hard;
            _startGame(PatternMode.solo);
          }),
          const SizedBox(height: 30),
          _sectionHeader('MULTIPLAYER'),
          _modeCard('1V1 BATTLE', 'Challenge a friend on one device.', Icons.groups, Colors.blueAccent, () {
            _startGame(PatternMode.battle);
          }),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
    );
  }

  Widget _modeCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
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
              const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoloGame() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSoloHeader(),
        const SizedBox(height: 40),
        _buildPadsGrid(0), // 0 for shared/solo
        const SizedBox(height: 50),
        _buildSoloStatus(),
      ],
    );
  }

  Widget _buildSoloHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('SCORE', score, Colors.white),
          _statItem('BEST', bestScore, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildSoloStatus() {
    return Column(
      children: [
        Text(
          isGameOver ? 'GAME OVER' : (isPlayingSequence ? 'WATCH...' : 'YOUR TURN'),
          style: TextStyle(
            color: isGameOver ? Colors.redAccent : (isPlayingSequence ? Colors.white38 : Colors.purpleAccent),
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2,
          ),
        ),
        if (isGameOver)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton.icon(
              onPressed: () => _startGame(PatternMode.solo),
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildBattleGame() {
    return Column(
      children: [
        // P2 Area (Flipped)
        Expanded(
          child: RotatedBox(
            quarterTurns: 2,
            child: _buildBattlePlayerArea(2),
          ),
        ),
        // Central Info / Score Table
        _buildBattleCentralUI(),
        // P1 Area
        Expanded(
          child: _buildBattlePlayerArea(1),
        ),
      ],
    );
  }

  Widget _buildBattlePlayerArea(int player) {
    bool isMyTurn = (player == 1 && isP1Turn) || (player == 2 && !isP1Turn);
    bool showHighlight = isMyTurn && !isPlayingSequence && battleWinner == null;
    
    return Container(
      width: double.infinity,
      color: showHighlight ? (player == 1 ? Colors.blueAccent : Colors.pinkAccent).withOpacity(0.05) : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPadsGrid(player),
          const SizedBox(height: 20),
          Text(
            isMyTurn ? (isPlayingSequence ? "WATCHING..." : "REPLICATE!") : "WAIT...",
            style: TextStyle(
              color: isMyTurn ? (player == 1 ? Colors.blueAccent : Colors.pinkAccent) : Colors.white10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleCentralUI() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withOpacity(0.05), width: 2)),
      ),
      child: Stack(
        children: [
          Positioned(left: 10, top: 0, bottom: 0, child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white24),
            onPressed: () => setState(() => selectedMode = null),
          )),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _battleScoreItem('P1', p1Wins, Colors.blueAccent),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                    ),
                    _battleScoreItem('P2', p2Wins, Colors.pinkAccent),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  battleWinner ?? (isPlayingSequence ? 'PLAYING SEQUENCE...' : 'ROUND ${score + 1}'),
                  style: TextStyle(
                    color: battleWinner != null ? Colors.yellowAccent : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (battleWinner != null)
                  TextButton(
                    onPressed: () => _startGame(PatternMode.battle),
                    child: const Text('NEXT ROUND', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _battleScoreItem(String label, int wins, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
        Text('$wins', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPadsGrid(int player) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          bool isActive = activePad == index;
          Color color = padColors[index];
          
          // Determine if this pad belongs to the active player in battle
          bool isInteractable = true;
          if (selectedMode == PatternMode.battle) {
            if (player == 1 && !isP1Turn) isInteractable = false;
            if (player == 2 && isP1Turn) isInteractable = false;
          }

          return GestureDetector(
            onTapDown: (_) => isInteractable ? _handlePadTap(player, index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isActive ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive ? Colors.white : color.withOpacity(0.3), 
                  width: isActive ? 3 : 2,
                ),
                boxShadow: isActive ? [BoxShadow(color: color, blurRadius: 20)] : [],
              ),
              child: !isActive && !isPlayingSequence && isInteractable ? Center(
                child: Icon(Icons.touch_app, color: color.withOpacity(0.1), size: 20),
              ) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String label, int val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('$val', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
