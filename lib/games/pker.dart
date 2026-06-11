import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class PkerGame extends StatefulWidget {
  const PkerGame({super.key});

  @override
  State<PkerGame> createState() => _PkerGameState();
}

class CardModel {
  final String suit;
  final String rank;
  bool isSelected = false;

  CardModel({required this.suit, required this.rank});

  String get label => rank;
  
  Color get color => (suit == '♥' || suit == '♦') ? Colors.pinkAccent : Colors.cyanAccent;

  @override
  String toString() => '$rank$suit';
}

class _PkerGameState extends State<PkerGame> {
  List<CardModel> deck = [];
  List<CardModel> playerHand = [];
  List<CardModel> aiHand = [];
  List<CardModel> discardPile = [];
  
  bool isPlayerTurn = true;
  bool isAiThinking = false;
  String? winner;
  String? currentDemandSuit;
  String? currentDemandRank;
  int pendingPenalty = 0;
  bool isQaMode = false;
  bool nikoKadiDeclared = false;
  
  String gameStatus = "MATCH SUIT OR RANK";
  
  final List<String> suits = ['♥', '♦', '♣', '♠'];
  final List<String> ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      deck = _generateDeck();
      deck.shuffle();
      playerHand = [];
      aiHand = [];
      discardPile = [];
      winner = null;
      isPlayerTurn = true;
      isAiThinking = false;
      pendingPenalty = 0;
      isQaMode = false;
      nikoKadiDeclared = false;
      currentDemandSuit = null;
      currentDemandRank = null;
      gameStatus = "STREET POKER: READY";

      for (int i = 0; i < 4; i++) {
        playerHand.add(deck.removeLast());
        aiHand.add(deck.removeLast());
      }

