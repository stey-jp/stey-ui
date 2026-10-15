import 'package:flutter_web_plugins/url_strategy.dart';

void configureNavigation() =>
    setUrlStrategy(PathUrlStrategy(BrowserPlatformLocation(), true));
