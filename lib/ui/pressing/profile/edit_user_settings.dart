import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class EditWorkingHoursDialog extends StatefulWidget {

  const EditWorkingHoursDialog({
    required this.onSubmit,
    required this.hourlyRateController,
    super.key,
  });
  final void Function(double, double) onSubmit;
  final TextEditingController hourlyRateController;

  @override
  _EditWorkingHoursDialogState createState() => _EditWorkingHoursDialogState();
}

class _EditWorkingHoursDialogState extends State<EditWorkingHoursDialog> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit your settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: customTextField(
                      controller: _hoursController,
                      hintText: 'Hours',
                      labelText: 'Hours',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: customTextField(
                      controller: _minutesController,
                      hintText: 'Minutes',
                      labelText: 'Minutes',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              customTextField(
                controller: widget.hourlyRateController,
                hintText: 'New hourly rate',
                labelText: 'New hourly rate',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Submit'),
                    onPressed: () {
                      final hours = int.tryParse(_hoursController.text) ?? 0;
                      final minutes = int.tryParse(_minutesController.text) ?? 0;
                      final hourlyRate = double.tryParse(
                        widget.hourlyRateController.text,
                      ) ?? 0;

                      // Convert hours and minutes to a double representing the total hours
                      final totalHours = hours + (minutes / 60.0);

                      widget.onSubmit(totalHours, hourlyRate);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
