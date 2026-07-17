// lib/features/library/library_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
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

  static const _accent = Color(0xFF0EA5E9); // sky blue

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await ref.read(databaseProvider.future);
    final books = await db.operationsDao.getAllBooks();
    final loans = await db.operationsDao.getActiveLoans();
    final overdue = await db.operationsDao.getOverdueLoans(DateTime.now().millisecondsSinceEpoch);
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
    final user = ref.watch(currentUserProvider);
    final available = _books.fold(0, (s, b) => s + b.available_copies);
    final total = _books.fold(0, (s, b) => s + b.total_copies);

    return AppShell(
      title: 'Library Hub',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
              context, 'Librarian Desk', DocumentTemplates.getTemplatesForModule('library')),
          icon: const Icon(Icons.print_outlined, size: 18, color: _accent),
          label: const Text('Forms', style: TextStyle(color: _accent)),
        ),
      ],
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildWelcomeCard(user, available, total),
                  const SizedBox(height: 24),
                  _buildStatsGrid(available, total),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, int available, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Librarian',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Total Catalogued', '$total'),
            const SizedBox(width: 32),
            _miniStat('Books On Loan', '${_activeLoans.length}'),
            const SizedBox(width: 32),
            _miniStat('Overdue Loans', '${_overdue.length}'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.auto_stories_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
      ]),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
    ],
  );

  Widget _buildStatsGrid(int available, int total) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 5 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
      children: [
        _statCard('Total Titles', '${_books.length}', Icons.menu_book_outlined, _accent),
        _statCard('Total Copies', '$total', Icons.library_books_outlined, Colors.teal),
        _statCard('Available', '$available', Icons.check_circle_outline, Colors.green),
        _statCard('On Loan', '${_activeLoans.length}', Icons.outbox_outlined, Colors.orange),
        _statCard('Overdue Alert', '${_overdue.length}', Icons.running_with_errors_outlined, Colors.red),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Library Records', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: _accent, indicatorColor: _accent,
            unselectedLabelColor: Colors.grey, dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Catalogue'),
              const Tab(text: 'Active Loans'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Overdue'),
                if (_overdue.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(radius: 8, backgroundColor: Colors.red,
                    child: Text('${_overdue.length}', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ],
              ])),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tab, children: [
              _buildCatalogueTab(),
              _buildLoanListTab(_activeLoans),
              _buildLoanListTab(_overdue, isOverdue: true),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildCatalogueTab() {
    final filtered = _searchQ.isEmpty
        ? _books
        : _books.where((b) => b.title.toLowerCase().contains(_searchQ.toLowerCase()) || b.author.toLowerCase().contains(_searchQ.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQ = v),
            decoration: InputDecoration(
              hintText: 'Search title, author or category...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching books found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final b = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _accent.withValues(alpha: 0.1), child: const Icon(Icons.menu_book_outlined, color: _accent, size: 18)),
                        title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${b.author} • Shelf: ${b.shelf_location}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${b.available_copies}/${b.total_copies}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: b.available_copies == 0 ? Colors.red : Colors.green)),
                            const Text('in shelf', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => _showBookActions(b),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLoanListTab(List<LibraryLoan> loans, {bool isOverdue = false}) {
    if (loans.isEmpty) {
      return Center(child: Text(isOverdue ? 'No overdue loans registered! 🎉' : 'No books currently checked out.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: loans.length,
      itemBuilder: (_, i) {
        final l = loans[i];
        final due = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(l.due_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOverdue ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              child: Icon(Icons.person_outline, color: isOverdue ? Colors.red : Colors.orange, size: 18),
            ),
            title: Text(l.borrower_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Due: $due${l.fine_amount > 0 ? ' • Fine: KSh ${l.fine_amount}' : ''}'),
            trailing: OutlinedButton(
              onPressed: () => _returnBook(l),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
              child: const Text('Return'),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _tab.index == 0 ? _showAddBook : _showCheckOut,
      label: Text(_tab.index == 0 ? 'Add Book' : 'Issue Book'),
      icon: Icon(_tab.index == 0 ? Icons.add : Icons.outbox_outlined),
      backgroundColor: _accent, foregroundColor: Colors.white,
    );
  }

  void _showBookActions(LibraryBook b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('by ${b.author}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 18),
          ListTile(
            leading: const Icon(Icons.outbox_outlined, color: _accent),
            title: const Text('Check Out / Issue Book'),
            subtitle: Text('${b.available_copies} of ${b.total_copies} copies currently available'),
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
            title: const Text('Shelf Location Shelf'),
            trailing: Text(b.shelf_location.isEmpty ? 'Not set' : b.shelf_location),
          ),
        ]),
      ),
    );
  }

  Future<void> _returnBook(LibraryLoan loan) async {
    final db = await ref.read(databaseProvider.future);
    final book = await db.operationsDao.getBookById(loan.book_id);
    if (book == null) return;
    await db.operationsDao.updateLibraryLoan(LibraryLoan(
      id: loan.id, book_id: loan.book_id, borrower_id: loan.borrower_id, borrower_name: loan.borrower_name,
      borrower_type: loan.borrower_type, borrowed_at: loan.borrowed_at, due_at: loan.due_at,
      returned_at: DateTime.now().millisecondsSinceEpoch, fine_amount: loan.fine_amount,
    ));
    await db.operationsDao.updateLibraryBook(LibraryBook(
      id: book.id, title: book.title, author: book.author, isbn: book.isbn, category: book.category,
      total_copies: book.total_copies, available_copies: book.available_copies + 1, shelf_location: book.shelf_location, version: book.version + 1,
    ));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book checked back in successfully! ✅')));
    }
  }

  Future<void> _showCheckOutForBook(LibraryBook b) async {
    final borrowerCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Issue: ${b.title}'),
        content: TextField(
          controller: borrowerCtrl,
          decoration: const InputDecoration(labelText: 'Borrower Full Name', prefixIcon: Icon(Icons.person)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add books to the catalogue first.')));
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
          title: const Text('Catalog New Book'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author Name')),
              const SizedBox(height: 8),
              TextField(controller: isbnCtrl, decoration: const InputDecoration(labelText: 'ISBN Prefix (optional)')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category, decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Science', 'Mathematics', 'Literature', 'History', 'Arts', 'Reference'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => category = v!),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: copiesCtrl, decoration: const InputDecoration(labelText: 'Total Copies'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: shelfCtrl, decoration: const InputDecoration(labelText: 'Shelf Section Code'))),
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
                  id: const Uuid().v4(), title: titleCtrl.text.trim(), author: authorCtrl.text.trim(),
                  isbn: isbnCtrl.text.trim(), category: category, total_copies: copies,
                  available_copies: copies, shelf_location: shelfCtrl.text.trim(),
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Register Book'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkOut(LibraryBook book, String borrowerName) async {
    final db = await ref.read(databaseProvider.future);
    final fresh = await db.operationsDao.getBookById(book.id);
    if (fresh == null || fresh.available_copies <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${book.title} — no copies available!')));
      }
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.operationsDao.insertLibraryLoan(LibraryLoan(
      id: const Uuid().v4(), book_id: book.id, borrower_id: const Uuid().v4(), borrower_name: borrowerName,
      borrowed_at: now, due_at: now + const Duration(days: 14).inMilliseconds,
    ));
    await db.operationsDao.updateLibraryBook(LibraryBook(
      id: fresh.id, title: fresh.title, author: fresh.author, isbn: fresh.isbn, category: fresh.category,
      total_copies: fresh.total_copies, available_copies: fresh.available_copies - 1, shelf_location: fresh.shelf_location, version: fresh.version + 1,
    ));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Issued successfully to $borrowerName (Due: ${DateFormat('dd MMM').format(DateTime.now().add(const Duration(days: 14)))})')));
    }
  }
}
