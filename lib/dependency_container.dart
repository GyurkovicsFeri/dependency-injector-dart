import 'dart:mirrors';

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

  void addClass(Type clazz) {
    reflectClass(clazz).metadata.forEach((metadata) {
      if (metadata.reflectee is Component) {
        Component component = metadata.reflectee as Component;
        component.register(this, clazz);
      }
    });
  }

  void addClasses(List<Type> classes) {
    for (Type clazz in classes) {
      addClass(clazz);
    }
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

  void scanForComponents() {
    MirrorSystem mirrorSystem = currentMirrorSystem();
    mirrorSystem.libraries.forEach((lk, l) {
      l.declarations.forEach((dk, d) {
        if (d is ClassMirror) {
          ClassMirror cm = d;
          for (var md in cm.metadata) {
            InstanceMirror metadata = md;
            if (metadata.type == reflectClass(Component)) {
              addClass(cm.reflectedType);
            }
          }
        }
      });
    });
  }
}

class Component {
  final bool singleton;
  final Type? type;
  final String? tag;

  const Component({this.singleton = false, this.type, this.tag});

  register(DependencyContainer dependencyContainer, Type clazz) {
    final reflectedClazz = reflectClass(clazz);
    final emptyConstructor = reflectedClazz.declarations[reflectedClazz.simpleName];
    if (emptyConstructor == null || emptyConstructor is! MethodMirror) {
      throw Exception('Class $clazz has no empty constructor');
    }

    final constructorParameterTypes = emptyConstructor.parameters.toList();
    if (singleton) {
      dependencyContainer.addSingleton((c) => newInstance(c, reflectedClazz, constructorParameterTypes),
          type: type ?? clazz, tag: tag);
    } else {
      dependencyContainer.add((c) => newInstance(c, reflectedClazz, constructorParameterTypes),
          type: type ?? clazz, tag: tag);
    }
  }

  dynamic newInstance(
      DependencyContainer c, ClassMirror reflectedClazz, List<ParameterMirror> constructorParameterTypes) {
    final parameters = constructorParameterTypes.map((e) => getParameter(c, e)).toList();
    return reflectedClazz.newInstance(Symbol.empty, parameters).reflectee;
  }

  dynamic getParameter(DependencyContainer c, ParameterMirror e) {
    final injectArray =
        e.metadata.firstWhereOrNull((element) => element.reflectee is InjectArray)?.reflectee as InjectArray?;
    if (injectArray != null) {
      return injectArray.get(c);
    }

    final inject = e.metadata.firstWhereOrNull((element) => element.reflectee is Inject)?.reflectee as Inject?;
    return c.get(type: e.type.reflectedType, tag: inject?.tag);
  }
}

class Inject {
  final String tag;

  const Inject({required this.tag});
}

class InjectArray<T> {
  final String tag;

  const InjectArray({required this.tag});

  List<T> get(DependencyContainer c) {
    return c.getList(tag: this.tag);
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
