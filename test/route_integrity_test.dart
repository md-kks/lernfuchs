import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lernfuchs/app/router.dart';

void main() {
  test('app shell routes preserve dashboard-first navigation', () {
    final paths = _flattenRoutes(appRouter.configuration.routes).toSet();

    expect(paths, contains('/home'));
    expect(paths, contains('/home/freies-ueben'));
    expect(paths, contains('/home/baumhaus'));
    expect(paths, isNot(contains('/home/weltkarte')));
    expect(paths, contains('/home/tagespfad'));
    expect(paths, contains('/home/elternbereich'));
    expect(paths, contains('/home/subject/:grade/:subject'));
    expect(paths, contains('/home/subject/:grade/:subject/exercise/:topic'));
    expect(paths, contains('/parent'));
  });
}

List<String> _flattenRoutes(List<RouteBase> routes, [String parentPath = '']) {
  final paths = <String>[];

  for (final route in routes) {
    if (route is GoRoute) {
      final fullPath = _joinPaths(parentPath, route.path);
      paths.add(fullPath);
      paths.addAll(_flattenRoutes(route.routes, fullPath));
    }
  }

  return paths;
}

String _joinPaths(String parentPath, String routePath) {
  if (routePath.startsWith('/')) return routePath;
  if (parentPath == '/' || parentPath.isEmpty) return '/$routePath';
  return '$parentPath/$routePath';
}
