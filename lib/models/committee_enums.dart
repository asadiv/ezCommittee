enum CommitteeFrequency { daily, weekly, monthly, custom }

extension CommitteeFrequencyX on CommitteeFrequency {
  String get value => name;

  static CommitteeFrequency fromValue(String? value) {
    return CommitteeFrequency.values.firstWhere(
      (frequency) => frequency.value == value,
      orElse: () => CommitteeFrequency.monthly,
    );
  }
}

enum CommitteeState { gathering, active, completed }

extension CommitteeStateX on CommitteeState {
  String get value => name;

  static CommitteeState fromValue(String? value) {
    return CommitteeState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => CommitteeState.gathering,
    );
  }
}
