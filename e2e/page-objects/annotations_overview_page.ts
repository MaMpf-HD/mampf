import { Locator, Page } from "../_support/fixtures";

/**
 * The overview of annotations: one's own, and for editors and teachers those
 * students shared. Both are accordions with a panel per lecture, so a lecture's
 * panel is found inside its section, not on the page.
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

  /** The lectures in the order shown, collapsed panels included. */
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

  /** The border sits on the card inside the link, not on the link. */
  frame(card: Locator): Locator {
    return card.locator(".annotation-overview-item");
  }

  /** Waits for the tab the card opens, since a click alone would miss it. */
  async open(card: Locator): Promise<Page> {
    const opened = this.page.waitForEvent("popup");
    await card.click();
    return await opened;
  }
}
