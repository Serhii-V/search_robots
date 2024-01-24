import 'dart:async';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:my_scanner/models/news.dart';

Future<void> main() async {
  await startParsingProcess('http://ccs.nau.edu.ua/');
}

final requestedParameters = [
  'Артамонова Євгена Борисовича',
  'Артамонов Євген',
  'Артамонов Є.Б',
];

Future<void> startParsingProcess(String url) async {
  final mainPageResponse = await validateResponse(url);
  final newsUrl =
      mainPageResponse != null ? responseGetNewsLink(mainPageResponse) : null;
  if (newsUrl != null) {
    final allNews = await getAllNewsFromUrl(newsUrl);
    final newsByParameters = allNews.where((element) => element.ifNewsContainParameters(requestedParameters));
    for (var element in newsByParameters) {
      print(element.title);
    }
  } else {
    print('check url');
  }
}

Future<List<News>> getAllNewsFromUrl(String newsUrl) async {
  final List<String> linksOnAllPagesWithNews = [newsUrl];
  final firstNewsPageResponse = await validateResponse(newsUrl);
  if (firstNewsPageResponse != null) {
    final firstNewsPageDocument = parse(firstNewsPageResponse.body);
    final allPagesWithNewsLinks =
        getAllPagesWithNewsLinks(firstNewsPageDocument);
    linksOnAllPagesWithNews.addAll(allPagesWithNewsLinks);
  }
  return getAllNewsFromNewsLinks(linksOnAllPagesWithNews);
}

Future<List<News>> getAllNewsFromNewsLinks(List<String> newsUrl) async {
  final List<String> articlesLinks = [];
  for (final link in newsUrl) {
    final responseFromPageWithNews = await validateResponse(link);
    if (responseFromPageWithNews != null) {
      final documentFromPageWithNews =
          getDocumentFromResponse(responseFromPageWithNews);
      articlesLinks.addAll(getAllLinksFromArticles(documentFromPageWithNews));
    }
  }
  return getNewsFromArticleLinks(articlesLinks);
}

Future<List<News>> getNewsFromArticleLinks(List<String> allNewsLinks) async {
  final List<News> allNews = [];
  if (allNewsLinks.isNotEmpty) {
    for (final newLink in allNewsLinks) {
      final resp = await validateResponse(newLink);
      if (resp != null) {
        final doc = getDocumentFromResponse(resp);
        allNews.add(News(getNewsTitle(doc) ?? '', getEntryContent(doc) ?? ''));
      }
    }
  }
  return allNews;
}

dom.Document getDocumentFromResponse(http.Response response) {
  return parse(response.body);
}

List<String> getAllPagesWithNewsLinks(dom.Document document) {
  final links = <String>[];
  final classPagination = document.getElementsByClassName('pagination');
  final elements = classPagination.first.querySelectorAll('a');
  for (final element in elements) {
    final href = element.attributes['href'];
    if (href != null && href.isNotEmpty) {
      links.add(href);
    }
  }
  return links.toSet().toList();
}

List<String> getAllLinksFromArticles(dom.Document document) {
  final links = <String>[];
  final classPagination = document.getElementsByClassName('entry-title');
  final elements = [];
  for (var element in classPagination) {
    elements.addAll(element.querySelectorAll('a'));
  }

  for (final element in elements) {
    final href = element.attributes['href'];
    if (href != null && href.isNotEmpty) {
      links.add(href);
    }
  }
  return links;
}

String? getNewsTitle(dom.Document document) {
  String result = '';
  document.getElementsByClassName('trail-end').forEach((element) {
    result += ' ${element.text}';
  });

  return result;
}

Future<http.Response?> validateResponse(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('Request successful!');
      return response;
    } else {
      print('An error occurred while executing the request.');
      return null;
    }
  } catch (e) {
    print('response failure: $e');
    return null;
  }
}

String? getEntryContent(dom.Document document) {
  String result = '';
  document.getElementsByClassName('entry-content').forEach((element) {
    result += ' ${element.text}';
  });
  return result;
}

String? responseGetNewsLink(http.Response response) {
  final document = parse(response.body);
  final links = document.getElementsByTagName('a').toList();
  for (var element in links) {
    if (element.text == 'Новини') {
      return element.attributes['href'];
    }
  }
  return null;
}
