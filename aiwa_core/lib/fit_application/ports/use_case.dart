/// UseCase 统一接口（Spec §3.1）
///
/// * I = Input（immutable 参数对象）
/// * O = Output（DTO 或 void）
abstract interface class UseCase<I, O> {
  Future<O> execute(I input);
}
