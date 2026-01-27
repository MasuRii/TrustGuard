import '../models/group.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.success() => const ValidationResult(isValid: true);
  factory ValidationResult.failure(String message) =>
      ValidationResult(isValid: false, errorMessage: message);
}

class Validators {
  static ValidationResult validateExpense({
    required int totalAmountMinor,
    required List<int> participantAmountsMinor,
  }) {
    if (totalAmountMinor <= 0) {
      return ValidationResult.failure('Total amount must be greater than zero');
    }

    if (participantAmountsMinor.isEmpty) {
      return ValidationResult.failure('At least one participant is required');
    }

    final sumOwed = participantAmountsMinor.fold<int>(
      0,
      (sum, amt) => sum + amt,
    );
    if (sumOwed != totalAmountMinor) {
      return ValidationResult.failure(
        'The sum of participant amounts ($sumOwed) must equal the total amount ($totalAmountMinor)',
      );
    }

    return ValidationResult.success();
  }

  static ValidationResult validatePercentageSum(
    Map<String, double> percentages,
  ) {
    if (percentages.isEmpty) {
      return ValidationResult.failure('At least one participant is required');
    }
    final sum = percentages.values.fold<double>(0, (s, p) => s + p);
    // Use a small epsilon for floating point comparison
    if ((sum - 100.0).abs() > 0.001) {
      return ValidationResult.failure(
        'Total percentage must be 100% (currently ${sum.toStringAsFixed(0)}%)',
      );
    }
    return ValidationResult.success();
  }

  static ValidationResult validateTransfer({
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
  }) {
    if (amountMinor <= 0) {
      return ValidationResult.failure(
        'Transfer amount must be greater than zero',
      );
    }

    if (fromMemberId == toMemberId) {
      return ValidationResult.failure(
        'Cannot transfer money to the same person',
      );
    }

    return ValidationResult.success();
  }

  static ValidationResult validateGroup(Group group) {
    if (group.name.trim().isEmpty) {
      return ValidationResult.failure('Group name cannot be empty');
    }

    if (group.currencyCode.trim().length != 3 ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(group.currencyCode.toUpperCase())) {
      return ValidationResult.failure('Invalid currency code');
    }

    return ValidationResult.success();
  }
}
