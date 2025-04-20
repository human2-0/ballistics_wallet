import 'package:ballistics_wallet_flutter/providers/bonus_tables_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BonusTableV2 extends ConsumerWidget {
  const BonusTableV2({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bonusTableProvider);

    // Display loading indicator when data is being fetched
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (state.errorMessage != null) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }

    // Handle the display of the content


    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListWheelScrollView(
        diameterRatio: 1.5,
        itemExtent: MediaQuery.of(context).size.height * 0.25,
        children: state.listItems ?? [], // Use the list items from the state
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.red,
          child: const Icon(Icons.close),
        ),
    );
  }
}
