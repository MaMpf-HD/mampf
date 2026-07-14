import { expect, test } from "./_support/fixtures";

/**
 * The GeoGebra page pulls its script in as a Vite entrypoint. While that
 * entrypoint was a `.coffee` file, the production build copied it verbatim
 * instead of transpiling it, and the static server answered with `text/plain` —
 * which a browser refuses for a module script, so the applet never loaded.
 * Development was fine, because the Vite dev server transpiles on the fly.
 *
 * The extension check therefore catches the regression everywhere, while the
 * content-type check additionally covers the built assets used in CI.
 */
test("geogebra page serves its module script as javascript",
  async ({ factory, teacher: { page, user } }) => {
    const moduleScriptErrors: string[] = [];
    page.on("console", (message) => {
      if (message.type() === "error" && /module script/i.test(message.text())) {
        moduleScriptErrors.push(message.text());
      }
    });

    const lecture = await factory.create("lecture", ["released_for_all"],
      { teacher_id: user.id });
    const medium = await factory.create("lecture_medium",
      ["with_lecture_by_id", "with_geogebra"], { lecture_id: lecture.id });

    await page.goto(`/media/${medium.id}/geogebra`);

    // The CDN's deployggb.js also carries "geogebra" in its URL, but it is not a
    // module script — hence the type filter.
    const src = await page
      .locator("script[type=\"module\"][src*=\"geogebra\"]")
      .getAttribute("src");

    if (src === null) {
      throw new Error("the geogebra page carries no module script");
    }

    expect(src).not.toMatch(/\.coffee(\?|$)/);

    const response = await page.request.get(src);
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"]).toMatch(/javascript/);

    expect(moduleScriptErrors).toEqual([]);
  });
