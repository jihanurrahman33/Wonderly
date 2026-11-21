/// Collectable badges and the plain-language way to earn each one.
enum BadgeId {
  zoologyExplorer(
    title: 'Zoology Explorer',
    unlockHint: 'Finish an animal quiz',
    celebration: 'You finished your first animal quiz. Roar-some!',
  ),
  shapeStarter(
    title: 'Shape Starter',
    unlockHint: 'Finish the shapes lesson',
    celebration: 'You matched every shape. Nice work!',
  ),
  quickThinker(
    title: 'Quick Thinker',
    unlockHint: 'Get 5 answers right in a row',
    celebration: 'Five right answers in a row. Speedy brain!',
  ),
  plantPal(
    title: 'Plant Pal',
    unlockHint: 'Collect 30 stars',
    celebration: 'You collected 30 stars. Your garden is growing!',
  ),
  puzzlePro(
    title: 'Puzzle Pro',
    unlockHint: 'Finish the logic puzzles',
    celebration: 'You cracked every puzzle. Super solver!',
  ),
  weekWarrior(
    title: 'Week Warrior',
    unlockHint: 'Play 7 days in a row',
    celebration: 'Seven days in a row. What a streak!',
  );

  const BadgeId({
    required this.title,
    required this.unlockHint,
    required this.celebration,
  });

  final String title;
  final String unlockHint;
  final String celebration;

  static BadgeId? tryParse(String? name) {
    for (final b in BadgeId.values) {
      if (b.name == name) return b;
    }
    return null;
  }
}
