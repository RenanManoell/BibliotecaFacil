import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epub_viewer/epub_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
// todas importações nescessarias.

void main() {
  runApp(MyApp());
  //inicio para start do app
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      //metodo para inicar a homepage
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Book> allBooks = [];
  List<Book> displayedBooks = [];
  Set<int> favoriteBooks = Set<int>();
  bool showFavorites = false;
  TextEditingController searchController = TextEditingController();
  bool favoritesLoaded = false;
  //inicializações nescessarias, exemplo: como mostrar todos e não somente favoritos

  @override
  void initState() {
    super.initState();
    fetchBooks();
    loadFavorites();
  }

  Future<void> fetchBooks() async {
    //carrega a API json do site
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
        //tratativas de erros
        print('Failed to load books. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching books: $e');
    }
  }

  Future<void> loadFavorites() async {
    //carregamento inicial dos favoritos com base noque o usuario colocou anteriormente antes de fechar o app
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedFavorites = prefs.getString('favorites');
    if (savedFavorites != null) {
      List<dynamic> favoritesList = jsonDecode(savedFavorites);
      setState(() {
        favoriteBooks = Set<int>.from(favoritesList.cast<int>());
        updateDisplayedBooks();
        favoritesLoaded = true;
      });
    } else {
      setState(() {
        favoritesLoaded = true;
      });
    }
  }

  Future<void> saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String favoritesString = jsonEncode(favoriteBooks.toList());
    prefs.setString('favorites', favoritesString);
  }

  void toggleFavorite(int bookId) {
    //salva os favoritos
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
    //recarrega e deixa somente os favoritos
    if (showFavorites) {
      displayedBooks =
          allBooks.where((book) => favoriteBooks.contains(book.id)).toList();
    } else {
      displayedBooks = List.from(allBooks);
    }
    applySearchFilter();
  }

  void applySearchFilter() {
    //função para pesquisar nome ou autor do livro
    String searchText = searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      displayedBooks = displayedBooks
          .where((book) =>
              book.title.toLowerCase().contains(searchText) ||
              book.author.toLowerCase().contains(searchText))
          .toList();
    }
  }

  Future<void> openEpub(String downloadUrl, int bookId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Aguarde o carregamento do livro, a velocidade vai depender da sua internet.'),
        ),
      );

      final http.Response response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final appDocumentsDirectory = await getApplicationDocumentsDirectory();
        final filePath = '${appDocumentsDirectory.path}/book_$bookId.epub';

        EpubViewer.setConfig(
          themeColor: Theme.of(context).primaryColor,
          identifier:
              "book_$bookId", // Use um identificador único para cada livro
          scrollDirection: EpubScrollDirection.HORIZONTAL,
          allowSharing: true,
          enableTts: true,
        );

        await File(filePath).writeAsBytes(response.bodyBytes);

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
    ProgressDialog pr = ProgressDialog(context);

    if (!favoritesLoaded) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      //começo de todo layout
      appBar: AppBar(
        title: Text('BibliotecaFácil'),
        actions: [
          IconButton(
            //icone que mostra todos os livros ao clicar
            icon: Icon(Icons.bookmarks),
            onPressed: () {
              setState(() {
                showFavorites = false;
                updateDisplayedBooks();
              });
            },
          ),
          IconButton(
            //mostra todos livros que foram favoritados.
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
                //campo para pesquisar nome do livro e autor
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
                      //for para listar todos os livros da API
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
                                  //ao clicar na imagem ele abre o livro.
                                  onTap: () {
                                    openEpub(
                                      displayedBooks[index + i].downloadUrl,
                                      displayedBooks[index + i].id,
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Image.network(
                                        //imagem do livro
                                        displayedBooks[index + i].coverUrl,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.fill,
                                      ),
                                      Positioned(
                                        //icone da filipeta do livro
                                        top: -20,
                                        right: -20,
                                        child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconButton(
                                              icon: Icon(
                                                favoriteBooks.contains(
                                                        displayedBooks[
                                                                index + i]
                                                            .id)
                                                    ? Icons.bookmark_rounded
                                                    : Icons.bookmark_border,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                toggleFavorite(
                                                    displayedBooks[index + i]
                                                        .id);
                                              },
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  //titulo do livro
                                  displayedBooks[index + i].title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  //autor do livro
                                  displayedBooks[index + i].author,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10),
                                ),
                                SizedBox(height: 4.0),
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
  //book que defini o tipo de dados do json
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
