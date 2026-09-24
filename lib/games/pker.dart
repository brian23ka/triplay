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
  final String suit; // '♥', '♦', '♣', '♠', 'RED', 'BLACK'
  final String rank; // '2'-'10', 'J', 'Q', 'K', 'A', 'JOK'
  bool isSelected = false;

  CardModel({required this.suit, required this.rank});

  String get label => rank == 'JOK' ? 'JK' : rank;
  
  Color get color {
    if (rank == 'JOK') return suit == 'RED' ? Colors.redAccent : Colors.grey.shade400;
    return (suit == '♥' || suit == '♦') ? Colors.pinkAccent : Colors.cyanAccent;
  }

  bool isJump() => rank == 'J';
  bool isQuestion() => rank == 'Q' || rank == '8';
  bool isKickback() => rank == 'K';
  bool isPenalty() => rank == '2' || rank == '3' || rank == 'JOK';
  bool isAnswer() => rank == '4' || rank == '5' || rank == '6' || rank == '7' || rank == '9' || rank == '10' || rank == 'A';

  @override
  String toString() => rank == 'JOK' ? '$suit JOKER' : '$rank$suit';
}

class _PkerGameState extends State<PkerGame> {
  List<CardModel> drawPile = [];
  List<CardModel> playerHand = [];
  List<CardModel> aiHand = [];
  List<CardModel> discardPile = [];
  
  bool isPlayerTurn = true;
  bool isAiThinking = false;
  bool isAiMode = true;
  bool isHandoff = false;
  String? winner;
  
  String? currentDemandSuit;
  String? jokerColorDemand; // 'RED' or 'BLACK'
  int pendingPenalty = 0;
  bool questionActive = false;
  bool nikoKadiPlayer = false;
  bool nikoKadiAi = false;
  int direction = 1; // 1 or -1 (though 2-player reverse is just same player again)
  
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
      drawPile = _generateDeck();
      drawPile.shuffle();
      playerHand = [];
      aiHand = [];
      discardPile = [];
      winner = null;
      isPlayerTurn = true;
      isAiThinking = false;
      isHandoff = false;
      pendingPenalty = 0;
      questionActive = false;
      nikoKadiPlayer = false;
      nikoKadiAi = false;
      direction = 1;
      currentDemandSuit = null;
      jokerColorDemand = null;
      gameStatus = "KADI: INITIALIZING";

      // Deal 4 cards each
      for (int i = 0; i < 4; i++) {
        playerHand.add(drawPile.removeLast());
        aiHand.add(drawPile.removeLast());
      }

      // Valid start card logic
      CardModel startCard;
      do {
        startCard = drawPile.removeLast();
        if (_isSpecial(startCard)) {
          drawPile.insert(0, startCard);
          drawPile.shuffle();
        } else {
          break;
        }
      } while (true);
      
