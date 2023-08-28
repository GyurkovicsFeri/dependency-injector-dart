import 'package:dependency_injector_dart/base_service.dart';
import 'package:dependency_injector_dart/composite_service_delegate.dart';
import 'package:dependency_injector_dart/dependency_container.dart';

DependencyContainer createContainer() {
  return DependencyContainer()
    ..scanForComponents()
    ..add((_) => "ChildDelegate1", tag: "ChildDelegatePrefix");
}

void main() {
  final dependencyContainer = createContainer();
  final service = dependencyContainer.get<BaseService>();
  service.functionality();
  final loggingDelegate = dependencyContainer.get<ChildDelegate1>();
  loggingDelegate.prefix = "Modified";
  service.functionality();
}

@Component(singleton: true, type: BaseService)
class MyService extends BaseService {
  MyService(@Inject(tag: "Composite") ServiceDelegate delegate) {
    this.delegate = delegate;
  }
}

@Component(singleton: true, type: ServiceDelegate, tag: "Composite")
class MyCompositeServiceDelegate extends CompositeServiceDelegate {
  MyCompositeServiceDelegate(@InjectArray<ServiceDelegate>(tag: "CompositeChild") List<ServiceDelegate> delegates) {
    addDelegates(delegates);
  }
}

@Component(singleton: true, type: ChildDelegate1, tag: "CompositeChild")
class ChildDelegate1 extends ServiceDelegate {
  String prefix;

  ChildDelegate1(@Inject(tag: "ChildDelegatePrefix") this.prefix);

  @override
  void onFunctionality(BaseService service) {
    print('$prefix: onFunctionality');
  }

  @override
  void onDidFunctionality(BaseService service) {
    print('$prefix: onDidFunctionality');
  }
}

@Component(singleton: true, type: ChildDelegate2, tag: "CompositeChild")
class ChildDelegate2 extends ServiceDelegate {
  @override
  void onFunctionality(BaseService service) {
    print('ChildDelegate2 onFunctionality');
  }

  @override
  void onDidFunctionality(BaseService service) {
    print('ChildDelegate2 onDidFunctionality');
  }
}
