import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class ReportBugEmailScreen extends StatefulWidget {
  const ReportBugEmailScreen({super.key});

  @override
  _ReportBugEmailScreenState createState() => _ReportBugEmailScreenState();
}

class _ReportBugEmailScreenState extends State<ReportBugEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final featureTitle = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final email = Email(
      body: description,
      subject: 'bug - $featureTitle',
      recipients: ['devulopa@gmail.com'],
    );

    setState(() => _isSending = true);
    try {
      await FlutterEmailSender.send(email);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bug report sent successfully!'),
          ),
        );
        _titleController.clear();
        _descriptionController.clear();
      });
    } on FormatException catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Unable to send email')),
        );
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Bug Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title of the Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: _isSending
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _sendEmail,
                  child: const Text('Send Email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
