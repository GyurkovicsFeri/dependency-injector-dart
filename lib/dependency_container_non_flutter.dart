import 'dart:mirrors';

import 'package:dependency_injector_dart/dependency_container.dart';
import 'package:dependency_injector_dart/iterable_extension.dart';

extension Mirrors on DependencyContainer {
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
