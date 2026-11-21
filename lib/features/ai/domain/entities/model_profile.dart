/// On-device language models a grown-up can choose between.
///
/// Both are open-licence (Apache 2.0) LiteRT-LM builds that need no account or
/// access token, so they download without any sign-in.
enum ModelProfile {
  balanced(
    title: 'Balanced',
    model: 'Qwen 2.5 1.5B',
    description: 'Good quality and fits most phones.',
    sizeLabel: '1.6 GB',
    sizeBytes: 1597922856,
    minRamGb: 4,
  ),
  quality(
    title: 'Best quality',
    model: 'Gemma 4 E2B',
    description: 'Sharper questions. Needs a newer phone with more memory.',
    sizeLabel: '2.6 GB',
    sizeBytes: 2588147712,
    minRamGb: 6,
  );

  const ModelProfile({
    required this.title,
    required this.model,
    required this.description,
    required this.sizeLabel,
    required this.sizeBytes,
    required this.minRamGb,
  });

  final String title;
  final String model;
  final String description;
  final String sizeLabel;
  final int sizeBytes;

  /// Rough memory a phone needs to run the model comfortably.
  final int minRamGb;

  static ModelProfile fromName(String? name) => ModelProfile.values.firstWhere(
    (p) => p.name == name,
    orElse: () => ModelProfile.balanced,
  );
}
