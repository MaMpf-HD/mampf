import { Locator, Page } from "../_support/fixtures";

/**
 * The video player and its feedback twin. Thyme draws its controls, markers
 * and the annotation area itself, without roles, so this is where they are
 * found by id.
 */
export class ThymePlayer {
  readonly page: Page;
  readonly link: string;
  readonly feedbackLink: string;
  readonly mediumId: number;

  constructor(page: Page, mediumId: number) {
    this.page = page;
    this.mediumId = mediumId;
    this.link = `/media/${mediumId}/play`;
    this.feedbackLink = `/media/${mediumId}/feedback`;
  }

  async goto() {
    const videoPromise = this.page.waitForResponse(response =>
      response.url().includes(`/media/${this.mediumId}/video/stream`),
    );
    // Usually, you should avoid "networkidle". However, here it is hard to
    // determine when the video player is fully loaded.
    await this.page.goto(this.link, { waitUntil: "networkidle" });
    await videoPromise;
  }

  async gotoFeedback() {
    await this.page.goto(this.feedbackLink);
  }

  get currentTime(): Locator {
    return this.page.locator("#current-time");
  }

  /** One pin per annotation on the feedback player's timeline. */
  get annotationMarkers(): Locator {
    return this.page.locator("#feedback-markers > span");
  }

  /** The pin's span has no height of its own; the icon inside takes the click. */
  async openAnnotationMarker(marker: Locator) {
    await marker.locator("i").click();
  }

  get annotationCategory(): Locator {
    return this.page.locator("#annotation-infobar");
  }

  get annotationComment(): Locator {
    return this.page.locator("#annotation-comment");
  }
}