      // Start discard pile with a non-special card if possible
      CardModel startCard = deck.removeLast();
      discardPile.add(startCard);
    });
  }

  List<CardModel> _generateDeck() {
    List<CardModel> d = [];
    for (var s in suits) {
      for (var r in ranks) {
        d.add(CardModel(suit: s, rank: r));
      }
    }
    return d;
  }

  CardModel get topCard => discardPile.last;

  void _drawCard() {
    if (winner != null || !isPlayerTurn || isAiThinking) return;

    setState(() {
      if (pendingPenalty > 0) {
        gameStatus = "TAKING +$pendingPenalty CARDS";
        for (int i = 0; i < pendingPenalty; i++) {
          if (deck.isEmpty) _reshuffleDiscard();
          if (deck.isNotEmpty) playerHand.add(deck.removeLast());
        }
        pendingPenalty = 0;
      } else {
        if (deck.isEmpty) _reshuffleDiscard();
        if (deck.isNotEmpty) playerHand.add(deck.removeLast());
        gameStatus = "CARD DRAWN";
      }
      _endTurn();
    });
  }

  void _reshuffleDiscard() {
    if (discardPile.length <= 1) return;
    CardModel top = discardPile.removeLast();
    deck = List.from(discardPile);
    deck.shuffle();
    discardPile = [top];
  }

  bool _isValidPlay(CardModel card) {
    if (pendingPenalty > 0) {
      // Must play punisher or escape card
      if (card.rank == '2' || card.rank == '3') return true;
      if (card.rank == 'J' || card.rank == 'K' || card.rank == 'A') return true;
      return false;
    }

    if (isQaMode) {
      return card.rank == 'A' || card.rank == 'Q'; // Can answer Q with A or another Q
    }

    if (currentDemandSuit != null) return card.suit == currentDemandSuit;
    if (currentDemandRank != null) return card.rank == currentDemandRank;

    return card.suit == topCard.suit || card.rank == topCard.rank;
  }

  void _toggleSelection(int index) {
    if (!isPlayerTurn || winner != null || isAiThinking) return;
    setState(() {
      String? selectedRank;
      for (var c in playerHand) {
        if (c.isSelected) {
          selectedRank = c.rank;
          break;
        }
      }

      if (selectedRank != null && playerHand[index].rank != selectedRank) {
        for (var c in playerHand) c.isSelected = false;
      }
      
      playerHand[index].isSelected = !playerHand[index].isSelected;
    });
  }

  void _playSelected() {
    if (isAiThinking) return;
    List<CardModel> selected = playerHand.where((c) => c.isSelected).toList();
    if (selected.isEmpty) return;

    bool allValid = selected.every((c) => _isValidPlay(c));
    if (!allValid) {
      setState(() => gameStatus = "INVALID PROTOCOL");
      return;
    }

    _executePlay(List.from(selected), true);
  }

  void _executePlay(List<CardModel> cards, bool isPlayer) async {
    if (isPlayer) {
      // Check Niko Kadi penalty if they had 2 cards and played 1 but didn't say it yet
      // Actually, check it when the turn ENDS.
    }

    for (var card in cards) {
      setState(() {
        if (isPlayer) playerHand.remove(card);
        else aiHand.remove(card);
        discardPile.add(card);
        gameStatus = isPlayer ? "YOU PLAYED ${card.rank}${card.suit}" : "AI PLAYED ${card.rank}${card.suit}";
      });
      await Future.delayed(const Duration(milliseconds: 600));
    }

    CardModel lastPlayed = cards.last;
    bool skipNext = false;
    
    setState(() {
      isQaMode = false;
      currentDemandSuit = null;
      currentDemandRank = null;

      if (lastPlayed.rank == '2') pendingPenalty += 2;
      else if (lastPlayed.rank == '3') pendingPenalty += 3;
      else if (lastPlayed.rank == 'Q') isQaMode = true;
      else if (lastPlayed.rank == 'J' || lastPlayed.rank == 'K') {
        pendingPenalty = 0; 
        skipNext = true; // Street Poker: J/K are Jump/Kick (Skip in 2P)
      }
      else if (lastPlayed.rank == 'A') {
        pendingPenalty = 0;
        if (isPlayer) {
          _showAceDialog();
          return; 
        } else {
          _aiAceDemand();
        }
      }

      _checkWinCondition();
      if (winner == null) {
        if (skipNext) {
          gameStatus = isPlayer ? "JUMP! PLAY AGAIN" : "AI JUMPED! STILL AI TURN";
          if (!isPlayer) {
            Future.delayed(const Duration(milliseconds: 1000), _aiTurn);
          }
        } else {
          _endTurn();
        }
      }
    });
  }

  void _endTurn() {
    // Check Niko Kadi penalty for the player who just finished
    if (isPlayerTurn && playerHand.length == 1 && !nikoKadiDeclared) {
      gameStatus = "FORGOT NIKO KADI! +2";
      for (int i = 0; i < 2; i++) {
        if (deck.isEmpty) _reshuffleDiscard();
        if (deck.isNotEmpty) playerHand.add(deck.removeLast());
      }
    }

    setState(() {
      isPlayerTurn = !isPlayerTurn;
      nikoKadiDeclared = false;
      if (!isPlayerTurn && winner == null) {
        _startAiSequence();
      } else if (isPlayerTurn) {
        gameStatus = "YOUR TURN";
      }
    });
  }

  void _startAiSequence() async {
    setState(() => isAiThinking = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) _aiTurn();
  }

  void _checkWinCondition() {
    if (playerHand.isEmpty) {
      winner = "PLAYER";
      StatsManager().recordWin();
      StatsManager().recordGamePlay("PKER");
    } else if (aiHand.isEmpty) {
      winner = "AI";
      StatsManager().recordGamePlay("PKER");
    }
  }

  void _aiTurn() {
    if (winner != null || isPlayerTurn) return;

    List<CardModel> playable = aiHand.where((c) => _isValidPlay(c)).toList();
    
    if (playable.isEmpty) {
      setState(() {
        if (pendingPenalty > 0) {
          gameStatus = "AI TAKES +$pendingPenalty";
          for (int i = 0; i < pendingPenalty; i++) {
            if (deck.isEmpty) _reshuffleDiscard();
            if (deck.isNotEmpty) aiHand.add(deck.removeLast());
          }
          pendingPenalty = 0;
        } else {
          if (deck.isEmpty) _reshuffleDiscard();
          if (deck.isNotEmpty) aiHand.add(deck.removeLast());
          gameStatus = "AI DRAWS";
        }
        isAiThinking = false;
        _endTurn();
      });
      return;
    }

    // AI Strategy: Play highest penalty cards or matching ranks
    playable.sort((a, b) {
      int score(String r) {
        if (r == '2') return 3;
        if (r == '3') return 3;
        if (r == 'A') return 4;
        if (r == 'J' || r == 'K') return 2;
        return 1;
      }
      return score(b.rank).compareTo(score(a.rank));
    });

    String targetRank = playable.first.rank;
    List<CardModel> combo = aiHand.where((c) => c.rank == targetRank && _isValidPlay(c)).toList();
    
    if (aiHand.length - combo.length == 1) {
      // AI "says" Niko Kadi automatically
    }

    setState(() => isAiThinking = false);
    _executePlay(combo, false);
  }

  void _aiAceDemand() {
    Map<String, int> counts = {};
    for (var c in aiHand) counts[c.suit] = (counts[c.suit] ?? 0) + 1;
    String bestSuit = suits.first;
    int max = -1;
    counts.forEach((s, c) { if (c > max) { max = c; bestSuit = s; } });
    currentDemandSuit = bestSuit;
    gameStatus = "AI DEMANDS $bestSuit";
  }

  void _showAceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ACE COMMAND", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("DEMAND SUIT:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: suits.map((s) => IconButton(
                icon: Text(s, style: const TextStyle(color: Colors.cyanAccent, fontSize: 32)),
                onPressed: () {
                  setState(() {
                    currentDemandSuit = s;
                    gameStatus = "DEMANDED $s";
                  });
                  Navigator.pop(context);
                  _endTurn();
                },
              )).toList(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: Colors.white10),
            ),
            const Text("OR DEMAND RANK:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['2','3','4','5','6','7','8','9','10','J','Q','K'].map((r) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.pinkAccent)),
                    child: Text(r, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        currentDemandRank = r;
                        gameStatus = "DEMANDED $r";
                      });
                      Navigator.pop(context);
                      _endTurn();
                    },
                  ),
                )).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _sayNikoKadi() {
    if (playerHand.length == 1) {
      setState(() {
        nikoKadiDeclared = true;
        gameStatus = "NIKO KADI DECLARED!";
      });
      HapticFeedback.heavyImpact();
    } else {
      setState(() => gameStatus = "NOT YET!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('STREET POKER 🃏', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.cyanAccent), onPressed: _startNewGame),
        ],
      ),
      body: Column(
        children: [
          _buildAiSection(),
          const Divider(color: Colors.white10, height: 1),
          Expanded(child: _buildPlayArea()),
          const Divider(color: Colors.white10, height: 1),
          _buildPlayerSection(),
        ],
      ),
    );
  }

  Widget _buildAiSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.computer, color: Colors.pinkAccent, size: 14),
              const SizedBox(width: 8),
              Text("STREET BOSS (${aiHand.length})", style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(aiHand.length, (index) => Container(
              width: 25, height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
              ),
              child: const Center(child: Icon(Icons.style, color: Colors.pinkAccent, size: 12)),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  gameStatus.toUpperCase(), 
                  key: ValueKey(gameStatus),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPlayerTurn ? Colors.cyanAccent : Colors.pinkAccent, 
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: isPlayerTurn ? Colors.cyanAccent : Colors.pinkAccent, blurRadius: 10)]
                  )
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDeckPile(),
                  const SizedBox(width: 40),
                  _buildCard(topCard, isTop: true),
                ],
              ),
              if (pendingPenalty > 0)
                Container(
                  margin: const EdgeInsets.only(top: 25),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent)),
                  child: Text("STRIKE: +$pendingPenalty CARDS", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              if (currentDemandSuit != null || currentDemandRank != null)
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  child: Text(
                    "DEMAND: ${currentDemandSuit ?? currentDemandRank}", 
                    style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 24, shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 15)])
                  ),
                ),
              if (isQaMode)
                const Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text("Q&A MODE: ANSWER WITH ACE/Q", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              if (isAiThinking)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: SizedBox(width: 40, child: LinearProgressIndicator(color: Colors.pinkAccent, backgroundColor: Colors.white10)),
                ),
            ],
          ),
        ),
        if (winner != null) _buildWinnerOverlay(),
      ],
    );
  }

  Widget _buildDeckPile() {
    return GestureDetector(
      onTap: _drawCard,
      child: Container(
        width: 75, height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent, width: 2),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_to_photos, color: Colors.cyanAccent, size: 30),
            const SizedBox(height: 5),
            Text("${deck.length}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("DRAW", style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("OPERATIVE", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  Text("HAND TERMINAL", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _actionButton("NIKO KADI", _sayNikoKadi, nikoKadiDeclared ? Colors.greenAccent : Colors.white10),
                  const SizedBox(width: 10),
                  _actionButton("DEPLOY", _playSelected, Colors.cyanAccent, textColor: Colors.black),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: playerHand.asMap().entries.map((e) => GestureDetector(
                  onTap: () => _toggleSelection(e.key),
                  child: _buildCard(e.value, isSelected: e.value.isSelected),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, Color color, {Color textColor = Colors.white}) {
    return ElevatedButton(
      onPressed: isAiThinking ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(color == Colors.white10 ? 1 : 0.8),
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildCard(CardModel card, {bool isTop = false, bool isSelected = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 65, height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      transform: Matrix4.translationValues(0, isSelected ? -15 : 0, 0),
      decoration: BoxDecoration(
        color: isTop ? Colors.white : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.yellowAccent : (isTop ? Colors.white : Colors.cyanAccent.withOpacity(0.3)),
          width: isSelected ? 3 : 1
        ),
        boxShadow: isSelected ? [const BoxShadow(color: Colors.yellowAccent, blurRadius: 15)] : (isTop ? [const BoxShadow(color: Colors.white24, blurRadius: 10)] : null),
      ),
      child: Stack(
        children: [
          Positioned(top: 5, left: 5, child: Text(card.rank, style: TextStyle(color: card.color, fontWeight: FontWeight.bold, fontSize: 16))),
          Center(child: Text(card.suit, style: TextStyle(color: card.color, fontSize: 28))),
          Positioned(bottom: 5, right: 5, child: Text(card.rank, style: TextStyle(color: card.color, fontWeight: FontWeight.bold, fontSize: 16))),
          if (isSelected) Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.yellowAccent.withOpacity(0.1))),
        ],
      ),
    );
  }

  Widget _buildWinnerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(winner == "PLAYER" ? Icons.emoji_events : Icons.gavel, size: 80, color: winner == "PLAYER" ? Colors.cyanAccent : Colors.pinkAccent),
          const SizedBox(height: 20),
          Text(
            winner == "PLAYER" ? "STREET LEGEND" : "BUSTED BY BOSS",
            style: TextStyle(color: winner == "PLAYER" ? Colors.cyanAccent : Colors.pinkAccent, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startNewGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              side: BorderSide(color: winner == "PLAYER" ? Colors.cyanAccent : Colors.pinkAccent),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("RETRY SEQUENCE", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
