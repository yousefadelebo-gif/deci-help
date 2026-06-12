/// Result type for handling success/failure cases
/// Following the Either pattern from functional programming
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => isSuccess ? (this as Success<T>).value : null;
  String? get error => isFailure ? (this as Failure<T>).message : null;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(String message) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failure<T>).message);
    }
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}
