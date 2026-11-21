import 'dart:math';

import 'package:equatable/equatable.dart';

/// A multiplication question only a grown-up is likely to answer quickly.
class ParentGateChallenge extends Equatable {
  const ParentGateChallenge({required this.left, required this.right});

  /// Generates a fresh challenge with factors from 6 to 9.
  factory ParentGateChallenge.random(Random random) => ParentGateChallenge(
    left: 6 + random.nextInt(4),
    right: 6 + random.nextInt(4),
  );

  final int left;
  final int right;

  int get answer => left * right;

  String get question => '$left × $right =';

  bool isCorrect(String input) => int.tryParse(input) == answer;

  @override
  List<Object?> get props => [left, right];
}
