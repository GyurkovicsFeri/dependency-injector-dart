class BaseService {
  ServiceDelegate? delegate;

  void functionality() {
    delegate?.onFunctionality(this);
    print('Service functionality');
    delegate?.onDidFunctionality(this);
  }
}

abstract class ServiceDelegate {
  void onFunctionality(BaseService service) {}
  void onDidFunctionality(BaseService service) {}
}
