import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubgroupsPage extends StatefulWidget {
  final String groupId;

  const SubgroupsPage({super.key, required this.groupId});

  @override
  _SubgroupsPageState createState() => _SubgroupsPageState();
}

class _SubgroupsPageState extends State<SubgroupsPage> {
  final TextEditingController _subgroupNameController = TextEditingController();
  List<Map<String, dynamic>> _subgroups = []; // To store subgroup data
  bool isLoading = true;
  bool isAdmin = false; // Track if the user is an admin

  @override
  void initState() {
    super.initState();
    _fetchGroupData(); // Fetch group data to check admin status
    _fetchSubgroups(); // Fetch subgroups on page load
  }

  Future<void> _fetchGroupData() async {
    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/groupMembers/${widget.groupId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final currentUserId =
            await _getCurrentUserId(); // Fetch the current user's ID
        setState(() {
          isAdmin = data['admins'].any((admin) =>
              admin['_id'] == currentUserId); // Check if user is admin
        });

        print(isAdmin);
      } else {
        print("Failed to fetch group data.");
      }
    } catch (e) {
      print("Error fetching group data: $e");
    }
  }

  Future<String?> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> _fetchSubgroups() async {
    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/subgroups/${widget.groupId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _subgroups = List<Map<String, dynamic>>.from(data['subgroups']);
          isLoading = false;
        });
      } else {
        _showSnackBar('Failed to load subgroups');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      _showSnackBar('Error loading subgroups');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addSubgroup(String subgroupName) async {
    if (!isAdmin) {
      _showSnackBar("Only admins can add subgroups");
      return;
    }

    final url = Uri.parse(
        '${Constants.serverUrl}/api/group/addSubgroup/${widget.groupId}');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"subgroupName": subgroupName}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showSnackBar(data['message'], isSuccess: true);
        _fetchSubgroups(); // Reload subgroups after adding
      } else {
        _showSnackBar('Failed to add subgroup');
      }
    } catch (e) {
      print("Error: $e");
      _showSnackBar('Error adding subgroup');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubgroupDrawer() {
    if (!isAdmin) {
      _showSnackBar("Only admins can add subgroups");
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add New Subgroup",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subgroupNameController,
                decoration: const InputDecoration(
                  labelText: "Subgroup Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final subgroupName = _subgroupNameController.text;
                  if (subgroupName.isNotEmpty) {
                    _addSubgroup(subgroupName);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text("Add Subgroup"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8ECE0),
        title: const Text("Subgroups"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subgroups.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _subgroups.length,
                  itemBuilder: (context, index) {
                    final subgroup = _subgroups[index];
                    return SubgroupCard(
                      name: subgroup['name'],
                      memberCount: subgroup['memberCount'],
                    );
                  },
                )
              : const Center(child: Text("No subgroups available")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubgroupDrawer,
        backgroundColor: const Color(0xFFF8ECE0),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class SubgroupCard extends StatelessWidget {
  final String name;
  final int memberCount;

  const SubgroupCard({super.key, required this.name, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Text(
          '$memberCount members',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }
}