      discardPile.add(startCard);
      gameStatus = "YOUR TURN";
    });
  }

  bool _isSpecial(CardModel c) {
    return c.isPenalty() || c.isQuestion() || c.isKickback() || c.isJump() || c.rank == 'A';
  }

  List<CardModel> _generateDeck() {
    List<CardModel> d = [];
    for (var s in suits) {
      for (var r in ranks) {
        d.add(CardModel(suit: s, rank: r));
      }
    }
    // 2 Jokers: 1 Red, 1 Black
    d.add(CardModel(suit: 'RED', rank: 'JOK'));
    d.add(CardModel(suit: 'BLACK', rank: 'JOK'));
    return d;
  }

  CardModel get topCard => discardPile.last;

  List<CardModel> get currentHand => isPlayerTurn ? playerHand : aiHand;

  void _drawCard() {
    if (winner != null || isAiThinking) return;

    setState(() {
      if (pendingPenalty > 0) {
        _performPenaltyDraw(isPlayerTurn);
      } else {
        _performNormalDraw(isPlayerTurn);
        if (questionActive) {
          questionActive = false; // Drew to answer question
        }
      }
      _endTurn();
    });
  }

  void _performNormalDraw(bool isPlayer) {
    if (drawPile.isEmpty) _reshuffleDiscard();
    if (drawPile.isNotEmpty) {
      var card = drawPile.removeLast();
      if (isPlayer) playerHand.add(card); else aiHand.add(card);
    }
  }

  void _performPenaltyDraw(bool isPlayer) {
    gameStatus = isPlayer ? "TAKING +$pendingPenalty CARDS" : "AI TAKES +$pendingPenalty CARDS";
    for (int i = 0; i < pendingPenalty; i++) {
      _performNormalDraw(isPlayer);
    }
    pendingPenalty = 0;
  }

  void _reshuffleDiscard() {
    if (discardPile.length <= 1) return;
    CardModel top = discardPile.removeLast();
    drawPile = List.from(discardPile);
    drawPile.shuffle();
    discardPile = [top];
  }

  bool _isValidPlay(CardModel card) {
    if (pendingPenalty > 0) {
      // Must follow penalty with same rank or Ace to stop
      if (card.rank == topCard.rank) return true;
      if (card.rank == 'A') return true;
      return false;
    }

    if (jokerColorDemand != null) {
      if (jokerColorDemand == 'RED') return card.suit == '♥' || card.suit == '♦';
      if (jokerColorDemand == 'BLACK') return card.suit == '♣' || card.suit == '♠';
    }

    if (questionActive) {
      // Must answer with matching suit or rank of the question card
      return card.suit == topCard.suit || card.rank == topCard.rank;
    }

    if (currentDemandSuit != null) return card.suit == currentDemandSuit;

    return card.suit == topCard.suit || card.rank == topCard.rank || card.rank == 'JOK';
  }

  void _toggleSelection(int index) {
    if (winner != null || isAiThinking || isHandoff) return;
    setState(() {
      currentHand[index].isSelected = !currentHand[index].isSelected;
    });
  }

  void _playSelected() {
    if (isAiThinking || winner != null || isHandoff) return;
    List<CardModel> selected = currentHand.where((c) => c.isSelected).toList();
    if (selected.isEmpty) return;

    // Check if multiple cards are played (only allowed for Jump, Kickback, or Winning move)
    if (selected.length > 1) {
      bool allSameRank = selected.every((c) => c.rank == selected[0].rank);
      bool isWinningMove = (selected.length == currentHand.length && (isPlayerTurn ? nikoKadiPlayer : nikoKadiAi));
      
      if (!allSameRank && !isWinningMove) {
        setState(() => gameStatus = "INVALID COMBO");
        return;
      }
    }

    // Check validity of the play
    if (!_isValidPlay(selected[0])) {
       setState(() {
         gameStatus = "WRONG PLAY! +1 PENALTY";
         _performNormalDraw(isPlayerTurn);
         for (var c in currentHand) c.isSelected = false;
         _endTurn();
       });
       return;
    }

    _executePlay(List.from(selected), isPlayerTurn);
  }

  void _executePlay(List<CardModel> cards, bool isPlayer) async {
    for (var card in cards) {
      setState(() {
        if (isPlayer) playerHand.remove(card);
        else aiHand.remove(card);
        discardPile.add(card);
        gameStatus = isPlayer ? "DEPLOYED ${card.label}" : "AI DEPLOYED ${card.label}";
      });
      await Future.delayed(const Duration(milliseconds: 600));
    }

    setState(() {
      questionActive = false; // Playing a card answers any active question
      currentDemandSuit = null;
      jokerColorDemand = null;
      bool turnEnded = false;

      // Handle Special Cards logic
      for (var card in cards) {
        if (card.isPenalty()) {
          if (card.rank == '2') pendingPenalty += 2;
          else if (card.rank == '3') pendingPenalty += 3;
          else if (card.rank == 'JOK') {
            pendingPenalty += 5;
            jokerColorDemand = card.suit; // 'RED' or 'BLACK'
          }
        } else if (card.rank == 'A') {
          pendingPenalty = 0; // Ace stops penalty
          if (isPlayer) {
            _showAceDialog();
            turnEnded = true; // Wait for dialog
          } else {
            _aiAceDemand();
          }
        } else if (card.isJump()) {
          // In 2P, Jump skips opponent (so same player again)
          // direction doesn't change, we just skip the turn toggle
        } else if (card.isKickback()) {
          // In 2P, Kickback is basically a Jump (reverses back to you)
        } else if (card.isQuestion()) {
          questionActive = true;
        }
      }

      // Check Winning Condition
      if (isPlayer && playerHand.isEmpty) {
        if (nikoKadiPlayer) {
          winner = "PLAYER";
          StatsManager().recordWin();
          StatsManager().recordGamePlay("KADI");
        } else {
          gameStatus = "FAILED NIKO KADI! +2";
          _performNormalDraw(true);
          _performNormalDraw(true);
        }
      } else if (!isPlayer && aiHand.isEmpty) {
        if (nikoKadiAi) {
          winner = "AI";
          StatsManager().recordGamePlay("KADI");
        } else {
          _performNormalDraw(false);
          _performNormalDraw(false);
        }
      }

      if (winner == null && !turnEnded) {
        // Special logic: if last card was a Jump or Kickback, the player plays again
        CardModel last = cards.last;
        if (last.isJump() || last.isKickback()) {
          gameStatus = isPlayer ? (isAiMode ? "CONTINUE TURN" : "PLAYER 1 CONTINUES") : "PLAYER 2 CONTINUES";
          if (!isPlayer && isAiMode) Future.delayed(const Duration(milliseconds: 1000), _aiTurn);
        } else if (questionActive) {
          // Player must play an answer now if they have one
          gameStatus = isPlayer ? (isAiMode ? "ANSWER THE QUESTION" : "P1 ANSWER REQUIRED") : (isAiMode ? "AI ANSWERING" : "P2 ANSWER REQUIRED");
          if (!isPlayer && isAiMode) Future.delayed(const Duration(milliseconds: 1000), _aiTurn);
        } else {
          if (!isAiMode) {
            setState(() => isHandoff = true);
          } else {
            _endTurn();
          }
        }
      }
    });
  }

  void _endTurn() {
    setState(() {
      isPlayerTurn = !isPlayerTurn;
      isHandoff = false;
      if (!isPlayerTurn && winner == null && isAiMode) {
        _startAiSequence();
      } else if (isPlayerTurn) {
        gameStatus = isAiMode ? "YOUR TURN" : "PLAYER 1 TURN";
      } else {
        gameStatus = "PLAYER 2 TURN";
      }
    });
  }

  void _startAiSequence() async {
    setState(() => isAiThinking = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) _aiTurn();
  }

  void _aiTurn() {
    if (winner != null || isPlayerTurn) return;

    List<CardModel> playable = aiHand.where((c) => _isValidPlay(c)).toList();
    
    if (playable.isEmpty) {
      setState(() {
        if (pendingPenalty > 0) {
          _performPenaltyDraw(false);
        } else {
          _performNormalDraw(false);
          gameStatus = "AI DRAWS";
          if (questionActive) questionActive = false;
        }
        isAiThinking = false;
        _endTurn();
      });
      return;
    }

    // AI Strategy
    // 1. If winning move possible (Must have said Niko Kadi)
    if (nikoKadiAi && playable.every((c) => c.isAnswer() || c.isQuestion())) {
       // Play all
       setState(() => isAiThinking = false);
       _executePlay(List.from(playable), false);
       return;
    }

    // 2. Play penalty cards if possible
    List<CardModel> penalties = playable.where((c) => c.isPenalty()).toList();
    if (penalties.isNotEmpty) {
      setState(() => isAiThinking = false);
      _executePlay([penalties.first], false);
      return;
    }

    // 3. Play normal cards
    playable.shuffle();
    var choice = playable.first;
    
    // AI says Niko Kadi if 1 card remains after this
    if (aiHand.length == 2) {
      setState(() => nikoKadiAi = true);
    }

    setState(() => isAiThinking = false);
    _executePlay([choice], false);
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
        title: const Text("COMMANDER ACE", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("DEMAND PROTOCOL SUIT:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: suits.map((s) => IconButton(
                icon: Text(s, style: const TextStyle(color: Colors.cyanAccent, fontSize: 32)),
                onPressed: () {
                  setState(() {
                    currentDemandSuit = s;
                    gameStatus = "SUIT LOCKED: $s";
                  });
                  Navigator.pop(context);
                  _endTurn();
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _sayNikoKadi() {
    if (currentHand.length <= 2) { 
      setState(() {
        if (isPlayerTurn) {
          nikoKadiPlayer = !nikoKadiPlayer;
        } else {
          nikoKadiAi = !nikoKadiAi;
        }
        bool active = isPlayerTurn ? nikoKadiPlayer : nikoKadiAi;
        gameStatus = active ? "NIKO KADI ENGAGED!" : "NIKO KADI DISENGAGED";
      });
      HapticFeedback.heavyImpact();
    } else {
      setState(() {
        if (isPlayerTurn) nikoKadiPlayer = false; else nikoKadiAi = false;
        gameStatus = "TOO MANY CARDS";
      });
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("KADI PROTOCOLS", style: TextStyle(color: Colors.cyanAccent)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Objective: Be the first to empty your hand.", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              Text("SPECIAL CARDS:", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 10)),
              Text("• J (Jump): Skip opponent turn", style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text("• K (Kickback): Reverse direction (Play again)", style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text("• Q & 8 (Question): Must play another card immediately", style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text("• 2, 3, JK (Penalty): Next player draws 2, 3, or 5 cards", style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text("• A (Ace): Stops penalties and changes suit", style: TextStyle(color: Colors.white60, fontSize: 12)),
              SizedBox(height: 10),
              Text("NIKO KADI: You must declare this in the round before you win!", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('STREET KADI 🃏', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.cyanAccent), onPressed: _showAbout),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.cyanAccent), onPressed: _startNewGame),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildModeSelector(),
              _buildAiSection(),
              const Divider(color: Colors.white10, height: 1),
              Expanded(child: _buildPlayArea()),
              const Divider(color: Colors.white10, height: 1),
              _buildPlayerSection(),
            ],
          ),
          if (isHandoff) _buildHandoffScreen(),
          if (winner != null) _buildWinnerOverlay(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _modeToggleItem("STREET BOSS", isAiMode, () => setState(() { isAiMode = true; _startNewGame(); })),
          _modeToggleItem("2 PLAYER", !isAiMode, () => setState(() { isAiMode = false; _startNewGame(); })),
        ],
      ),
    );
  }

  Widget _modeToggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                fontSize: 10,
                letterSpacing: 1.2
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandoffScreen() {
    String next = isPlayerTurn ? "PLAYER 2" : "PLAYER 1";
    Color color = isPlayerTurn ? Colors.pinkAccent : Colors.cyanAccent;
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.style, color: color, size: 64),
        const SizedBox(height: 20),
        Text("PASS DEVICE TO $next", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _endTurn,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            side: BorderSide(color: color, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("START TURN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))
        ),
      ])),
    );
  }

  Widget _buildAiSection() {
    String label = isAiMode ? "STREET BOSS" : "PLAYER 2";
    int count = aiHand.length;
    bool nikoKadi = nikoKadiAi;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isAiMode ? Icons.computer : Icons.person, color: Colors.pinkAccent, size: 14),
              const SizedBox(width: 8),
              Text("$label ($count)", style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              if (nikoKadi) const Padding(padding: EdgeInsets.only(left: 10), child: Text("NIKO KADI!", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) => Container(
              width: 25, height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
              ),
              child: Center(
                child: (isAiMode || isPlayerTurn || isHandoff) 
                  ? const Icon(Icons.style, color: Colors.pinkAccent, size: 12)
                  : Text(aiHand[index].label, style: TextStyle(color: aiHand[index].color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
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
              if (currentDemandSuit != null)
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  child: Text(
                    "SUIT: $currentDemandSuit", 
                    style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 24, shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 15)])
                  ),
                ),
              if (jokerColorDemand != null)
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  child: Text(
                    "$jokerColorDemand PROTOCOL", 
                    style: TextStyle(color: jokerColorDemand == 'RED' ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: 22, shadows: [Shadow(color: jokerColorDemand == 'RED' ? Colors.redAccent : Colors.white, blurRadius: 15)])
                  ),
                ),
              if (questionActive)
                const Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text("QUESTION ACTIVE: ANSWER REQUIRED", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
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
            Text("${drawPile.length}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("DRAW", style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    String label = isPlayerTurn ? (isAiMode ? "OPERATIVE" : "PLAYER 1") : "PLAYER 2";
    bool nikoKadi = isPlayerTurn ? nikoKadiPlayer : nikoKadiAi;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: isPlayerTurn ? Colors.cyanAccent : Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  if (nikoKadi) const Text("NIKO KADI!", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _actionButton("NIKO KADI", _sayNikoKadi, nikoKadi ? Colors.greenAccent : Colors.orangeAccent, textColor: nikoKadi ? Colors.white : Colors.black),
                  const SizedBox(width: 10),
                  _actionButton("DEPLOY", _playSelected, Colors.cyanAccent, textColor: Colors.black),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 120,
            child: (!isHandoff && (isAiMode ? isPlayerTurn : true)) 
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: currentHand.asMap().entries.map((e) => GestureDetector(
                      onTap: () => _toggleSelection(e.key),
                      child: _buildCard(e.value, isSelected: e.value.isSelected),
                    )).toList(),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(currentHand.length, (index) => Container(
                    width: 25, height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: const Center(child: Icon(Icons.style, color: Colors.cyanAccent, size: 12)),
                  )),
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
        backgroundColor: color.withOpacity(0.8),
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
          Positioned(top: 5, left: 5, child: Text(card.label, style: TextStyle(color: card.color, fontWeight: FontWeight.bold, fontSize: 16))),
          Center(child: Text(card.suit, style: TextStyle(color: card.color, fontSize: 28))),
          Positioned(bottom: 5, right: 5, child: Text(card.label, style: TextStyle(color: card.color, fontWeight: FontWeight.bold, fontSize: 16))),
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
