import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameChangeDialog extends StatefulWidget {
  final String currentUserName;
  final Function(String) onNameChanged;

  const NameChangeDialog({
    super.key,
    required this.currentUserName,
    required this.onNameChanged,
  });

  @override
  NameChangeDialogState createState() => NameChangeDialogState();
}

class NameChangeDialogState extends State<NameChangeDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUserName);
  }

  Future<void> _saveName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _controller.text);

    widget.onNameChanged(_controller.text);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Name'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Enter new name'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _saveName();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
