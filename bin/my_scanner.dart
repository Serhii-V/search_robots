import 'dart:async';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:my_scanner/models/news.dart';
import 'package:my_scanner/models/task.dart';

Future<void> main() async {
  ///Please select number of task
  final taskNumber = Task.firstTask;

  if (taskNumber == Task.firstTask) {
    await startFirstTaskParsingProcess('http://ccs.nau.edu.ua/', taskNumber);
  } else {
    await startSecondTaskParsingProcess('http://ccs.nau.edu.ua/', taskNumber);
    // await startSecondTaskParsingProcess('https://nau.edu.ua/', taskNumber);
  }
}

final requestedParameters = [
  'Артамонова Євгена Борисовича',
  'Артамонов Євген',
  'Артамонов Є.Б',
];

Future<void> startFirstTaskParsingProcess(String url, Task taskNumber) async {
  final mainPageResponse = await validateResponse(url);
  final newsUrl =
      mainPageResponse != null ? responseGetNewsLink(mainPageResponse) : null;
  if (newsUrl != null) {
    final allNews = await getAllNewsFromUrl(newsUrl, taskNumber);
    print('Загальна кількість новин ${allNews.length}');
  } else {
    print('check url');
  }
}

Future<void> startSecondTaskParsingProcess(String url, Task taskNumber) async {
  int counter = 1;
  final mainPageResponse = await validateResponse(url);
  final newsUrl =
      mainPageResponse != null ? responseGetNewsLink(mainPageResponse) : null;
  if (newsUrl != null) {
    final allNews = await getAllNewsFromUrl(newsUrl, taskNumber);
    final newsByParameters = allNews.where(
        (element) => element.ifNewsContainParameters(requestedParameters));
    for (var element in newsByParameters) {
      print('$counter ${element.title}');
      counter += 1;
    }
  } else {
    print('check url');
  }
}

Future<List<News>> getAllNewsFromUrl(String newsUrl, Task taskNumber) async {
  final List<String> linksOnAllPagesWithNews = [newsUrl];
  final firstNewsPageResponse = await validateResponse(newsUrl);
  if (firstNewsPageResponse != null) {
    final firstNewsPageDocument = parse(firstNewsPageResponse.body);
    final allPagesWithNewsLinks =
        getAllPagesWithNewsLinks(firstNewsPageDocument, taskNumber);
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

List<String> getAllPagesWithNewsLinks(dom.Document document, Task taskNumber) {
  if (taskNumber == Task.firstTask) {
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
  } else {
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
