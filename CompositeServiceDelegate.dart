
import 'Service.dart';

class CompositeServiceDelegate with CompositeDelegate<ServiceDelegate> implements ServiceDelegate {
  @override
  void onFunctionality(Service service) {
    call((delegate) => delegate.onFunctionality(service));
  }

  @override
  void onDidFunctionality(Service service) {
    call((delegate) => delegate.onDidFunctionality(service));
  }
}


mixin CompositeDelegate<T> {
  List<T> delegates = [];

  void addDelegates(Iterable<T> delegates) {
    this.delegates.addAll(delegates);
  }

  void addDelegate(T delegate) {
    this.delegates.add(delegate);
  }

  void remove(T delegate) {
    this.delegates.remove(delegate);
  }

  void call(Function(T) function) {
    for (T delegate in this.delegates) {
      function(delegate);
    }
  }
}