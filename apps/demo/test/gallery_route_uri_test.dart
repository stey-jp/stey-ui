import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/gallery_route_uri.dart';

void main() {
  test('Normal fragments and all route parameters are retained', () {
    for (final hash in ['overview', 'caf%C3%A9', '50%-off', '%', '%ZZ']) {
      final uri = Uri.parse('/?component=table-of-contents&mode=dark#$hash');
      expect(galleryRouteUri(uri), uri);
    }
  });

  test('Engine decoding preserves invalid UTF-8 hashes without throwing', () {
    for (final hash in ['%FF', '%C0%AF', '%E0%A4%A']) {
      final uri = Uri.parse('/?component=table-of-contents&mode=dark#$hash');
      final safe = galleryRouteUri(uri);
      // Mirrors the documented engine boundary, checking the final browser
      // route rather than requiring a particular internal escape sequence.
      expect(Uri.decodeComponent(safe.toString()), uri.toString());
      expect(safe.queryParameters, uri.queryParameters);
    }
  });
}
