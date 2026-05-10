import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

void main() => runApp(const KachingApp());

// ##########################################
// MODELS
// ##########################################
class Equipment {
  String name, icon, statBonus;
  int level, powerBonus, upgradeCost;
  Equipment({required this.name, required this.icon, required this.statBonus, this.level = 1, this.powerBonus = 50, this.upgradeCost = 200});
}

class SavingsPocket {
  String name;
  double current, target, allocationPercent;
  IconData icon;
  Color color;
  SavingsPocket({required this.name, required this.current, required this.target, required this.allocationPercent, required this.icon, required this.color});
  double get percent => (current / target).clamp(0.0, 1.0);
}

// ##########################################
// CORE: MOCK SERVICE
// ##########################################
class MockService extends ChangeNotifier {
  double spendableBalance = 1240.50;
  double dailySpent = 12.50;
  double dailyBudget = 30.00;
  int points = 1250;
  int totalPointsGained = 5400;
  int savingsStreak = 8;
  int guardianBasePower = 500;
  int guardianLevel = 14;
  bool streakClaimedToday = false;

  List<String> myBadges = ["Early Bird", "Safe Spender", "Streak King"];
  
  List<Map<String, dynamic>> leaderboard = [
    {"name": "Alex (You)", "lvl": 14, "pwr": 850, "avatar": "🐧", "badges": ["Early Bird", "Safe Spender"], "isMe": true},
    {"name": "Sarah", "lvl": 18, "pwr": 2400, "avatar": "🦊", "badges": ["Wealthy", "Pro Swiper", "Elite"], "isMe": false},
    {"name": "Jordan", "lvl": 12, "pwr": 1400, "avatar": "🐻", "badges": ["First Save"], "isMe": false},
  ];

  List<Equipment> equipment = [
    Equipment(name: "Savings Sword", icon: "⚔️", statBonus: "+120 Power", powerBonus: 120),
    Equipment(name: "Budget Shield", icon: "🛡️", statBonus: "+85 Power", powerBonus: 85),
  ];

  // ALLOCATION: 40+20+10+10+10 = 90% (Remainder 10% to Spendable)
  List<SavingsPocket> pockets = [
    SavingsPocket(name: "Rent/Housing", current: 1200, target: 1500, allocationPercent: 40, icon: Icons.home, color: Colors.indigo),
    SavingsPocket(name: "Emergency", current: 2000, target: 10000, allocationPercent: 20, icon: Icons.shield, color: const Color(0xFF556B2F)),
    SavingsPocket(name: "Utilities", current: 150, target: 300, allocationPercent: 10, icon: Icons.bolt, color: Colors.orange),
    SavingsPocket(name: "Bali Trip", current: 800, target: 5000, allocationPercent: 10, icon: Icons.flight, color: Colors.blue),
    SavingsPocket(name: "New Laptop", current: 350, target: 4500, allocationPercent: 10, icon: Icons.laptop, color: Colors.purple),
  ];

  List<Map<String, dynamic>> swipeQueue = [
    {"merchant": "Netflix", "amount": 54.00, "icon": Icons.movie, "cat": "Entertainment"},
    {"merchant": "Electric Bill", "amount": 210.40, "icon": Icons.electric_bolt, "cat": "Bills"},
    {"merchant": "Steam Sale", "amount": 89.90, "icon": Icons.videogame_asset, "cat": "Gaming"},
    {"merchant": "Bubble Tea", "amount": 15.50, "icon": Icons.local_drink, "cat": "Treats"},
  ];

  List<Map<String, dynamic>> transactions = [
    {"name": "Lunch", "base": 12.50, "round": 0.50, "type": "expense"},
  ];

  // CALCULATION: Total Assets = Sum of all Pockets + Spendable (100% of money)
  double get totalNetWorth {
    double totalPockets = pockets.fold(0, (sum, p) => sum + p.current);
    return totalPockets + spendableBalance;
  }

  int get totalPower {
    int equipPower = equipment.fold(0, (sum, e) => sum + (e.powerBonus * e.level));
    return guardianBasePower + equipPower;
  }

  void processSalary(double amount) {
    // 90% goes to specific pockets
    for (var p in pockets) {
      p.current += (amount * (p.allocationPercent / 100));
    }
    // Exactly 10% goes to Spendable Balance
    spendableBalance += (amount * 0.10);
    
    _addPoints(150);
    streakClaimedToday = false;
    transactions.insert(0, {"name": "Salary Deposit", "base": amount, "round": 0.0, "type": "income"});
    notifyListeners();
  }

