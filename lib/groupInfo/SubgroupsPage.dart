import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubgroupsPage extends StatefulWidget {
  final String groupId;

  const SubgroupsPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _SubgroupsPageState createState() => _SubgroupsPageState();
}

class _SubgroupsPageState extends State<SubgroupsPage> {
  final TextEditingController _subgroupNameController = TextEditingController();
  List<Map<String, dynamic>> _subgroups = []; // To store subgroup data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubgroups(); // Fetch subgroups on page load
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
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
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
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add New Subgroup",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _subgroupNameController,
                decoration: InputDecoration(
                  labelText: "Subgroup Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final subgroupName = _subgroupNameController.text;
                  if (subgroupName.isNotEmpty) {
                    _addSubgroup(subgroupName);
                    Navigator.pop(context);
                  }
                },
                child: Text("Add Subgroup"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
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
        backgroundColor: Color(0xFFF8ECE0),
        title: Text("Subgroups"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
              : Center(child: Text("No subgroups available")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubgroupDrawer,
        backgroundColor: Color(0xFFF8ECE0),
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class SubgroupCard extends StatelessWidget {
  final String name;
  final int memberCount;

  const SubgroupCard({required this.name, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Text(
          '$memberCount members',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }
}
