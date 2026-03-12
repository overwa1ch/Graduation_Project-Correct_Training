abstract interface class TransactionalResource {
  Object snapshot();
  void restore(Object snapshot);
}