  void claimStreakBonus() {
    if (!streakClaimedToday && savingsStreak > 0) {
      int bonus = savingsStreak * 2;
      _addPoints(bonus);
      streakClaimedToday = true;
      notifyListeners();
    }
  }

  String processSpend(double amount, String name) {
    String message = "";
    double roundTo = amount.ceilToDouble();
    double roundUp = double.parse((roundTo - amount).toStringAsFixed(2));
    double totalCharge = amount + roundUp;
    
    if (amount > (spendableBalance * 0.20)) {
      message += "⚠️ Large Spend Warning!\n";
    }

    if ((dailySpent + amount) > dailyBudget && savingsStreak > 0) {
      message += "📉 Budget Exceeded! Your $savingsStreak day streak has ended.\n";
      savingsStreak = 0;
    }

    if (totalCharge > spendableBalance) {
      double deficit = totalCharge - spendableBalance;
      spendableBalance = 0;
      pockets[1].current -= deficit; 
      message += "🆘 Overdraft! RM ${deficit.toStringAsFixed(2)} pulled from Emergency Pocket.\n";
    } else {
      spendableBalance -= totalCharge;
      if (roundUp > 0) {
        pockets[1].current += roundUp; 
        message += "🪄 RM ${roundUp.toStringAsFixed(2)} saved to Emergency!";
      }
    }

    dailySpent += amount;
    transactions.insert(0, {"name": name, "base": amount, "round": roundUp, "type": "expense"});
    _addPoints(20);
    
    notifyListeners();
    return message.isEmpty ? "Purchase successful!" : message;
  }

  void _addPoints(int p) {
    points += p;
    totalPointsGained += p;
  }

  bool redeemVoucher(int cost) {
    if (points >= cost) {
      points -= cost;
      notifyListeners();
      return true;
    }
    return false;
  }

  void upgradeEquip(int index) {
    if (points >= equipment[index].upgradeCost) {
      points -= equipment[index].upgradeCost;
      equipment[index].level++;
      equipment[index].upgradeCost += 200;
      notifyListeners();
    }
  }

  void powerUpGuardian() {
    if (points >= 500) {
      points -= 500;
      guardianLevel++;
      guardianBasePower += 150;
      notifyListeners();
    }
  }

  void classify() {
    if (swipeQueue.isNotEmpty) {
      swipeQueue.removeAt(0);
      _addPoints(30);
      notifyListeners();
    }
  }
}

final mockService = MockService();

// ##########################################
// UI NAVIGATION
// ##########################################
class KachingApp extends StatelessWidget {
  const KachingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF556B2F), textTheme: GoogleFonts.outfitTextTheme()),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final screens = [const Dashboard(), const Vault(), const SwipeLab(), const Guardian(), const Rewards()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.swipe_outlined), label: 'Lab'),
          NavigationDestination(icon: Icon(Icons.catching_pokemon_outlined), label: 'Hero'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Gift'),
        ],
      ),
    );
  }
}

