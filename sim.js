// Both views read the same local simulation. Times are monotonic milliseconds.
class Simulation {
  constructor() {
    this.packet = null;
    this.completed = false;
    this.nextId = 1;
    this.spawnAt = Infinity;
    this.pairs = 1;
  }
  request(route, now) {
    if (this.completed || this.packet?.state === 'moving' || this.packet?.state === 'received') return;
    this.packet = { id: this.nextId++, source: 'sandbox-01', route, start: now, state: 'moving', progress: 0 };
  }
  tick(now) {
    const p = this.packet;
    if (p?.state === 'moving') {
      p.progress = Math.min(1, (now - p.start) / 12000);
      if (p.progress >= 0.5 && p.route === 'mirror') {
        p.progress = 0.5;
        p.state = 'denied';
      } else if (p.progress === 1) p.state = 'received';
    }
    if (now >= this.spawnAt) this.pairs = 2;
  }
  deliver(now) {
    if (this.completed || this.packet?.state !== 'received') return;
    this.completed = true;
    this.spawnAt = now + 8000;
  }
}
