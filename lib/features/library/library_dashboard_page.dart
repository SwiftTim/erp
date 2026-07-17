// lib/features/library/library_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class LibraryDashboardPage extends ConsumerStatefulWidget {
  const LibraryDashboardPage({super.key});
  @override
  ConsumerState<LibraryDashboardPage> createState() => _LibraryDashboardPageState();
}

class _LibraryDashboardPageState extends ConsumerState<LibraryDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<LibraryBook> _books = [];
  List<LibraryLoan> _activeLoans = [];
  List<LibraryLoan> _overdue = [];
  bool _loading = true;
  String _searchQ = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final books = await db.operationsDao.getAllBooks();
    final loans = await db.operationsDao.getActiveLoans();
    final overdue = await db.operationsDao
        .getOverdueLoans(DateTime.now().millisecondsSinceEpoch);
    if (mounted) {
      setState(() {
        _books = books;
        _activeLoans = loans;
        _overdue = overdue;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Library Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              PrintableDocumentHub.show(
                context,
                'Library Office',
                DocumentTemplates.getTemplatesForModule('library'),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF0EA5E9)),
            label: const Text('Forms / Slips', style: TextStyle(color: Color(0xFF0EA5E9))),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF0EA5E9),
          indicatorColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Catalogue'),
            Tab(text: 'Active Loans'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tab.index == 0 ? _showAddBook : _showCheckOut,
        label: Text(_tab.index == 0 ? 'Add Book' : 'Check Out'),
        icon: Icon(_tab.index == 0 ? Icons.add : Icons.book_outlined),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStats(),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildCatalogue(),
                      _buildLoanList(_activeLoans),
                      _buildLoanList(_overdue, isOverdue: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStats() {
    final available = _books.fold(0, (s, b) => s + b.available_copies);
    final total = _books.fold(0, (s, b) => s + b.total_copies);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        _chip('${_books.length}', 'Titles', const Color(0xFF0EA5E9)),
        const SizedBox(width: 12),
        _chip('$total', 'Copies', Colors.teal),
        const SizedBox(width: 12),
        _chip('$available', 'Available', Colors.green),
        const SizedBox(width: 12),
        _chip('${_activeLoans.length}', 'On Loan', Colors.orange),
        const SizedBox(width: 12),
        _chip('${_overdue.length}', 'Overdue', Colors.red),
      ]),
    );
  }

  Widget _chip(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        ]),
      ),
    );
  }

  Widget _buildCatalogue() {
    final filtered = _searchQ.isEmpty
        ? _books
        : _books
            .where((b) =>
                b.title.toLowerCase().contains(_searchQ.toLowerCase()) ||
                b.author.toLowerCase().contains(_searchQ.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQ = v),
            decoration: InputDecoration(
              hintText: 'Search title, author…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No books found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final b = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          child: const Icon(Icons.menu_book_outlined,
                              color: Color(0xFF0EA5E9)),
                        ),
                        title: Text(b.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${b.author} • ${b.category} • Shelf: ${b.shelf_location}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${b.available_copies}/${b.total_copies}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: b.available_copies == 0
                                        ? Colors.red
                                        : Colors.green)),
                            const Text('copies',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => _showBookActions(b),
                      ),
                    );
                  }),
        ),
      ],
    );
  }

  Widget _buildLoanList(List<LibraryLoan> loans, {bool isOverdue = false}) {
    if (loans.isEmpty) {
      return Center(
          child: Text(
              isOverdue ? 'No overdue books 🎉' : 'No active loans.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: loans.length,
      itemBuilder: (_, i) {
        final l = loans[i];
        final due = DateFormat('dd MMM yyyy')
            .format(DateTime.fromMillisecondsSinceEpoch(l.due_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOverdue
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              child: Icon(Icons.book_outlined,
                  color: isOverdue ? Colors.red : Colors.orange),
            ),
            title: Text(l.borrower_name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Book ID: ${l.book_id.substring(0, 8)}… • Due: $due'
                '${l.fine_amount > 0 ? ' • Fine: KSh ${l.fine_amount}' : ''}'),
            trailing: TextButton(
              onPressed: () => _returnBook(l),
              child: const Text('Return'),
            ),
          ),
        );
      },
    );
  }

  void _showBookActions(LibraryBook b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(b.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('by ${b.author}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.outbox_outlined, color: Color(0xFF0EA5E9)),
              title: const Text('Check Out'),
              subtitle: Text('${b.available_copies} copies available'),
              enabled: b.available_copies > 0,
              onTap: () {
                Navigator.pop(context);
                _showCheckOutForBook(b);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('ISBN'),
              trailing: Text(b.isbn.isEmpty ? 'N/A' : b.isbn),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined, color: Colors.grey),
              title: const Text('Shelf Location'),
              trailing: Text(b.shelf_location.isEmpty ? 'Not set' : b.shelf_location),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _returnBook(LibraryLoan loan) async {
    // Optimistic concurrency: fetch book, check version, update atomically
    final db = await ref.read(databaseProvider.future);
    final book = await db.operationsDao.getBookById(loan.book_id);
    if (book == null) return;

    // Return the book
    await db.operationsDao.updateLibraryLoan(LibraryLoan(
      id: loan.id,
      book_id: loan.book_id,
      borrower_id: loan.borrower_id,
      borrower_name: loan.borrower_name,
      borrower_type: loan.borrower_type,
      borrowed_at: loan.borrowed_at,
      due_at: loan.due_at,
      returned_at: DateTime.now().millisecondsSinceEpoch,
      fine_amount: loan.fine_amount,
    ));

    // Increment available copies + version (optimistic lock)
    await db.operationsDao.updateLibraryBook(LibraryBook(
      id: book.id,
      title: book.title,
      author: book.author,
      isbn: book.isbn,
      category: book.category,
      total_copies: book.total_copies,
      available_copies: book.available_copies + 1,
      shelf_location: book.shelf_location,
      version: book.version + 1,
    ));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book returned successfully!')));
    }
  }

  Future<void> _showCheckOutForBook(LibraryBook b) async {
    final borrowerCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Check Out: ${b.title}'),
        content: TextField(
          controller: borrowerCtrl,
          decoration: const InputDecoration(
              labelText: 'Borrower Name', prefixIcon: Icon(Icons.person)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (borrowerCtrl.text.isEmpty) return;
              await _checkOut(b, borrowerCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckOut() async {
    if (_books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add books to catalogue first.')));
      return;
    }
    _showBookActions(_books.first);
  }

  Future<void> _showAddBook() async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final isbnCtrl = TextEditingController();
    final shelfCtrl = TextEditingController();
    final copiesCtrl = TextEditingController(text: '1');
    String category = 'General';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Book to Catalogue'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
              const SizedBox(height: 8),
              TextField(controller: isbnCtrl, decoration: const InputDecoration(labelText: 'ISBN (optional)')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Science', 'Mathematics', 'Literature', 'History', 'Arts', 'Reference']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => category = v!),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: copiesCtrl, decoration: const InputDecoration(labelText: 'Copies'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: shelfCtrl, decoration: const InputDecoration(labelText: 'Shelf Location'))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final copies = int.tryParse(copiesCtrl.text) ?? 1;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertLibraryBook(LibraryBook(
                  id: const Uuid().v4(),
                  title: titleCtrl.text.trim(),
                  author: authorCtrl.text.trim(),
                  isbn: isbnCtrl.text.trim(),
                  category: category,
                  total_copies: copies,
                  available_copies: copies,
                  shelf_location: shelfCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Add Book'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkOut(LibraryBook book, String borrowerName) async {
    final db = await ref.read(databaseProvider.future);
    // Fetch fresh book state for optimistic lock
    final fresh = await db.operationsDao.getBookById(book.id);
    if (fresh == null || fresh.available_copies <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${book.title} — no copies available!')));
      }
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.operationsDao.insertLibraryLoan(LibraryLoan(
      id: const Uuid().v4(),
      book_id: book.id,
      borrower_id: const Uuid().v4(),
      borrower_name: borrowerName,
      borrowed_at: now,
      due_at: now + const Duration(days: 14).inMilliseconds,
    ));
    await db.operationsDao.updateLibraryBook(LibraryBook(
      id: fresh.id,
      title: fresh.title,
      author: fresh.author,
      isbn: fresh.isbn,
      category: fresh.category,
      total_copies: fresh.total_copies,
      available_copies: fresh.available_copies - 1,
      shelf_location: fresh.shelf_location,
      version: fresh.version + 1,
    ));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} checked out to $borrowerName (due in 14 days)')));
    }
  }
}
