import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseAddPage extends StatefulWidget {
  final Database database;
  final Map<String, dynamic>? expense;

  const ExpenseAddPage({
    super.key,
    required this.database,
    this.expense,
  });

  @override
  State<ExpenseAddPage> createState() => _ExpenseAddPageState();
}

class _ExpenseAddPageState extends State<ExpenseAddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _nameController.text = widget.expense!['name'];
      _selectedDate = DateTime.tryParse(widget.expense!['date']) ?? DateTime.now();
      _amountController.text = widget.expense!['amount'].toString();
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (widget.expense == null) {
        // Yeni kayıt
        await widget.database.insert(
          'expenses',
          {
            'name': _nameController.text,
            'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
            'amount': double.tryParse(_amountController.text) ?? 0.0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Güncelleme
        await widget.database.update(
          'expenses',
          {
            'name': _nameController.text,
            'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
            'amount': double.tryParse(_amountController.text) ?? 0.0,
          },
          where: 'id = ?',
          whereArgs: [widget.expense!['id']],
        );
      }
      if (mounted) {
        Navigator.of(context).pop(); // Hata burada context as BuildContext gereksizdi, context zaten BuildContext
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final width = size.width;
    final horizontalPadding = isWide ? width * 0.22 : width * 0.06;
    final inputFontSize = isWide ? 22.0 : 16.0;
    final labelFontSize = isWide ? 20.0 : 15.0;
    final buttonFontSize = isWide ? 22.0 : 18.0;
    final buttonHeight = isWide ? 60.0 : 48.0;
    final appBarFontSize = isWide ? 28.0 : 22.0;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expense == null ? 'Gider Ekle' : 'Gider Güncelle', style: TextStyle(fontSize: appBarFontSize)),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isWide ? 32 : 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(fontSize: inputFontSize),
                      decoration: InputDecoration(
                        labelText: 'Gider Adı',
                        labelStyle: TextStyle(fontSize: labelFontSize),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Zorunlu alan' : null,
                    ),
                    SizedBox(height: isWide ? 24 : 16),
                    Row(
                      children: [
                        Text(
                          'Tarih: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                          style: TextStyle(fontSize: isWide ? 18 : 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Tarih Seç', style: TextStyle(fontSize: isWide ? 18 : 15)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                    SizedBox(height: isWide ? 24 : 16),
                    TextFormField(
                      controller: _amountController,
                      style: TextStyle(fontSize: inputFontSize),
                      decoration: InputDecoration(
                        labelText: 'Tutar',
                        labelStyle: TextStyle(fontSize: labelFontSize),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Zorunlu alan' : null,
                    ),
                    SizedBox(height: isWide ? 36 : 28),
                    SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold),
                        ),
                        child: Text(widget.expense == null ? 'Kaydet' : 'Güncelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 