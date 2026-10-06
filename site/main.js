// Reparc site: particle burst for the hero mark and scroll reveals.
// No trackers, no network calls. Everything respects reduced motion.
(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduce) return;
  document.documentElement.classList.add("js-motion");

  // Burst of "rep" particles when the leg lands (CSS times the start).
  const burst = document.querySelector(".burst");
  if (burst) {
    const size = burst.parentElement.getBoundingClientRect().width;
    for (let i = 0; i < 28; i++) {
      const a = (i * 137.508 * Math.PI) / 180;
      const d = size * (0.22 + (i % 5) * 0.045);
      const s = document.createElement("span");
      s.style.setProperty("--x", `${Math.cos(a) * d}px`);
      s.style.setProperty("--y", `${Math.sin(a) * d}px`);
      burst.appendChild(s);
    }
  }

  const io = new IntersectionObserver(
    (entries) => {
      for (const e of entries) {
        if (e.isIntersecting) {
          e.target.classList.add("in");
          io.unobserve(e.target);
        }
      }
    },
    { threshold: 0.15 },
  );
  document.querySelectorAll(".reveal").forEach((el, i) => {
    el.style.transitionDelay = `${(i % 3) * 80}ms`;
    io.observe(el);
  });
})();
