/// Protects the Flutter Web engine's unconditional URI decoding while keeping
/// a malformed UTF-8 fragment intact in the browser's final URL.
Uri galleryRouteUri(Uri uri) {
  try {
    Uri.decodeComponent(uri.fragment);
    return uri;
  } catch (_) {
    return uri.replace(fragment: Uri.encodeComponent(uri.fragment));
  }
}
