import 'package:dependency_injector_dart/iterable_extension.dart';

class DependencyContainer {
  List<DependecyInjector> dependencyInjectors = [];

  void add<T>(DependencyCallback<T> callback, {Type? type, String? tag}) {
    addDependencyInjector(SimpleDependencyInjector<T>(callback, tag: type, stringTag: tag));
  }

  void addSingleton<T>(DependencyCallback<T> callback, {Type? type, String? tag}) {
    addDependencyInjector(SingletonDependencyInjector<T>(callback, type: type, tag: tag));
  }

  void addDependencyInjector<T>(DependecyInjector<T> dependencyInjector) {
    dependencyInjectors.add(dependencyInjector);
  }

  T get<T>({Type? type, String? tag}) {
    final injector = dependencyInjectors.firstWhereOrNull(
        (dependencyInjector) => dependencyInjector.type == (type ?? T) && tag == null || dependencyInjector.tag == tag);
    if (injector == null) throw Exception('Dependency not found: $T ($type, $tag)');
    return injector.createInstance(this) as T;
  }

  List<T> getList<T>({Type? type, String? tag}) {
    final injectors = dependencyInjectors.where(
        (dependencyInjector) => dependencyInjector.type == (type ?? T) && tag == null || dependencyInjector.tag == tag);
    if (injectors.isEmpty) throw Exception('Dependency not found: $T ($type, $tag)');
    return injectors.map((e) => e.createInstance(this) as T).toList();
  }
}

abstract class DependecyInjector<T> {
  late Type type;
  late String tag;
  T createInstance(DependencyContainer dependencyContainer);
}

typedef DependencyCallback<T> = T Function(DependencyContainer dependencyContainer);

class SimpleDependencyInjector<T> implements DependecyInjector<T> {
  @override
  late Type type;
  @override
  late String tag;
  DependencyCallback<T> callback;

  SimpleDependencyInjector(this.callback, {Type? tag, String? stringTag}) {
    this.type = tag ?? T;
    this.tag = stringTag ?? '';
  }

  @override
  T createInstance(DependencyContainer dependencyContainer) {
    return this.callback(dependencyContainer);
  }
}

class SingletonDependencyInjector<T> implements DependecyInjector<T> {
  @override
  late Type type;
  @override
  late String tag;
  T? instance;
  DependencyCallback<T> callback;

  SingletonDependencyInjector(this.callback, {Type? type, String? tag}) {
    this.type = type ?? T;
    this.tag = tag ?? '';
  }

  @override
  T createInstance(DependencyContainer dependencyContainer) {
    if (this.instance == null) {
      this.instance = this.callback(dependencyContainer);
    }
    return this.instance!;
  }
}