// ##########################################
// SCREEN: DASHBOARD
// ##########################################
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  void _showAction(BuildContext context, bool isSalary) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isSalary ? "Deposit Salary" : "Pay Merchant", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: "RM ")),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: isSalary ? Colors.green : Colors.black, foregroundColor: Colors.white),
              onPressed: () {
                double val = double.tryParse(ctrl.text) ?? 0;
                if (isSalary) {
                  mockService.processSalary(val);
                  Navigator.pop(context);
                } else {
                  String result = mockService.processSpend(val, "Local Spend");
                  Navigator.pop(context);
                  _showIntervention(context, result);
                }
              },
              child: const Text("CONFIRM"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showIntervention(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: msg.contains("📉") || msg.contains("⚠️") || msg.contains("🆘") ? Colors.redAccent : const Color(0xFF556B2F),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mockService,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _topHeader(),
              const SizedBox(height: 20),
              _balanceCard(),
              const SizedBox(height: 20),
              _dailyBudgetMeter(),
              const SizedBox(height: 30),
              const Text("Transactions", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...mockService.transactions.map((t) => _txTile(t)),
            ]),
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(heroTag: "in", onPressed: () => _showAction(context, true), label: const Text("CASH IN"), icon: const Icon(Icons.add), backgroundColor: Colors.green, foregroundColor: Colors.white),
            const SizedBox(width: 10),
            FloatingActionButton.extended(heroTag: "out", onPressed: () => _showAction(context, false), label: const Text("CASH OUT"), icon: const Icon(Icons.remove), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Hi, Alex 👋"), Text("Kaching! Pro", style: TextStyle(color: Colors.grey, fontSize: 12))]),
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text("🔥 ${mockService.savingsStreak} Streak", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF556B2F), borderRadius: BorderRadius.circular(25)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("SPENDABLE BALANCE", style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text("RM ${mockService.spendableBalance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24, height: 30),
        Text("Total 100% Assets: RM ${mockService.totalNetWorth.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _dailyBudgetMeter() {
    double progress = (mockService.dailySpent / mockService.dailyBudget).clamp(0, 1);
    Color color = mockService.dailySpent > mockService.dailyBudget ? Colors.red : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Daily Budget (RM 30.00)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text("Spent: RM ${mockService.dailySpent.toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 8),
      ]),
    );
  }

  Widget _txTile(Map t) {
    bool isExp = t['type'] == 'expense';
    double total = t['base'] + t['round'];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text("RM ${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
      title: Text(t['name']),
      subtitle: isExp ? Text("Base: ${t['base'].toStringAsFixed(2)} + Round: ${t['round'].toStringAsFixed(2)} 🪄", style: const TextStyle(fontSize: 10, color: Colors.grey)) : const Text("Income"),
      trailing: Icon(isExp ? Icons.arrow_outward : Icons.south_west, color: isExp ? Colors.red : Colors.green, size: 16),
    );
  }
}

// ##########################################
// SCREEN: VAULT
// ##########################################
class Vault extends StatelessWidget {
  const Vault({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: mockService, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text("Wealth Distribution")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Asset Breakdown (Total 100%)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            // PROOF OF 100% CALCULATION
            _buildSpecialSpendableTile(),
            ...mockService.pockets.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Icon(p.icon, color: p.color),
                    const SizedBox(width: 10),
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text("RM ${p.current.toStringAsFixed(2)}"),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: p.percent, color: p.color, minHeight: 6),
                  const SizedBox(height: 5),
                  Align(alignment: Alignment.centerRight, child: Text("${p.allocationPercent}% Income Allocation", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                ]),
              ),
            )),
          ],
        ),
      ),
    ));
  }

  Widget _buildSpecialSpendableTile() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet, color: Colors.blue),
            const SizedBox(width: 10),
            const Text("Daily Spendable", style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text("RM ${mockService.spendableBalance.toStringAsFixed(2)}"),
          ]),
          const SizedBox(height: 10),
          const LinearProgressIndicator(value: 1.0, color: Colors.blue, minHeight: 6),
          const SizedBox(height: 5),
          const Align(alignment: Alignment.centerRight, child: Text("10% Income Allocation", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}

// ##########################################
// SCREEN: SWIPE LAB
// ##########################################
class SwipeLab extends StatelessWidget {
  const SwipeLab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: mockService, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text("AI Trainer")),
      body: mockService.swipeQueue.isEmpty 
        ? const Center(child: Text("All items classified! 🎉"))
        : Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Draggable(onDragEnd: (d) => mockService.classify(), feedback: _card(mockService.swipeQueue.first), child: _card(mockService.swipeQueue.first)),
              const SizedBox(height: 40),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Column(children: [Text("☁️", style: TextStyle(fontSize: 30)), Text("WANT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                Column(children: [Text("🍞", style: TextStyle(fontSize: 30)), Text("NEED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
              ]),
            ],
          )),
    ));
  }

  Widget _card(Map item) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280, height: 350,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(item['icon'], size: 50, color: const Color(0xFF556B2F)),
          const SizedBox(height: 20),
          Text(item['merchant'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("RM ${item['amount'].toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, color: Colors.orange)),
          const SizedBox(height: 10),
          Chip(label: Text(item['cat'])),
        ]),
      ),
    );
  }
}

