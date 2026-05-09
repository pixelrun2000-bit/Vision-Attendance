class FaceScanFrame {
  final int bytesLength;

  const FaceScanFrame({required this.bytesLength});
}

class FaceMatchResult {
  final bool isMatch;
  final double confidence;

  const FaceMatchResult({required this.isMatch, required this.confidence});
}

class FaceMatchEvaluator {
  final int targetBytes;
  final double threshold;

  const FaceMatchEvaluator({
    this.targetBytes = 200000,
    this.threshold = 0.72,
  });

  FaceMatchResult evaluate(FaceScanFrame frame) {
    if (frame.bytesLength <= 0) {
      return const FaceMatchResult(isMatch: false, confidence: 0);
    }

    final normalized = (frame.bytesLength / targetBytes).clamp(0.0, 1.2);
    final confidence = (normalized / 1.2).clamp(0.0, 1.0).toDouble();
    return FaceMatchResult(isMatch: confidence >= threshold, confidence: confidence);
  }
}
