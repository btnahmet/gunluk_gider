import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'expense_add_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    if (Platform.isWindows) {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final documentsDirectory = await getApplicationSupportDirectory();
      final path = join(documentsDirectory.path, 'expenses.db');
      _database = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          onCreate: (db, version) {
            return db.execute(
              'CREATE TABLE expenses(id INTEGER PRIMARY KEY, name TEXT, date TEXT, amount REAL)',
            );
          },
          version: 1,
        ),
      );
    } else {
      _database = await openDatabase(
        path,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE expenses(id INTEGER PRIMARY KEY, name TEXT, date TEXT, amount REAL)',
          );
        },
        version: 1,
      );
    }

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
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final width = size.width;
    final horizontalPadding = isWide ? width * 0.18 : width * 0.04;
    final cardPadding = isWide ? 24.0 : 10.0;
    final cardFontSize = isWide ? 22.0 : 18.0;
    final cardAmountFontSize = isWide ? 22.0 : 18.0;
    final appBarFontSize = isWide ? 28.0 : 22.0;
    final totalFontSize = isWide ? 28.0 : 22.0;
    final fabSize = isWide ? 72.0 : 56.0;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gider Listesi', style: TextStyle(fontSize: appBarFontSize)),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam Gider: ₺${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: totalFontSize, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              SizedBox(height: isWide ? 18 : 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final exp = _expenses[index];
                    return Card(
                      elevation: 6,
                      margin: EdgeInsets.symmetric(vertical: isWide ? 14 : 8, horizontal: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: Colors.white,
                      shadowColor: Colors.deepPurple.withOpacity(0.2),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 20 : 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp['name'],
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: cardFontSize),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isWide ? 8 : 4),
                                  Text(
                                    exp['date'],
                                    style: TextStyle(color: Colors.grey, fontSize: isWide ? 17 : 15),
                                  ),
                                  SizedBox(height: isWide ? 8 : 4),
                                  Text(
                                    '₺${exp['amount'].toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: cardAmountFontSize, color: Colors.deepPurple, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ExpenseAddPage(
                                          database: _database!,
                                          expense: exp,
                                        ),
                                      ),
                                    );
                                    _fetchExpenses();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Silme Onayı'),
                                        content: const Text('Silmek istediğinizden emin misiniz?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Hayır'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Evet'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (shouldDelete == true) {
                                      _deleteExpense(exp['id'] as int);
                                    }
                                  },
                                ),
                              ],
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
        floatingActionButton: SizedBox(
          width: fabSize,
          height: fabSize,
          child: FloatingActionButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseAddPage(database: _database!),
                ),
              );
              _fetchExpenses();
            },
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
} 