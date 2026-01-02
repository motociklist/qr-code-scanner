class UrlHelper {
  static bool isUrl(String text) {
    return text.startsWith('http://') || text.startsWith('https://');
  }

  static String getShortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      String path = uri.path;
      if (path.length > 20) {
        path = '${path.substring(0, 17)}...';
      }
      return '$host$path';
    } catch (e) {
      if (url.length > 30) {
        return '${url.substring(0, 27)}...';
      }
      return url;
    }
  }

  static String truncateText(String text, {int maxLength = 30}) {
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength - 3)}...';
    }
    return text;
  }
}

