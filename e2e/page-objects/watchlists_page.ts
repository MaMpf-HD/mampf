import { expect, Page } from "../_support/fixtures";

export class WatchlistsPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, link: string = "/watchlists") {
    this.page = page;
    this.link = link;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async createWatchlist(name: string, description: string = "", check = true) {
    await this.page.locator("#openNewWatchlistForm").click();
    await this.page.waitForResponse(response => response.url().includes("/watchlists/new"));

    await this.page.getByRole("textbox", { name: "Enter name" }).fill(name);
    await this.page.getByRole("textbox", { name: "Enter description (optional)" }).fill(description);
    await this.page.getByRole("button", { name: "Create", exact: true }).click();
    if (check) {
      await this.checkWatchlistCreated();
    }
  }

  async checkWatchlistCreated() {
    await expect(this.page.getByRole("alert").filter({ hasText: "Watchlist was successfully" })).toBeVisible();
  }

  async editWatchlist(newName: string, newDescription: string = "") {
    await this.page.getByRole("button", { name: "Change" }).click();
    await this.page.waitForLoadState("networkidle");
    await this.page.getByRole("textbox", { name: "Enter name" }).fill(newName);
    await this.page.getByRole("textbox", { name: "Enter description (optional)" }).fill(newDescription);
    await this.page.getByRole("button", { name: "Save changes" }).click();
    await this.page.waitForLoadState("networkidle");
  }

  async toggleVisibility() {
    await this.page.getByRole("checkbox", { name: "Public" }).click();
  }

  async isPublic(): Promise<boolean> {
    return await this.page.getByRole("checkbox", { name: "Public" }).isChecked();
  }

  async deleteWatchlist(accept = true) {
    this.page.once("dialog", dialog => accept ? dialog.accept() : dialog.dismiss());
    await this.page.getByRole("link", { name: "Delete" }).click();
    await this.page.waitForLoadState("networkidle");
  }

  async deleteWatchlistEntry(accept = true) {
    this.page.once("dialog", dialog => accept ? dialog.accept() : dialog.dismiss());
    const deleteButton = this.page.getByTitle("Remove medium from watchlist").first();
    await deleteButton.click();
    await this.page.waitForLoadState("networkidle");
  }

  async getWatchlistName(): Promise<string | null> {
    return await this.page.locator("#watchlistButton").textContent();
  }

  async getDescription(): Promise<string | null> {
    return await this.page.locator(".card-body").textContent();
  }

  async swapEntries(fromId: number, toId: number) {
    await this.page.dragAndDrop(`div[data-id="${fromId}"] .mampf-card-header`, `div[data-id="${toId}"]`);
  }

  async getEntryOrder(): Promise<number[]> {
    const entryElements = await this.page.locator(".media-grid").all();
    const ids = [];
    for (const entryElement of entryElements) {
      const id = await entryElement.getAttribute("data-id");
      if (id) {
        ids.push(parseInt(id));
      }
    }
    return ids;
  }
}
