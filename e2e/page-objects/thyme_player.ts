import { Page } from "../_support/fixtures";

export class ThymePlayer {
  readonly page: Page;
  readonly link: string;
  readonly mediumId: number;

  constructor(page: Page, mediumId: number) {
    this.page = page;
    this.mediumId = mediumId;
    this.link = `/media/${mediumId}/play`;
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
}
