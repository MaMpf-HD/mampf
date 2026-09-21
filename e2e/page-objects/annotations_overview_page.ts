import { Locator, Page } from "../_support/fixtures";

/**
 * The overview of annotations: one's own, and for editors and teachers those
 * students shared, each as an accordion with a panel per lecture. A card is a
 * link that opens the player in a new tab.
 */
export class AnnotationsOverviewPage {
  readonly page: Page;
  readonly link = "/annotations";

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  get ownAnnotations(): Locator {
    return this.page.getByRole("region", { name: "Your annotations" });
  }

  get studentsAnnotations(): Locator {
    return this.page.getByRole("region", { name: "Students annotations" });
  }

  /** The accordion headers of a section, in the order they are shown. */
  lectures(section: Locator): Locator {
    return section.getByRole("button");
  }

  /** Opens the panel of one lecture, since a collapsed panel has no cards to find. */
  async openLecture(section: Locator, lectureTitle: string): Promise<Locator> {
    await section.getByRole("button", { name: lectureTitle }).click();
    return section.getByRole("region", { name: lectureTitle });
  }

  cards(panel: Locator): Locator {
    return panel.getByRole("link");
  }

  /** The coloured frame inside the link; the colour is what the test reads. */
  frame(card: Locator): Locator {
    return card.locator(".annotation-overview-item");
  }

  /** Follows the card into the tab it opens. */
  async open(card: Locator): Promise<Page> {
    const opened = this.page.waitForEvent("popup");
    await card.click();
    return await opened;
  }
}
