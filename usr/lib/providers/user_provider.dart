import 'dart:async';
import 'package:flutter/material.dart';

// Models
class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String inviteCode;
  final double balance;
  final int rewardCount;
  final String lastRewardDate;
  final bool hasPlan;
  final int withdrawCount;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.inviteCode,
    this.balance = 0.0,
    this.rewardCount = 0,
    this.lastRewardDate = '',
    this.hasPlan = false,
    this.withdrawCount = 0,
  });

  User copyWith({
    double? balance,
    int? rewardCount,
    String? lastRewardDate,
    bool? hasPlan,
    int? withdrawCount,
  }) {
    return User(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      inviteCode: inviteCode,
      balance: balance ?? this.balance,
      rewardCount: rewardCount ?? this.rewardCount,
      lastRewardDate: lastRewardDate ?? this.lastRewardDate,
      hasPlan: hasPlan ?? this.hasPlan,
      withdrawCount: withdrawCount ?? this.withdrawCount,
    );
  }
}

class Plan {
  final int id;
  final String name;
  final double price;
  final double dailyEarning;
  final bool comingSoon;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.dailyEarning,
    this.comingSoon = false,
  });
}

class ActivePlan {
  final String id;
  final String name;
  final double earningPerAd;
  int adsLeft;
  int nextReset; // Timestamp

  ActivePlan({
    required this.id,
    required this.name,
    required this.earningPerAd,
    this.adsLeft = 2,
    this.nextReset = 0,
  });
}

class Transaction {
  final String id;
  final String type; // 'deposit', 'withdraw', 'task'
  final double amount;
  final String description;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.date,
  });
}

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  
  // Mock Data Storage
  List<ActivePlan> _activePlans = [];
  List<Transaction> _transactions = [];
  
  // Config
  final List<Plan> availablePlans = [
    Plan(id: 1, name: "ZS Basic", price: 400, dailyEarning: 80),
    Plan(id: 2, name: "ZS Starter", price: 1000, dailyEarning: 180),
    Plan(id: 3, name: "ZS Booster", price: 2000, dailyEarning: 400),
    Plan(id: 4, name: "ZS Pro Plus", price: 5000, dailyEarning: 1000),
    Plan(id: 5, name: "ZS Premium", price: 10000, dailyEarning: 2000),
    Plan(id: 6, name: "ZS Ultra", price: 20000, dailyEarning: 4000),
    Plan(id: 7, name: "ZS Diamond", price: 50000, dailyEarning: 10000),
    Plan(id: 8, name: "ZS Future", price: 0, dailyEarning: 0, comingSoon: true),
  ];

  User? get user => _currentUser;
  bool get isLoading => _isLoading;
  List<ActivePlan> get activePlans => _activePlans;
  List<Transaction> get transactions => _transactions;

  // Auth Methods
  Future<void> login(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate network
    
    // Mock Login
    _currentUser = User(
      uid: 'user_123',
      name: 'Demo User',
      email: email,
      phone: '03001234567',
      inviteCode: 'ZS8810',
      balance: 50.0, // Signup bonus simulated
    );
    
    // Mock Data Init
    _activePlans = [];
    _transactions = [
      Transaction(
        id: 'tx_1',
        type: 'task',
        amount: 50.0,
        description: 'Signup Bonus',
        status: 'approved',
        date: DateTime.now().subtract(const Duration(days: 1)),
      )
    ];

    _setLoading(false);
    notifyListeners();
  }

  Future<void> signup(String name, String email, String phone, String password, String inviteCode) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));
    
    _currentUser = User(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      inviteCode: 'NEW${DateTime.now().second}',
      balance: 50.0, // Bonus
    );
    
    _transactions = [
      Transaction(
        id: 'tx_init',
        type: 'task',
        amount: 50.0,
        description: 'Signup Bonus',
        status: 'approved',
        date: DateTime.now(),
      )
    ];

    _setLoading(false);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _activePlans = [];
    _transactions = [];
    notifyListeners();
  }

  // Features
  Future<void> claimDailyReward() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    
    double reward = 10.0;
    _currentUser = _currentUser!.copyWith(
      balance: _currentUser!.balance + reward,
      rewardCount: _currentUser!.rewardCount + 1,
      lastRewardDate: DateTime.now().toIso8601String().split('T')[0],
    );
    
    _transactions.insert(0, Transaction(
      id: 'rew_${DateTime.now().millisecondsSinceEpoch}',
      type: 'task',
      amount: reward,
      description: 'Daily Gift Day ${_currentUser!.rewardCount}',
      status: 'approved',
      date: DateTime.now(),
    ));
    
    _setLoading(false);
    notifyListeners();
  }

  Future<String?> buyPlan(int planId) async {
    if (_currentUser == null) return "Not logged in";
    
    Plan? plan = availablePlans.firstWhere((p) => p.id == planId, orElse: () => availablePlans.last);
    if (plan.comingSoon) return "Plan coming soon";
    
    if (_currentUser!.balance < plan.price) {
      return "Insufficient balance. Need ${plan.price - _currentUser!.balance} more.";
    }
    
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    
    // Deduct balance
    _currentUser = _currentUser!.copyWith(
      balance: _currentUser!.balance - plan.price,
      hasPlan: true,
    );
    
    // Add Plan
    _activePlans.add(ActivePlan(
      id: 'ap_${DateTime.now().millisecondsSinceEpoch}',
      name: plan.name,
      earningPerAd: plan.dailyEarning / 2, // 2 ads per day assumption from JS
      adsLeft: 2,
    ));
    
    _setLoading(false);
    notifyListeners();
    return null; // Success
  }

  Future<void> watchAd(String activePlanId) async {
    if (_currentUser == null) return;
    
    int index = _activePlans.indexWhere((p) => p.id == activePlanId);
    if (index == -1) return;
    
    ActivePlan plan = _activePlans[index];
    if (plan.adsLeft <= 0) return;
    
    // Logic is handled in UI for timer, this is just the commit
    double earning = plan.earningPerAd;
    
    _currentUser = _currentUser!.copyWith(
      balance: _currentUser!.balance + earning,
    );
    
    plan.adsLeft -= 1;
    if (plan.adsLeft <= 0) {
      plan.nextReset = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
    }
    
    _transactions.insert(0, Transaction(
      id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
      type: 'task',
      amount: earning,
      description: 'Ad Watch - ${plan.name}',
      status: 'approved',
      date: DateTime.now(),
    ));
    
    notifyListeners();
  }

  Future<void> deposit(double amount, String method, String tid) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    
    _transactions.insert(0, Transaction(
      id: 'dep_${DateTime.now().millisecondsSinceEpoch}',
      type: 'deposit',
      amount: amount,
      description: 'Deposit via $method (TID: $tid)',
      status: 'pending',
      date: DateTime.now(),
    ));
    
    _setLoading(false);
    notifyListeners();
  }

  Future<void> withdraw(double amount, String method, String number) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = _currentUser!.copyWith(
      balance: _currentUser!.balance - amount,
      withdrawCount: _currentUser!.withdrawCount + 1,
    );
    
    _transactions.insert(0, Transaction(
      id: 'wd_${DateTime.now().millisecondsSinceEpoch}',
      type: 'withdraw',
      amount: amount,
      description: 'Withdraw to $method ($number)',
      status: 'pending',
      date: DateTime.now(),
    ));
    
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
