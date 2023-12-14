import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epub_viewer/epub_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Book> allBooks = [];
  List<Book> displayedBooks = [];
  Set<int> favoriteBooks = Set<int>();
  bool showFavorites = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
    loadFavorites();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.escribo.com/books.json'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          allBooks = List<Book>.from(data.map((json) => Book.fromJson(json)));
          updateDisplayedBooks();
        });
      } else {
        print('Failed to load books. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching books: $e');
    }
  }

  Future<void> loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedFavorites = prefs.getString('favorites');
    if (savedFavorites != null) {
      List<dynamic> favoritesList = jsonDecode(savedFavorites);
      setState(() {
        favoriteBooks = Set<int>.from(favoritesList.cast<int>());
        updateDisplayedBooks();
      });
    }
  }

  Future<void> saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String favoritesString = jsonEncode(favoriteBooks.toList());
    prefs.setString('favorites', favoritesString);
  }

  void toggleFavorite(int bookId) {
    setState(() {
      if (favoriteBooks.contains(bookId)) {
        favoriteBooks.remove(bookId);
      } else {
        favoriteBooks.add(bookId);
      }
      saveFavorites();
      updateDisplayedBooks();
    });
  }

  void updateDisplayedBooks() {
    if (showFavorites) {
      displayedBooks =
          allBooks.where((book) => favoriteBooks.contains(book.id)).toList();
    } else {
      displayedBooks = List.from(allBooks);
    }
    applySearchFilter();
  }

  void applySearchFilter() {
    String searchText = searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      displayedBooks = displayedBooks
          .where((book) =>
              book.title.toLowerCase().contains(searchText) ||
              book.author.toLowerCase().contains(searchText))
          .toList();
    }
  }

  Future<void> openEpub(String downloadUrl) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aguarde o carregamento do livro.'),
      ),
    );

    final http.Response response = await http.get(Uri.parse(downloadUrl));

    try {
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final ProgressDialog pr = new ProgressDialog(context);

        pr.style(message: 'Aguarde o carregamento...');
        // Obtenha o diretório de documentos para salvar o arquivo .epub
        final appDocumentsDirectory = await getApplicationDocumentsDirectory();
        pr.show;
        await pr.hide();
        final filePath = '${appDocumentsDirectory.path}/book.epub';

        // Salve o arquivo .epub localmente
        await File(filePath).writeAsBytes(bytes);

        // Abra o arquivo .epub usando a biblioteca epub_viewer
        EpubViewer.setConfig(
          themeColor: Theme.of(context).primaryColor,
          identifier: "androidBook",
          scrollDirection: EpubScrollDirection.HORIZONTAL,
          allowSharing: true,
          enableTts: true,
        );
        EpubViewer.open(filePath);
      } else {
        print('Falha ao baixar o arquivo. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao baixar o arquivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estante Virtual'),
        actions: [
          IconButton(
            icon: Icon(Icons.book),
            onPressed: () {
              setState(() {
                showFavorites = false;
                updateDisplayedBooks();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.star),
            onPressed: () {
              setState(() {
                showFavorites = true;
                updateDisplayedBooks();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Pesquisar',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    updateDisplayedBooks();
                  });
                },
              ),
            ),
            for (int index = 0; index < displayedBooks.length; index += 3)
              Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0;
                          i < 3 && index + i < displayedBooks.length;
                          i++)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    openEpub(
                                        displayedBooks[index + i].downloadUrl);
                                  },
                                  child: Image.network(
                                    displayedBooks[index + i].coverUrl,
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  displayedBooks[index + i].title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  displayedBooks[index + i].author,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10),
                                ),
                                SizedBox(height: 4.0),
                                IconButton(
                                  icon: Icon(
                                    favoriteBooks.contains(
                                            displayedBooks[index + i].id)
                                        ? Icons.star
                                        : Icons.star_border,
                                  ),
                                  onPressed: () {
                                    toggleFavorite(
                                        displayedBooks[index + i].id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Divider(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class Book {
  final int id;
  final String title;
  final String author;
  final String coverUrl;
  final String downloadUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.downloadUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['cover_url'],
      downloadUrl: json['download_url'],
    );
  }
}
