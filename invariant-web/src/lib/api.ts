const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://16.171.151.222:3000';

export async function fetchNetworkStats() {
  try {
    // Parallel fetch for speed
    const [healthRes, leaderboardRes] = await Promise.all([
      fetch(`${API_URL}/health`, { next: { revalidate: 10 } }),
      fetch(`${API_URL}/leaderboard`, { next: { revalidate: 10 } })
    ]);

    const isHealthy = healthRes.status === 200;
    
    let activeAnchors = 0;
    let continuityHeight = 0;

    if (leaderboardRes.ok) {
      const data = await leaderboardRes.json();
      activeAnchors = data.length;
      // Sum of all scores = Total Network Continuity
      continuityHeight = data.reduce((acc: number, curr: any) => acc + (curr.score || 0), 0);
    }

    return {
      status: isHealthy ? 'HEALTHY' : 'DEGRADED',
      activeAnchors,
      continuityHeight
    };
  } catch (e) {
    console.error("Network Fetch Error:", e);
    // Graceful degradation so the site doesn't crash if backend is updating
    return {
      status: 'OFFLINE',
      activeAnchors: 20, // Fallback (e.g. Genesis set)
      continuityHeight: 104500
    };
  }
}