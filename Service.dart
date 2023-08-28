class Service {
  ServiceDelegate? delegate;

  void functionality() {
    this.delegate?.onFunctionality(this);
    print('Service functionality');
    this.delegate?.onDidFunctionality(this);
  }
}

abstract class ServiceDelegate {
  void onFunctionality(Service service) {}
  void onDidFunctionality(Service service) {}
}