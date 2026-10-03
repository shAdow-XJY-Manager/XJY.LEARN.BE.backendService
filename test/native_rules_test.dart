import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:backend_service/server/server.dart';
import 'package:backend_service/server/routers/novel_routes.dart';

void main() {
  test('configured novel routes return actual route parameters and JSON', () async {
    final router = createNovelRouter();
    final list = await router(Request('GET', Uri.parse('http://localhost/getNovels')));
    expect(list.statusCode, 200);
    expect(list.headers['content-type'], 'application/json');
    expect(jsonDecode(await list.readAsString()), {'novels': ['Novel 1', 'Novel 2']});
    final detail = await router(Request('GET', Uri.parse('http://localhost/getNovel/42')));
    expect(jsonDecode(await detail.readAsString()), {'id': '42', 'name': 'Novel 42'});
    final chapter = await router(Request('GET', Uri.parse('http://localhost/getChapter&novel=42&chapter=7')));
    expect(chapter.statusCode, 200);
    expect(jsonDecode(await chapter.readAsString()), {
      'novelId': '42', 'chapterId': '7', 'content': 'Content of chapter 7 from novel 42',
    });
    expect((await router(Request('GET', Uri.parse('http://localhost/missing')))).statusCode, 404);
    expect(BSNovelAPIConfig().getApiPath(BSNovelAPIConfig.getNovels), '/api/novel/getNovels');
  });

  test('novel POST preserves its JSON payload and middleware contains malformed JSON errors', () async {
    final handler = createErrorHandlingMiddleware()(createNovelRouter().call);
    final body = {'name': '中文小说', 'chapters': ['第一章', '第二章']};
    final response = await handler(Request('POST', Uri.parse('http://localhost/novel/add'), body: jsonEncode(body)));
    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), {
      'message': 'Novel added successfully', 'novel': body,
    });
    final invalid = await handler(Request('POST', Uri.parse('http://localhost/novel/add'), body: '{bad'));
    expect(invalid.statusCode, 500);
    expect(invalid.headers['content-type'], 'application/json');
    final error = jsonDecode(await invalid.readAsString()) as Map;
    expect(error['error'], 'An unexpected error occurred.');
    expect(error['message'], contains('FormatException'));
  });
}
