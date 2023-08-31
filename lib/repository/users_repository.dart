import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot documentSnapshot =
    await _db.collection('users').doc(userId).get();

    if (documentSnapshot.exists) {
      return documentSnapshot.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  Future<bool> editWorkingHours(String userId, double newWorkingHours) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .update({'workingHours': newWorkingHours});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editPaidBreaks(String userId, bool newPaidBreaks) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .update({'paidBreaks': newPaidBreaks});
      return true;
    } catch (e) {
      return false;
    }
  }



}

class UserState {
  final String? userId;
  final double? workingHours; // actual working hours
  final double? realWorkingHours; // effective working hours
  final double? allowance;
  final String? avatarUrl;
  final bool? paidBreaks;

  UserState({
    this.userId,
    this.workingHours,
    this.realWorkingHours,
    this.allowance,
    this.avatarUrl,
    this.paidBreaks,
  });

  UserState copyWith({
    String? userId,
    double? workingHours,
    double? realWorkingHours,
    double? allowance,
    String? avatarUrl,
    bool? paidBreaks,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      workingHours: workingHours ?? this.workingHours,
      realWorkingHours: realWorkingHours ?? this.realWorkingHours,
      allowance: allowance ?? this.allowance,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      paidBreaks: paidBreaks ?? this.paidBreaks,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository userRepository;

  UserNotifier(this.userRepository) : super(UserState());

  double calculateEffectiveWorkingHours(double workingHours) {
    if (workingHours == 8.0) {
      return workingHours - 1.0;
    } else if (workingHours == 4.0) {
      return workingHours - 0.25;
    } else if (workingHours == 6.0) {
      return workingHours - 0.5;
    } else {
      // return the original working hours if it does not match any conditions
      return workingHours;
    }
  }

  void loadUser(String userId) async {
    final userData = await userRepository.getUserData(userId);
    if (userData != null) {

      double? workingHours = userData['workingHours'] is int
          ? (userData['workingHours'] as int).toDouble()
          : userData['workingHours'] as double?;
      workingHours = calculateEffectiveWorkingHours(workingHours!);

      double? realWorkingHours = userData['workingHours'];

      double? allowance = userData['allowance'] is int
          ? (userData['allowance'] as int).toDouble()
          : userData['allowance'] as double?;

      // Ensure paidBreaks is never null
      bool paidBreaks = userData['paidBreaks'] ?? false;

      state = UserState(
        userId: userId,
        workingHours: workingHours,
        allowance: allowance,
        avatarUrl: userData['avatarUrl'],
        paidBreaks: paidBreaks,
        realWorkingHours: realWorkingHours,// Update with non-null value
      );
    }
  }


  Future<bool> editWorkingHours(double newWorkingHours) async {
    if (state.userId == null) return false;
    final result = await userRepository.editWorkingHours(state.userId!, newWorkingHours);
    if (result) {
      state = UserState(
        userId: state.userId,
        workingHours: newWorkingHours,
        allowance: state.allowance,
        avatarUrl: state.avatarUrl,
      );
    }
    return result;
  }

  void updateAllowance(double allowanceProvided) {
    state = state.copyWith(
      allowance: allowanceProvided,
    );
    print('new state of allowance ${state.allowance}');
  }

  void updateUser(UserState user) {
    state = user;
  }
}



final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider));
});

final userDataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getUserData(uid);
});

