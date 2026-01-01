/// ENFORCES THE "OPERATOR PLAN" LOGIC
/// Total Duration: 14 Days
/// Cycle Duration: 4 Hours
/// Total Cycles: 84
class GenesisLogic {
  static const int totalDays = 14;
  static const int cyclesPerDay = 6; // 24h / 4h
  static const int totalCycles = totalDays * cyclesPerDay; // 84

  /// Returns the specific "Title" based on the tactical plan milestones.
  static String getTitle(int streak) {
    int days = (streak / cyclesPerDay).floor();

    if (days >= 14) return "GENESIS ANCHOR";
    if (days >= 10) return "GUARDIAN TIER"; // Day 10
    if (days >= 7) return "STABILITY TIER"; // Day 7
    if (days >= 3) return "PIONEER STATUS"; // Day 3
    
    return "INITIATE"; // Day 0-2
  }

  /// Returns the exact progress 0.0 -> 1.0
  static double getProgress(int streak) {
    return (streak / totalCycles).clamp(0.0, 1.0);
  }

  /// Returns remaining cycles for the Daily Brief
  static int getRemainingCycles(int streak) {
    return (totalCycles - streak).clamp(0, totalCycles);
  }

  /// Formats the Daily Brief text exactly as requested
  static String getDailyBriefBody(int streak, int totalNetworkNodes) {
    int day = (streak / cyclesPerDay).floor();
    int remaining = getRemainingCycles(streak);
    
    // "Day 9/14 complete. You are currently in the top 5% of global stability. 120 cycles remaining until Genesis."
    return "Day $day/$totalDays complete. Active Anchors: $totalNetworkNodes. $remaining cycles remaining until Genesis.";
  }
}