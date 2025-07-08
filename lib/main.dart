import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gider Takip',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExpensesListPage(),
    );
  }
}

class ExpensesListPage extends StatefulWidget {
  const ExpensesListPage({super.key});

  @override
  State<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  Database? _database;
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'expenses.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE expenses(id INTEGER PRIMARY KEY, name TEXT, date TEXT, amount REAL)',
        );
      },
      version: 1,
    );
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    final List<Map<String, dynamic>> maps =
    await _database!.query('expenses', orderBy: "date DESC");
    setState(() {
      _expenses = maps;
    });
  }

  Future<void> _deleteExpense(int id) async {
    await _database!.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    _fetchExpenses();
  }

  double get totalAmount {
    double total = 0;
    for (var exp in _expenses) {
      total += exp['amount'] as double;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Listesi'),
      ),
      body: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toplam Gider: ₺${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final exp = _expenses[index];
                  return Card(
                    child: ListTile(
                      title: Text(exp['name']),
                      subtitle: Text(exp['date']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₺${exp['amount'].toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteExpense(exp['id'] as int);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpenseAddPage(database: _database!),
            ),
          );
          _fetchExpenses();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ExpenseAddPage extends StatefulWidget {
  final Database database;

  const ExpenseAddPage({super.key, required this.database});

  @override
  State<ExpenseAddPage> createState() => _ExpenseAddPageState();
}

class _ExpenseAddPageState extends State<ExpenseAddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      await widget.database.insert(
        'expenses',
        {
          'name': _nameController.text,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'amount': double.tryParse(_amountController.text) ?? 0.0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (mounted) {
        Navigator.of(context as BuildContext).pop(); // Kayıt sonrası direkt geri dön
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Gider Ekle')),
      body: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Gider Adı'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Tarih: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                  ),
                  const Spacer(),
                  TextButton(
                    child: const Text('Tarih Seç'),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  )
                ],
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Tutar'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || value.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('Kaydet'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
