import 'package:flutter_test/flutter_test.dart';
import 'package:vision_attendance/services/face_match_evaluator.dart';

void main() {
  const evaluator = FaceMatchEvaluator(targetBytes: 1000, threshold: 0.7);

  test('returns failure for empty frame', () {
    const result = FaceMatchResult(isMatch: false, confidence: 0);
    expect(evaluator.evaluate(const FaceScanFrame(bytesLength: 0)).isMatch, result.isMatch);
    expect(evaluator.evaluate(const FaceScanFrame(bytesLength: 0)).confidence, result.confidence);
  });

  test('returns success when confidence exceeds threshold', () {
    final result = evaluator.evaluate(const FaceScanFrame(bytesLength: 1000));
    expect(result.isMatch, isTrue);
    expect(result.confidence, greaterThanOrEqualTo(0.7));
  });

  test('returns failure when confidence below threshold', () {
    final result = evaluator.evaluate(const FaceScanFrame(bytesLength: 200));
    expect(result.isMatch, isFalse);
    expect(result.confidence, lessThan(0.7));
  });
}
