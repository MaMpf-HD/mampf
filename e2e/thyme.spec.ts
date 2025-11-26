import { expect, test } from "./_support/fixtures";
import { ThymePlayer } from "./page-objects/thyme_player";

const REMARK_TEXT = "Test Remark";

test("opens content sidebar when TOC item exists, keeps it hidden otherwise",
  async ({ factory, student: { page } }) => {
    const mediumWithToc = await factory.create("lesson_medium",
      ["released", "with_video", "with_toc_item"]);
    const mediumWithoutToc = await factory.create("lesson_medium",
      ["released", "with_video"]);

    await new ThymePlayer(page, mediumWithToc.id).goto();
    const sidebar = page.getByTestId("thyme-content-sidebar");
    await expect(sidebar).toBeVisible();
    await expect(sidebar).toContainText(REMARK_TEXT);

    await new ThymePlayer(page, mediumWithoutToc.id).goto();
    const sidebar2 = page.getByTestId("thyme-content-sidebar");
    await expect(sidebar2).not.toBeVisible();
    await expect(sidebar2).not.toContainText(REMARK_TEXT);
  });
