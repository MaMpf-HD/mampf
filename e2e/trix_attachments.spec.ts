import { expect, test } from "./_support/fixtures";

interface TrixElement extends HTMLElement {
  editor: {
    insertFile: (_file: File) => void;
    getDocument: () => { getAttachments: () => unknown[] };
  };
}

// The editors that Action Text did not wire cannot store a file, so they must
// not offer one either.
test("a plain Trix editor neither shows nor accepts an attachment",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id, locale: "en" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Kaviar" });

    await page.goto(`/media/${medium.id}/edit`);
    await expect(page.locator("#medium-content-trix")).toBeVisible();

    await expect(page.locator("trix-toolbar [data-trix-button-group='file-tools']"))
      .toHaveCount(0);

    const attached = await page.evaluate(() => {
      const trix = document.querySelector<TrixElement>("#medium-content-trix");
      if (!trix) return -1;

      trix.editor.insertFile(new File([new Uint8Array([1, 2, 3])], "probe.png",
        { type: "image/png" }));
      return trix.editor.getDocument().getAttachments().length;
    });

    expect(attached).toBe(0);
  });

test("an editor Action Text wired keeps taking files",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id, locale: "en" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Kaviar" });

    await page.goto(`/media/${medium.id}/edit`);

    const refused = await page.evaluate(() => {
      const trix = document.querySelector<HTMLElement>("#medium-content-trix");
      if (!trix) return null;

      const ask = () => {
        const event = new CustomEvent("trix-file-accept", { bubbles: true, cancelable: true });
        trix.dispatchEvent(event);
        return event.defaultPrevented;
      };
      const withoutUrl = ask();
      trix.dataset.directUploadUrl = "/rails/active_storage/direct_uploads";

      return { withoutUrl, withUrl: ask() };
    });

    expect(refused).toEqual({ withoutUrl: true, withUrl: false });
  });
