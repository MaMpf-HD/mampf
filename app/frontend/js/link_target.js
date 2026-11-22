/**
 * Returns the given URL if a link may lead there, and null otherwise.
 *
 * A link leads to an http(s) URL or to a path within MaMpf. The URL is parsed
 * the way the browser parses it when following the link, so that both agree
 * on its scheme.
 */
export function linkTarget(url) {
  if (!url) {
    return null;
  }
  try {
    const { protocol } = new URL(url, window.location.origin);
    return ["http:", "https:"].includes(protocol) ? url : null;
  }
  catch {
    return null;
  }
}
