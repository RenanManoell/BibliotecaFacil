Feito uma pequena coreção em um bug, quando apertava no livro fecha o app automaticamente.
Atualização feita dentro do build.gradle 

# BibliotecaFácil
BibliotecaFácil é um aplicativo simples de biblioteca virtual, onde os usuários podem explorar uma lista de livros, visualizar detalhes sobre cada livro, marcar seus favoritos e abrir os livros em formato EPUB para leitura. O aplicativo utiliza uma API JSON para obter informações sobre os livros.

## Funcionalidades
Listagem de Livros: Todos os livros disponíveis são listados, mostrando a capa, título e autor.
Pesquisa: Os usuários podem pesquisar livros por título ou autor para facilitar a busca.
Favoritos: Os usuários podem marcar livros como favoritos, e esses favoritos são persistidos localmente.
Visualização de Detalhes: Ao clicar em um livro, é possível visualizar detalhes adicionais e abrir o livro para leitura em formato EPUB.

## Como Instalar e Rodar
1. Metodo um: Você baixa o APK e instala no seu android.
2. Metodo um: Siga as instruções abaixo para instalar e rodar o aplicativo em seu ambiente de desenvolvimento local:

**Pré-requisitos:**

Certifique-se de ter o Flutter e o Dart instalados em seu sistema. Caso contrário, siga as instruções de instalação do Flutter. (https://flutter.dev/)

1. **Clone o Repositório:**
  
        git clone https://github.com/RenanManoell/BibliotecaFacil.git
        cd BibliotecaFacil

2. **Instale as Dependências:**

        flutter pub get
3. **Execute o Aplicativo:**

        flutter run
Certifique-se de ter um emulador Android ou um dispositivo conectado para visualizar o aplicativo.

4. **Explore a Biblioteca:**

- Navegue pela lista de livros, pesquise por títulos ou autores e marque seus favoritos.
- Clique em um livro para ver detalhes adicionais e abrir o livro para leitura.
# Notas Adicionais
- O aplicativo utiliza uma API JSON fornecida pelo site https://www.escribo.com/books.json para obter informações sobre os livros.
- A persistência dos livros marcados como favoritos é realizada localmente utilizando o pacote shared_preferences.
- A leitura dos livros em formato EPUB é possível graças ao pacote epub_viewer.
# Observação:
- Certifique-se de ter uma conexão com a internet durante a primeira execução do aplicativo para carregar os livros da API.

# Divirta-se explorando sua BibliotecaFácil! 📚