// ##########################################
// SCREEN: GUARDIAN
// ##########################################
class Guardian extends StatelessWidget {
  const Guardian({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: mockService, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text("Guardian Peak")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _heroCard(),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("Duel Arena", style: TextStyle(fontWeight: FontWeight.bold))),
          ...mockService.leaderboard.map((u) => Card(
            color: u['isMe'] ? Colors.orange.withOpacity(0.05) : null,
            child: ListTile(
              leading: Text(u['avatar'], style: const TextStyle(fontSize: 24)),
              title: Text(u['name']),
              subtitle: Row(children: (u['badges'] as List).map((b) => const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.verified, size: 12, color: Colors.blue))).toList()),
              trailing: u['isMe'] ? Text("Pwr: ${mockService.totalPower}") : const Icon(Icons.bolt, color: Colors.orange),
              onTap: u['isMe'] ? null : () => _showDuel(context, u['name']),
            ),
          )),
          const SizedBox(height: 25),
          const Align(alignment: Alignment.centerLeft, child: Text("Armory", style: TextStyle(fontWeight: FontWeight.bold))),
          ...mockService.equipment.asMap().entries.map((e) => ListTile(
            leading: Text(e.value.icon, style: const TextStyle(fontSize: 20)),
            title: Text("${e.value.name} (Lv. ${e.value.level})"),
            trailing: ElevatedButton(onPressed: () => mockService.upgradeEquip(e.key), child: Text("${e.value.upgradeCost} Pts")),
          )),
        ]),
      ),
    ));
  }

  void _showDuel(BuildContext context, String enemy) {
    bool win = Random().nextDouble() > 0.3; 
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(win ? "Victory! 🎉" : "Defeated... 🛡️"),
      content: Text(win ? "⚔️ Your Sylvaris outclassed $enemy!" : "⚔️ $enemy was better prepared."),
      actions: [TextButton(onPressed: () {
        mockService.points += win ? 150 : 10;
        Navigator.pop(c);
      }, child: Text(win ? "CLAIM 150 PTS" : "TAKE 10 PTS"))],
    ));
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF556B2F), Color(0xFF2D361E)]), borderRadius: BorderRadius.circular(30)),
      child: Column(children: [
        const Text("🐧", style: TextStyle(fontSize: 70)),
        Text("Sylvaris Lv.${mockService.guardianLevel}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24, height: 30),
        const Text("SPENDABLE POINTS", style: TextStyle(color: Colors.white70, fontSize: 10)),
        Text("${mockService.points}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () => mockService.powerUpGuardian(), child: const Text("Level Up (500 Pts)")),
      ]),
    );
  }
}

// ##########################################
// SCREEN: REWARDS
// ##########################################
class Rewards extends StatelessWidget {
  const Rewards({super.key});

  void _claimStreakBonus(BuildContext context) {
    if (mockService.savingsStreak > 0 && !mockService.streakClaimedToday) {
      int bonus = mockService.savingsStreak * 2;
      mockService.claimStreakBonus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Streak Claimed! +$bonus Points!"), backgroundColor: Colors.orange));
    }
  }

  void _redeem(BuildContext context, String title, int cost) {
    bool success = mockService.redeemVoucher(cost);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? "Redeemed $title!" : "Not enough points!"),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: mockService, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text("Rewards")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF556B2F), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(children: [const Text("STREAK", style: TextStyle(color: Colors.white70)), Text("${mockService.savingsStreak} Days", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                Column(children: [const Text("WALLET", style: TextStyle(color: Colors.white70)), Text("${mockService.points} Pts", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))]),
              ]),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: (mockService.savingsStreak > 0 && !mockService.streakClaimedToday) ? () => _claimStreakBonus(context) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 45)),
                child: Text(mockService.streakClaimedToday ? "Already Claimed" : "Claim Streak Bonus (+${mockService.savingsStreak * 2} Pts)"),
              )
            ]),
          ),
          const SizedBox(height: 30),
          _rewardTile(context, "RM 5 Cashback", "GrabPay Voucher", 500, Icons.wallet),
          _rewardTile(context, "10% Off Coffee", "Zus Coffee Coupon", 300, Icons.coffee),
          _rewardTile(context, "RM 2 Shopee", "Marketplace Disc", 200, Icons.shopping_bag),
        ]),
      ),
    ));
  }

  Widget _rewardTile(BuildContext ctx, String title, String sub, int cost, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF556B2F)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: ElevatedButton(onPressed: () => _redeem(ctx, title, cost), child: Text("$cost Pts")),
      ),
    );
  }
}