/**
 * Animates a fade & reveal effect.
 *
 * Further ressources:
 * - https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API/Using
 * - https://developer.chrome.com/docs/web-platform/view-transitions/cross-document
 * - https://view-transitions.chrome.dev/
 */
window.addEventListener("pagereveal", async (e) => {
  if (!navigation.activation.from) return;
  if (!e.viewTransition) return;

  await e.viewTransition.ready;

  const duration = 700;
  const easing = "cubic-bezier(0.4,0,0.2,1)";

  document.documentElement.animate(
    {
      filter: ["none", "blur(8px)"],
      opacity: [1, 0.3],
      transform: ["scale(1)", "scale(1.07)"],
    },
    {
      duration,
      easing,
      pseudoElement: "::view-transition-old(root)",
    },
  );

  document.documentElement.animate(
    {
      filter: ["blur(8px)", "none"],
      opacity: [0.3, 1],
      transform: ["scale(0.93)", "scale(1)"],
    },
    {
      duration,
      easing,
      pseudoElement: "::view-transition-new(root)",
    },
  );
});
