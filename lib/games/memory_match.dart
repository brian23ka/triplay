import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

enum GameMode { solo, vsAI, twoPlayer }

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const int gridCount = 16;
  late List<String> symbols;
  late List<bool> cardFlips;
  late List<bool> cardMatches;
  
  int? firstSelectedIndex;
  bool isProcessing = false;
  int moves = 0;
  int matchesFound = 0;
  bool gameWon = false;
  
  bool gameStarted = false;
  GameMode selectedMode = GameMode.solo;
  int aiLevel = 1; 
  bool isPlayer1Turn = true;
  int p1Score = 0;
  int p2Score = 0; 
  Map<int, String> aiMemory = {}; 

  final List<IconData> iconPool = [
    Icons.ac_unit, Icons.anchor, Icons.favorite, Icons.flash_on,
    Icons.lightbulb, Icons.local_fire_department, Icons.rocket_launch, Icons.visibility,
  ];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      List<int> indices = List.generate(iconPool.length, (i) => i);
      List<int> pairs = [...indices, ...indices];
      pairs.shuffle();
      
      symbols = pairs.map((i) => i.toString()).toList();
      cardFlips = List.filled(gridCount, false);
      cardMatches = List.filled(gridCount, false);
      
      firstSelectedIndex = null;
      isProcessing = false;
      moves = 0;
      matchesFound = 0;
      gameWon = false;
      gameStarted = false;
      isPlayer1Turn = true;
      p1Score = 0;
      p2Score = 0;
      aiMemory.clear();
    });
  }

  void _onCardTap(int index) {
    if (!gameStarted || isProcessing || cardFlips[index] || cardMatches[index]) return;
    if (selectedMode == GameMode.vsAI && !isPlayer1Turn) return;

    _processTurn(index);
  }

  void _processTurn(int index) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      cardFlips[index] = true;
      aiMemory[index] = symbols[index];
      
      if (firstSelectedIndex == null) {
        firstSelectedIndex = index;
        if (selectedMode == GameMode.vsAI && !isPlayer1Turn) {
          Timer(Duration(milliseconds: _getAIDelay()), _aiSecondMove);
        }
      } else {
        moves++;
        isProcessing = true;
        
        if (symbols[firstSelectedIndex!] == symbols[index]) {
          cardMatches[firstSelectedIndex!] = true;
          cardMatches[index] = true;
          matchesFound++;
          
          if (isPlayer1Turn) p1Score++; else p2Score++;

          aiMemory.remove(firstSelectedIndex);
          aiMemory.remove(index);

          firstSelectedIndex = null;
          isProcessing = false;
          HapticFeedback.mediumImpact();
          
          if (matchesFound == iconPool.length) {
            _handleWin();
          } else if (selectedMode == GameMode.vsAI && !isPlayer1Turn) {
             Timer(Duration(milliseconds: _getAIDelay()), _aiFirstMove);
          }
        } else {
          Timer(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                cardFlips[firstSelectedIndex!] = false;
                cardFlips[index] = false;
                firstSelectedIndex = null;
                isProcessing = false;
                
                if (selectedMode != GameMode.solo) {
                  isPlayer1Turn = !isPlayer1Turn;
                  if (!isPlayer1Turn && selectedMode == GameMode.vsAI) {
                    _aiFirstMove();
                  }
                }
              });
            }
          });
        }
      }
    });
  }

  int _getAIDelay() {
    // Levels 1-5 affect delay
    return (2000 - (aiLevel - 1) * 400).clamp(400, 2000);
  }

  void _aiFirstMove() {
    if (gameWon || !mounted) return;

    Map<int, String> activeMemory = _getFilteredMemory();
    int? firstChoice;

    for (var entry1 in activeMemory.entries) {
      for (var entry2 in activeMemory.entries) {
        if (entry1.key != entry2.key && entry1.value == entry2.value) {
          firstChoice = entry1.key;
          break;
        }
      }
      if (firstChoice != null) break;
    }

    if (firstChoice == null) {
      List<int> available = [];
      for (int i = 0; i < gridCount; i++) {
        if (!cardMatches[i] && !cardFlips[i]) available.add(i);
      }
      if (available.isEmpty) return;
      firstChoice = available[Random().nextInt(available.length)];
    }

    _processTurn(firstChoice);
  }

  void _aiSecondMove() {
    if (gameWon || !mounted || firstSelectedIndex == null) return;

    Map<int, String> activeMemory = _getFilteredMemory();
    String targetSymbol = symbols[firstSelectedIndex!];
    int? secondChoice;

    for (var entry in activeMemory.entries) {
      if (entry.key != firstSelectedIndex && entry.value == targetSymbol) {
        secondChoice = entry.key;
        break;
      }
    }

    if (secondChoice == null) {
      List<int> available = [];
      for (int i = 0; i < gridCount; i++) {
        if (!cardMatches[i] && !cardFlips[i] && i != firstSelectedIndex) available.add(i);
      }
      if (available.isEmpty) return;
      secondChoice = available[Random().nextInt(available.length)];
    }

    _processTurn(secondChoice);
  }

  Map<int, String> _getFilteredMemory() {
    Map<int, String> filtered = {};
    // Level 1: 80% forget, Level 5: 0% forget
    double forgetChance = (0.8 - (aiLevel - 1) * 0.2).clamp(0.0, 0.8);
    aiMemory.forEach((idx, symbol) {
      if (Random().nextDouble() > forgetChance) filtered[idx] = symbol;
    });
    return filtered;
  }

  void _handleWin() {
    setState(() => gameWon = true);
    StatsManager().recordGamePlay("NEON MATCH");
    if (selectedMode == GameMode.solo || (selectedMode == GameMode.vsAI && p1Score > p2Score) || (selectedMode == GameMode.twoPlayer && p1Score != p2Score)) {
       StatsManager().recordWin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('NEON MATCH', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !gameStarted ? _buildStartScreen() : Column(
        children: [
          const SizedBox(height: 10),
          _buildScoreBoard(),
          const SizedBox(height: 20),
          Expanded(child: _buildGrid()),
          _buildTurnIndicator(),
          _buildControls(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension, size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 30),
            const Text("SELECT PROTOCOL", style: TextStyle(color: Colors.white38, letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _modeButton("SOLO MISSION", GameMode.solo, Icons.person),
            _modeButton("AI CHALLENGE", GameMode.vsAI, Icons.computer),
            _modeButton("DUAL LINK", GameMode.twoPlayer, Icons.people),
            if (selectedMode == GameMode.vsAI) ...[
              const SizedBox(height: 30),
              const Text("AI INTENSITY", style: TextStyle(color: Colors.white38, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => _levelChip(index + 1)),
              ),
            ],
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => setState(() => gameStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              ),
              child: const Text("INITIALIZE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, GameMode mode, IconData icon) {
    bool isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        width: 250, margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white24),
            const SizedBox(width: 20),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _levelChip(int level) {
    bool isSelected = aiLevel == level;
    return GestureDetector(
      onTap: () => setState(() => aiLevel = level),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(level.toString(), style: TextStyle(color: isSelected ? Colors.pinkAccent : Colors.white24, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildScoreBoard() {
    if (selectedMode == GameMode.solo) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("MOVES", moves.toString(), Colors.cyanAccent),
          _statItem("MATCHES", "$matchesFound / 8", Colors.pinkAccent),
        ],
      );
    }
    String p2Label = selectedMode == GameMode.vsAI ? "AI (L$aiLevel)" : "P2";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem("PLAYER 1", p1Score.toString(), Colors.cyanAccent, active: isPlayer1Turn),
        _statItem(p2Label, p2Score.toString(), Colors.pinkAccent, active: !isPlayer1Turn),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color, {bool active = true}) {
    return Opacity(
      opacity: active ? 1.0 : 0.3,
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold, shadows: active ? [Shadow(color: color, blurRadius: 10)] : [])),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    if (selectedMode == GameMode.solo || gameWon) return const SizedBox(height: 20);
    String turnText = isPlayer1Turn ? "PLAYER 1 TURN" : (selectedMode == GameMode.vsAI ? "AI CALCULATING..." : "PLAYER 2 TURN");
    Color turnColor = isPlayer1Turn ? Colors.cyanAccent : Colors.pinkAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(turnText, style: TextStyle(color: turnColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: gridCount,
        itemBuilder: (context, index) {
          bool isFlipped = cardFlips[index] || cardMatches[index];
          return GestureDetector(
            onTap: () => _onCardTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isFlipped ? const Color(0xFF1A1A2E) : Colors.cyanAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardMatches[index] ? Colors.greenAccent : (isFlipped ? (isPlayer1Turn ? Colors.cyanAccent : Colors.pinkAccent) : Colors.white10), width: 2),
                boxShadow: isFlipped ? [BoxShadow(color: cardMatches[index] ? Colors.greenAccent.withOpacity(0.3) : (isPlayer1Turn ? Colors.cyanAccent : Colors.pinkAccent).withOpacity(0.3), blurRadius: 10)] : [],
              ),
              child: isFlipped ? Icon(iconPool[int.parse(symbols[index])], color: cardMatches[index] ? Colors.greenAccent : (isPlayer1Turn ? Colors.cyanAccent : Colors.pinkAccent), size: 30)
                  : const Center(child: Text("?", style: TextStyle(color: Colors.white10, fontSize: 24, fontWeight: FontWeight.bold))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    if (gameWon) {
      String winText = "MEMORY SYNC COMPLETE";
      if (selectedMode != GameMode.solo) {
        if (p1Score > p2Score) winText = "PLAYER 1 DOMINATES";
        else if (p2Score > p1Score) winText = selectedMode == GameMode.vsAI ? "AI SUPREMACY" : "PLAYER 2 DOMINATES";
        else winText = "NEURAL TIE";
      }
      return Column(
        children: [
          Text(winText, style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 10)])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.cyanAccent, side: const BorderSide(color: Colors.cyanAccent), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            icon: const Icon(Icons.refresh), label: const Text("REBOOT SYSTEM"),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
