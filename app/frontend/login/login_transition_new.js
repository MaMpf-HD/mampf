/**
 * Animates a circular reveal on page load (starting from the center of the screen).
 *
 * Adapted from:
 * https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API/Using#a_javascript-powered_custom_same-document_spa_transition
 * and https://developer.chrome.com/docs/web-platform/view-transitions/cross-document
 *
 * See more examples here:
 * https://view-transitions.chrome.dev/
 */
window.addEventListener("pagereveal", async (e) => {
  if (!navigation.activation.from) return;
  if (!e.viewTransition) return;

  let x = window.innerWidth / 2;
  let y = window.innerHeight / 2;

  // distance to farthest corner
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
