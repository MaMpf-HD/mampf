const POSITION_ID = "loginViewTransitionClick";

/**
 * Animates a circular reveal on page load based on the stored click position.
 *
 * Adapted from:
 * https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API/Using#a_javascript-powered_custom_same-document_spa_transition
 * and https://developer.chrome.com/docs/web-platform/view-transitions/cross-document
 */
window.addEventListener("pagereveal", async (e) => {
  if (!navigation.activation.from) return;
  if (!e.viewTransition) return;

  let x = window.innerWidth / 2;
  let y = window.innerHeight / 2;
  const stored = sessionStorage.getItem(POSITION_ID);
  if (stored) {
    const pos = JSON.parse(stored);
    if (typeof pos.x === "number" && typeof pos.y === "number") {
      if (pos.x !== 0 && pos.y !== 0) {
        x = pos.x;
        y = pos.y;
      }
    }
    sessionStorage.removeItem(POSITION_ID);
  }

  // furthest corner
  const endRadius = Math.hypot(
    Math.max(x, window.innerWidth - x),
    Math.max(y, window.innerHeight - y),
  );

  await e.viewTransition.ready;

  document.documentElement.animate(
    {
      clipPath: [
          `circle(0 at ${x}px ${y}px)`,
          `circle(${endRadius}px at ${x}px ${y}px)`,
      ],
    },
    {
      duration: 500,
      easing: "ease-in",
      pseudoElement: "::view-transition-new(root)",
    },
  );
});
