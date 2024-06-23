import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ElectronicRosaryApp());
}

class ElectronicRosaryApp extends StatelessWidget {
  const ElectronicRosaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electronic Rosary',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const RosaryHomePage(),
    );
  }
}

class RosaryHomePage extends StatefulWidget {
  const RosaryHomePage({super.key});

  @override
  _RosaryHomePageState createState() => _RosaryHomePageState();
}

class _RosaryHomePageState extends State<RosaryHomePage> {
  List<Map<String, dynamic>> _tasbihList = [];
  int _currentIndex = 0;
  int _counter = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadTasbihList();
  }

  Future<void> _loadTasbihList() async {
    List<Map<String, dynamic>> tasbihs = await _dbHelper.getTasbihs();
    setState(() {
      _tasbihList = tasbihs;
    });
    if (_tasbihList.isNotEmpty) {
      _loadCounter();
    }
  }

  Future<void> _loadCounter() async {
    if (_tasbihList.isNotEmpty) {
      int count =
          await _dbHelper.getTasbihCount(_tasbihList[_currentIndex]['id']);
      setState(() {
        _counter = count;
      });
    }
  }

  Future<void> _incrementCounter() async {
    if (_tasbihList.isNotEmpty) {
      setState(() {
        _counter++;
      });
      await _dbHelper.addHistory(_tasbihList[_currentIndex]['id'], 1);
      if (_counter % 33 == 0) {
        Vibration.vibrate(duration: 100);
      }
    }
  }

  Future<void> _resetCounter() async {
    if (_tasbihList.isNotEmpty) {
      setState(() {
        _counter = 0;
      });
      await _dbHelper.addHistory(_tasbihList[_currentIndex]['id'], -_counter);
    }
  }

  Future<void> _addTasbih(String tasbih) async {
    await _dbHelper.addTasbih(tasbih);
    await _loadTasbihList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electronic Rosary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HistoryPage(_tasbihList)),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _incrementCounter,
        child: Center(
          child: _tasbihList.isEmpty
              ? const Text('No Tasbih added yet.')
              : PageView.builder(
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _loadCounter();
                    });
                  },
                  itemCount: _tasbihList.length,
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _tasbihList[index]['text'],
                          style: Theme.of(context).textTheme.headlineMedium,
                          
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Count: $_counter',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _resetCounter,
                          child: const Text('Reset'),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? result = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              String newTasbih = '';
              return AlertDialog(
                title: const Text('Add Tasbih'),
                content: TextField(
                  onChanged: (value) {
                    newTasbih = value;
                  },
                  decoration: const InputDecoration(hintText: "Enter Tasbih"),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, newTasbih);
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
          if (result != null && result.isNotEmpty) {
            _addTasbih(result);
          }
        },
        tooltip: 'Add Tasbih',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> tasbihList;

  const HistoryPage(this.tasbihList, {super.key});

  Future<int> _loadHistory(int tasbihId) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    int count = await dbHelper.getTasbihCount(tasbihId);
    return count;
  }

  Future<void> _resetHistory(int tasbihId) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.resetTasbihHistory(tasbihId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        itemCount: tasbihList.length,
        itemBuilder: (context, index) {
          int tasbihId = tasbihList[index]['id'];
          String tasbihText = tasbihList[index]['text'];
          return FutureBuilder<int>(
            future: _loadHistory(tasbihId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                  title: Text(tasbihText),
                  subtitle: const Text('Loading...'),
                );
              }
              if (snapshot.hasError) {
                return ListTile(
                  title: Text(tasbihText),
                  subtitle: const Text('Error loading history'),
                );
              }
              int count = snapshot.data ?? 0;
              return ListTile(
                title: Text(tasbihText),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Count: $count'),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _resetHistory(tasbihId);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
