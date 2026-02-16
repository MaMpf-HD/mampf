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
    await this.page.waitForResponse(response => response.url().includes("/watchlists") && response.status() === 200);
    if (check) {
      await this.checkWatchlistCreated();
    }
  }

  async checkWatchlistCreated() {
    await expect(this.page.getByRole("alert").filter({ hasText: "Watchlist was successfully" })).toBeVisible();
  }

  async editWatchlist(newName: string, newDescription: string = "") {
    await this.page.locator("#changeWatchlistBtn").click();
    await this.page.waitForLoadState("networkidle");
    await this.page.locator("#watchlistNameField").clear();
    await this.page.waitForTimeout(100);
    await this.page.locator("#watchlistNameField").fill(newName);
    await this.page.locator("#watchlistDescriptionField").fill(newDescription);
    await this.page.locator("#confirmChangeWatchlistButton").click();
    await this.page.waitForLoadState("networkidle");
  }

  async toggleVisibility() {
    await this.page.locator("#watchlistVisiblityCheck").click();
  }

  async isPublic(): Promise<boolean> {
    return await this.page.locator("#watchlistVisiblityCheck").isChecked();
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
}
