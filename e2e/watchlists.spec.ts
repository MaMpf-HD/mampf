import { WatchlistsPage } from "./page-objects/watchlists_page";
import { expect, test } from "./_support/fixtures";

test.describe("create Watchlists", () => {
  test("can create new watchlist with description", async ({ student: { page } }) => {
    const watchlistsPage = new WatchlistsPage(page);
    await watchlistsPage.goto();
    await watchlistsPage.createWatchlist("Test Watchlist", "This is a test watchlist.");
  });

  test("can create new watchlist without description", async ({ student: { page } }) => {
    const watchlistsPage = new WatchlistsPage(page);
    await watchlistsPage.goto();
    await watchlistsPage.createWatchlist("Another Test Watchlist");
  });

  test("can not create watchlist with duplicate name", async ({ factory, student: { page, user } }) => {
    const watchlistName = "Duplicate Name Watchlist";
    await factory.create("watchlist", [], { user: user, name: watchlistName });
    const watchlistsPage = new WatchlistsPage(page);
    await watchlistsPage.goto();
    await watchlistsPage.createWatchlist(watchlistName, "Second watchlist with the same name.", false);
    await expect(page.getByText("A watchlist with that name")).toBeVisible();
  });
});

test.describe("edit Watchlists", () => {
  test("can change watchlist name and description", async ({ factory, student: { page, user } }) => {
    await factory.create("watchlist", [], { user: user });
    const watchlistsPage = new WatchlistsPage(page);
    await watchlistsPage.goto();
    await watchlistsPage.editWatchlist("Updated Watchlist Name", "Updated description.");
    await expect(page.getByRole("button", { name: "Updated Watchlist Name" })).toBeVisible();
    await expect(page.getByText("Watchlist was changed")).toBeVisible();
    await page.getByRole("button", { name: "Description" }).click();
    await expect(page.locator("#collapseDescription div").filter({ hasText: "Updated description." })).toBeVisible();
  });

  test("can change visibility of watchlist", async ({ factory, student: { page, user } }) => {
    const watchlist = await factory.create("watchlist", [], { user: user });
    const watchlistsPage = new WatchlistsPage(page, `/watchlists/${watchlist.id}`);
    await watchlistsPage.goto();
    await expect(watchlistsPage.isPublic()).resolves.toBe(false);
    await watchlistsPage.toggleVisibility();
    await expect(watchlistsPage.isPublic()).resolves.toBe(true);
    await page.reload();
    await expect(watchlistsPage.isPublic()).resolves.toBe(true);
  });

  test("can delete watchlist", async ({ factory, student: { page, user } }) => {
    const watchlist1 = await factory.create("watchlist", [], { user: user, name: "Watchlist 1" });
    await factory.create("watchlist", [], { user: user, name: "Watchlist 2" });
    const watchlistsPage = new WatchlistsPage(page, `/watchlists/${watchlist1.id}`);
    await watchlistsPage.goto();
    await watchlistsPage.deleteWatchlist();
    await expect(page.getByRole("alert").filter({ hasText: "was successfully deleted" })).toBeVisible();
    await expect(page.getByText("Watchlist 1")).not.toBeVisible();
    await expect(page.getByText("Watchlist 2")).toBeVisible();
  });

  test("can not delete watchlist when deletion is cancelled", async ({ factory, student: { page, user } }) => {
    const watchlist = await factory.create("watchlist", [], { user: user, name: "Watchlist to Delete" });
    const watchlistsPage = new WatchlistsPage(page, `/watchlists/${watchlist.id}`);
    await watchlistsPage.goto();
    await watchlistsPage.deleteWatchlist(false);
    await expect(page.getByRole("button", { name: "Watchlist to Delete" })).toBeVisible();
  });
});

test.describe("view Watchlists", () => {
  test("can view public watchlist of other user", async ({ factory, student: { page }, student2: { user: student2User, page: student2Page } }) => {
    const publicWatchlist = await factory.create("watchlist", [], {
      user: student2User,
      public: true,
      name: "Public Watchlist",
    });
    const watchlistsPage = new WatchlistsPage(student2Page, `/watchlists/${publicWatchlist.id}`);
    await watchlistsPage.goto();
    await expect(student2Page.getByRole("button", { name: "Public Watchlist" })).toBeVisible();
    await expect(watchlistsPage.isPublic()).resolves.toBe(true);
    const watchlistsPage1 = new WatchlistsPage(page, `/watchlists/${publicWatchlist.id}`);
    await watchlistsPage1.goto();
    await expect(page.getByText("You are not authorized to")).not.toBeVisible();
  });

  test("can not view private watchlist of other user", async ({ factory, student: { page }, student2: { user: student2User } }) => {
    const privateWatchlist = await factory.create("watchlist", [], {
      user: student2User,
      public: false,
      name: "Private Watchlist",
    });
    const watchlistsPage = new WatchlistsPage(page, `/watchlists/${privateWatchlist.id}`);
    await watchlistsPage.goto();
    await expect(page.getByText("You are not authorized to")).toBeVisible();
  });
});

test.describe("manage Watchlist entries", () => {
  test("can delete watchlist entry", async ({ factory, student: { page, user } }) => {
    const watchlist = await factory.create("watchlist", [], { user: user });
    const medium = await factory.create("lecture_medium", ["released"]);
    await factory.create("watchlist_entry", [], {
      watchlist_id: watchlist.id,
      medium_id: medium.id,
    });
    const watchlistsPage = new WatchlistsPage(page, `/watchlists/${watchlist.id}`);
    await watchlistsPage.goto();
    await watchlistsPage.deleteWatchlistEntry();
    await expect(page.getByRole("alert").filter({ hasText: "The medium was removed from" })).toBeVisible();
  });
  test("can not delete watchlist entry when deletion is cancelled", async ({ factory, student: { page, user } }) => {
    const watchlist = await factory.create("watchlist", [], { user: user });
    const medium = await factory.create("lecture_medium", ["released"]);
    await factory.create("watchlist_entry", [], {
      watchlist_id: watchlist.id,
      medium_id: medium.id,
    });
    const watchlistsPage = new WatchlistsPage(page, `/watchlists/${watchlist.id}`);
    await watchlistsPage.goto();
    await watchlistsPage.deleteWatchlistEntry(false);
    await expect(page.getByRole("alert").filter({ hasText: "The medium was removed from" })).not.toBeVisible();
  });
});
