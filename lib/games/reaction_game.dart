import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

enum GameMode { classic, f1, aim, rapid, sequence, battle }

class ReactionGame extends StatefulWidget {
  const ReactionGame({super.key});

  @override
  State<ReactionGame> createState() => _ReactionGameState();
}

class _ReactionGameState extends State<ReactionGame> with SingleTickerProviderStateMixin {
  GameMode? selectedMode;
  String status = 'READY?';
  String subStatus = 'TAP TO INITIATE';
  Color neonColor = Colors.cyanAccent;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;
  bool isWaiting = false;
  
  Map<GameMode, int> bestTimes = {};

  int lightsOn = 0;
  Timer? f1Timer;
  Offset? targetPosition;
  int targetsHit = 0;
  final int totalTargets = 5;
  int tapCount = 0;
  int timeLeft = 5;
  Timer? rapidTimer;
  int sequenceIndex = 0;
  List<int> shuffledIndices = [];
  String? battleWinner;
  int p1Score = 0;
  int p2Score = 0;

  // Animation for glow
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(_pulseController);
  }

  String _getRank(int ms) {
    if (ms < 180) return 'GODLY ⚡';
    if (ms < 230) return 'PRO 🔥';
    if (ms < 280) return 'FAST 🚀';
    if (ms < 350) return 'HUMAN 👤';
    if (ms < 500) return 'SLOW 🐢';
    return 'SNAIL 🐌';
  }

  void _showRules(GameMode mode) {
    String title = '';
    String rules = '';
    
    switch (mode) {
      case GameMode.classic:
        title = 'NEON CLASSIC';
        rules = '1. Tap to start.\n2. Wait for the circle to turn GREEN.\n3. Tap as fast as you can!\n\nDon\'t tap when it\'s pink!';
        break;
      case GameMode.f1:
        title = 'F1 START';
        rules = '1. Watch the 5 red lights turn on one by one.\n2. Wait for them all to go OUT.\n3. Tap immediately when they disappear!\n\nFalse starts will reset the round.';
        break;
      case GameMode.aim:
        title = 'AIM TRAINER';
        rules = '1. 5 targets will appear randomly.\n2. Tap them as fast as possible.\n3. Your score is the average time per target.';
        break;
      case GameMode.rapid:
        title = 'RAPID TAPS';
        rules = '1. You have 5 seconds.\n2. Tap the screen as many times as you can.\n3. Faster fingers = Higher score!';
        break;
      case GameMode.sequence:
        title = 'SEQUENCE TAP';
        rules = '1. A grid of 1-9 appears randomly.\n2. Tap the numbers in order: 1, then 2, then 3...\n3. Mis-tapping resets your rhythm!';
        break;
      case GameMode.battle:
        title = '1V1 BATTLE';
        rules = '1. Place the phone between two players.\n2. Wait for the center to say "FIRE!".\n3. First one to tap their side wins.\n\nTapping early gives the point to your opponent!';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 1)),
        title: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        content: Text(rules, style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
    stopwatch.reset();
    targetsHit = 0;
    tapCount = 0;
    timeLeft = 5;
    sequenceIndex = 0;
    battleWinner = null;

    if (selectedMode == GameMode.classic) {
      _startClassicGame();
    } else if (selectedMode == GameMode.f1) {
      _startF1Game();
    } else if (selectedMode == GameMode.aim) {
      _startAimGame();
    } else if (selectedMode == GameMode.rapid) {
      _startRapidGame();
    } else if (selectedMode == GameMode.sequence) {
      _startSequenceGame();
    } else if (selectedMode == GameMode.battle) {
      _startBattleGame();
    }
  }

  void _startClassicGame() {
    setState(() {
      status = 'WAIT FOR IT...';
      subStatus = 'STAY STEADY';
      neonColor = Colors.pinkAccent;
      isWaiting = true;
    });

    int delay = 2000 + Random().nextInt(3000);
    timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        status = 'TAP NOW!';
        subStatus = 'GO GO GO!';
        neonColor = Colors.greenAccent;
        stopwatch.start();
      });
      HapticFeedback.vibrate();
    });
  }

  void _startF1Game() {
    setState(() {
      lightsOn = 0;
      status = 'GRID ALIGNING';
      subStatus = 'WATCH THE LIGHTS';
      isWaiting = true;
    });
    _scheduleF1Light(1);
  }

  void _scheduleF1Light(int lightIndex) {
    f1Timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (lightIndex <= 5) {
        setState(() => lightsOn = lightIndex);
        HapticFeedback.lightImpact();
        _scheduleF1Light(lightIndex + 1);
      } else {
        int delay = 500 + Random().nextInt(2000);
        f1Timer = Timer(Duration(milliseconds: delay), () {
          if (!mounted) return;
          setState(() {
            lightsOn = 0;
            status = 'LIGHTS OUT!';
            subStatus = 'AWAY WE GO!';
            stopwatch.start();
          });
          HapticFeedback.vibrate();
        });
      }
    });
  }

  void _startAimGame() {
    setState(() {
      status = 'READY...';
      subStatus = 'HIT 5 TARGETS';
      isWaiting = true;
    });
    
    timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        status = 'GO!';
        isWaiting = false;
        _spawnTarget();
        stopwatch.start();
      });
    });
  }

  void _spawnTarget() {
    final random = Random();
    setState(() {
      targetPosition = Offset(
        0.1 + random.nextDouble() * 0.8,
        0.2 + random.nextDouble() * 0.5,
      );
    });
  }

  void _startRapidGame() {
    setState(() {
      status = 'READY...';
      subStatus = 'TAP AS FAST AS POSSIBLE';
      isWaiting = true;
    });

    timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        status = 'TAP!';
        subStatus = 'TIME: $timeLeft';
        isWaiting = false;
        stopwatch.start();
      });

      rapidTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          timeLeft--;
          subStatus = 'TIME: $timeLeft';
          if (timeLeft <= 0) {
            t.cancel();
            _finishGame();
          }
        });
      });
    });
  }

  void _startSequenceGame() {
    shuffledIndices = List.generate(9, (index) => index + 1)..shuffle();
    setState(() {
      status = 'READY...';
      subStatus = 'TAP 1 TO 9 IN ORDER';
      isWaiting = true;
    });

    timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        status = 'GO!';
        isWaiting = false;
        stopwatch.start();
      });
    });
  }

  void _startBattleGame() {
    setState(() {
      status = 'WAIT...';
      subStatus = 'P1 vs P2';
      neonColor = Colors.pinkAccent;
      isWaiting = true;
    });

    int delay = 2000 + Random().nextInt(4000);
    timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        status = 'FIRE!';
        subStatus = 'WHO IS FASTER?';
        neonColor = Colors.greenAccent;
      });
      HapticFeedback.vibrate();
    });
  }

  void _handleTap() {
    if (selectedMode == null || selectedMode == GameMode.battle) return;

    if (status == 'READY?' || status.contains('ms') || status == 'TOO EARLY!' || status.contains('TAPS') || status == 'MISSED!') {
      _startGame();
      return;
    }

    if (selectedMode == GameMode.classic) {
      if (isWaiting && status == 'WAIT FOR IT...') {
        _tooEarly();
      } else if (status == 'TAP NOW!') {
        _finishGame();
      }
    } else if (selectedMode == GameMode.f1) {
      if (isWaiting && lightsOn > 0) {
        _tooEarly();
      } else if (status == 'LIGHTS OUT!') {
        _finishGame();
      }
    } else if (selectedMode == GameMode.rapid) {
      if (status == 'TAP!') {
        setState(() {
          tapCount++;
          HapticFeedback.lightImpact();
        });
      }
    }
  }

  void _handleBattleTap(int player) {
    if (status == 'READY?' || status == 'FINISHED') {
      _startGame();
      return;
    }
    
    if (battleWinner != null) return;

    if (status == 'WAIT...') {
      HapticFeedback.heavyImpact();
      setState(() {
        battleWinner = player == 1 ? 'P2 WINS' : 'P1 WINS';
        subStatus = 'JUMP START BY P$player';
        if (player == 1) p2Score++; else p1Score++;
        status = 'FINISHED';
        timer?.cancel();
      });
    } else if (status == 'FIRE!') {
      HapticFeedback.vibrate();
      setState(() {
        battleWinner = 'P$player WINS!';
        subStatus = 'LIGHTNING REFLEXES';
        if (player == 1) p1Score++; else p2Score++;
        status = 'FINISHED';
        StatsManager().recordWin();
      });
    }
  }

  void _handleAimHit() {
    HapticFeedback.selectionClick();
    targetsHit++;
    if (targetsHit >= totalTargets) {
      _finishGame();
    } else {
      _spawnTarget();
    }
  }

  void _handleSequenceTap(int value) {
    if (status != 'GO!') return;
    
    if (value == sequenceIndex + 1) {
      HapticFeedback.selectionClick();
      setState(() {
        sequenceIndex++;
        if (sequenceIndex >= 9) {
          _finishGame();
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        status = 'MISSED!';
        subStatus = 'WRONG ORDER - RETRY';
        neonColor = Colors.orangeAccent;
      });
    }
  }

  void _tooEarly() {
    timer?.cancel();
    f1Timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      status = 'TOO EARLY!';
      subStatus = 'JUMP START! - RETRY';
      neonColor = Colors.orangeAccent;
      isWaiting = false;
      lightsOn = 0;
    });
  }

  void _finishGame() {
    stopwatch.stop();
    int elapsed = stopwatch.elapsedMilliseconds;
    HapticFeedback.mediumImpact();
    
    setState(() {
      if (selectedMode == GameMode.rapid) {
        status = '$tapCount TAPS';
        subStatus = 'IN 5 SECONDS\nTAP TO REPLAY';
        if (bestTimes[GameMode.rapid] == null || tapCount > bestTimes[GameMode.rapid]!) {
          bestTimes[GameMode.rapid] = tapCount;
        }
        if (tapCount > 30) {
          StatsManager().recordWin();
        }
      } else {
        int finalScore = selectedMode == GameMode.aim ? elapsed ~/ totalTargets : 
                         selectedMode == GameMode.sequence ? elapsed ~/ 9 : elapsed;
        status = '$finalScore ms';
        String rank = _getRank(finalScore);
        subStatus = '$rank\nTAP TO REPLAY';
        
        if (bestTimes[selectedMode!] == null || finalScore < bestTimes[selectedMode!]!) {
          bestTimes[selectedMode!] = finalScore;
        }

        if (finalScore < 280) { // FAST or better
          StatsManager().recordWin();
        }
      }
      neonColor = Colors.cyanAccent;
      isWaiting = false;
      targetPosition = null;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    timer?.cancel();
    f1Timer?.cancel();
    rapidTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: selectedMode == GameMode.battle ? null : AppBar(
        title: Text(
          _getModeTitle(),
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () {
            if (selectedMode != null) {
              setState(() {
                selectedMode = null;
                timer?.cancel();
                f1Timer?.cancel();
                rapidTimer?.cancel();
                status = 'READY?';
                subStatus = 'TAP TO INITIATE';
                targetPosition = null;
                sequenceIndex = 0;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            onPressed: () => _showAbout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      _getStatusColor().withOpacity(0.05 * _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          selectedMode == null ? _buildModeSelection() : (selectedMode == GameMode.battle ? _buildBattleMode() : _buildGameArea()),
        ],
      ),
    );
  }

  String _getModeTitle() {
    if (selectedMode == null) return 'REACTION';
    switch (selectedMode!) {
      case GameMode.classic: return 'NEON CLASSIC';
      case GameMode.f1: return 'F1 START';
      case GameMode.aim: return 'AIM TRAINER';
      case GameMode.rapid: return 'RAPID TAPS';
      case GameMode.sequence: return 'SEQUENCE TAP';
      case GameMode.battle: return '1V1 BATTLE';
    }
  }

  Widget _buildModeSelection() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
        child: Column(
          children: [
            _sectionHeader('SOLO TRAINING'),
            _modeCard(GameMode.classic, 'NEON CLASSIC', 'Classic reaction test.', Icons.blur_on, Colors.pinkAccent),
            _modeCard(GameMode.f1, 'F1 START', 'Grid lights challenge.', Icons.speed, Colors.redAccent),
            _modeCard(GameMode.aim, 'AIM TRAINER', 'Precision speed test.', Icons.ads_click, Colors.orangeAccent),
            _modeCard(GameMode.rapid, 'RAPID TAPS', 'Speed tapping challenge.', Icons.touch_app, Colors.greenAccent),
            _modeCard(GameMode.sequence, 'SEQUENCE TAP', 'Pattern memorization.', Icons.format_list_numbered, Colors.blueAccent),
            const SizedBox(height: 30),
            _sectionHeader('PARTY MODES'),
            _modeCard(GameMode.battle, '1V1 NEON BATTLE', 'Face off on one device!', Icons.groups, Colors.cyanAccent),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 5),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _modeCard(GameMode mode, String title, String desc, IconData icon, Color color) {
    int? best = bestTimes[mode];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedMode = mode;
            status = 'READY?';
            subStatus = mode == GameMode.battle ? 'TAP SIDES TO START' : 'TAP TO INITIATE';
            if (mode == GameMode.battle) {
              p1Score = 0;
              p2Score = 0;
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 0),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), 
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              if (best != null) 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('BEST', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('$best${mode == GameMode.rapid ? '' : 'ms'}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBattleMode() {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleBattleTap(2),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      battleWinner?.contains('P2') == true ? Colors.pinkAccent.withOpacity(0.4) : Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('PLAYER 2', style: TextStyle(color: Colors.pinkAccent.withOpacity(0.4), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      const SizedBox(height: 20),
                      Text('$p2Score', style: TextStyle(
                        color: Colors.pinkAccent, 
                        fontSize: 80, 
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.pinkAccent.withOpacity(0.5), blurRadius: 30)],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border.symmetric(horizontal: BorderSide(color: neonColor.withOpacity(0.3), width: 2)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10, right: 10,
                child: IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white24),
                  onPressed: () => _showRules(GameMode.battle),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        battleWinner ?? status,
                        key: ValueKey(battleWinner ?? status),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36, 
                          fontWeight: FontWeight.bold, 
                          color: neonColor,
                          shadows: [Shadow(color: neonColor, blurRadius: 20)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 1),
                    ),
                    if (status == 'FINISHED' || status == 'READY?')
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('TAP SIDES TO START', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10, left: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white24),
                  onPressed: () => setState(() => selectedMode = null),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleBattleTap(1),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    battleWinner?.contains('P1') == true ? Colors.cyanAccent.withOpacity(0.4) : Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('PLAYER 1', style: TextStyle(color: Colors.cyanAccent.withOpacity(0.4), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    const SizedBox(height: 20),
                    Text('$p1Score', style: TextStyle(
                      color: Colors.cyanAccent, 
                      fontSize: 80, 
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 30)],
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selectedMode == GameMode.classic) _buildClassicVisuals(),
                if (selectedMode == GameMode.f1) _buildF1Visuals(),
                if (selectedMode == GameMode.rapid) _buildRapidVisuals(),
                if (selectedMode == GameMode.sequence && status == 'GO!') _buildSequenceVisuals(),
                const SizedBox(height: 60),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                      shadows: [Shadow(color: _getStatusColor(), blurRadius: 25)],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  subStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          if (targetPosition != null)
            Positioned(
              left: MediaQuery.of(context).size.width * targetPosition!.dx - 35,
              top: MediaQuery.of(context).size.height * targetPosition!.dy - 35,
              child: GestureDetector(
                onTap: _handleAimHit,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orangeAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.orangeAccent, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.close, color: Colors.orangeAccent, size: 30)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (selectedMode == GameMode.f1 && status == 'LIGHTS OUT!') return Colors.greenAccent;
    if (selectedMode == GameMode.classic && status == 'TAP NOW!') return Colors.greenAccent;
    if (status == 'TOO EARLY!' || status == 'MISSED!') return Colors.orangeAccent;
    return neonColor;
  }

  Widget _buildClassicVisuals() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _getStatusColor(), width: 5),
        boxShadow: [
          BoxShadow(color: _getStatusColor().withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
        ],
      ),
      child: Center(
        child: Icon(_getIcon(), size: 80, color: _getStatusColor()),
      ),
    );
  }

  Widget _buildF1Visuals() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          bool isOn = index < lightsOn;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 55,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(2, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (dotIndex) {
                return Container(
                  width: 35,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? Colors.redAccent : Colors.grey.shade900,
                    boxShadow: isOn ? [BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 1)] : [],
                    gradient: isOn ? const RadialGradient(colors: [Colors.white, Colors.redAccent], stops: [0.1, 0.9]) : null,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRapidVisuals() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CircularProgressIndicator(
            value: timeLeft / 5,
            strokeWidth: 10,
            color: Colors.greenAccent,
            backgroundColor: Colors.white10,
          ),
        ),
        Text(
          '$tapCount',
          style: TextStyle(
            fontSize: 60, 
            fontWeight: FontWeight.bold, 
            color: Colors.greenAccent,
            shadows: [Shadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 20)],
          ),
        ),
      ],
    );
  }

  Widget _buildSequenceVisuals() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          int val = shuffledIndices[index];
          bool isHit = val <= sequenceIndex;
          Color cellColor = isHit ? Colors.blueAccent : Colors.white;
          
          return GestureDetector(
            onTap: () => _handleSequenceTap(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isHit ? Colors.blueAccent.withOpacity(0.2) : Colors.black26,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isHit ? Colors.blueAccent : Colors.white24, width: 2),
                boxShadow: isHit ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10)] : [],
              ),
              child: Center(
                child: Text(
                  '$val',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: cellColor,
                    shadows: isHit ? [Shadow(color: Colors.blueAccent, blurRadius: 10)] : [],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAbout() {
    if (selectedMode != null) {
      _showRules(selectedMode!);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ABOUT REACTION", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          "Test your reflexes across multiple challenging modes! From classic reaction time to aim training and 1v1 battles. Select a mode to see specific protocols.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (status == 'READY?') return Icons.power_settings_new;
    if (status == 'WAIT FOR IT...') return Icons.hourglass_empty;
    if (status == 'TAP NOW!') return Icons.bolt;
    if (status == 'TOO EARLY!') return Icons.error_outline;
    return Icons.timer;
  }
}
