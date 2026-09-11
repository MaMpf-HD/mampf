import { readFile } from "node:fs/promises";
import { Page } from "../_support/fixtures";
import { parseCsv } from "../_support/csv";

export const QUESTIONNAIRE_CSV_HEADERS = [
  "Answer ID",
  "Created At",
  "Codename",
  "Slide position",
  "Slide title",
  "Total time on slide",
  "Time on slide",
  "Time on info slide",
  "Info slide access count",
  "Info slide first access time",
  "Answer",
  "Selected Options",
  "Likert Scale Option",
];

export type QuestionnaireCsvRow = {
  answerId: string;
  createdAt: string;
  codename: string;
  slidePosition: string;
  slideTitle: string;
  totalTimeOnSlide: string;
  timeOnSlide: string;
  timeOnInfoSlide: string;
  infoSlideAccessCount: string;
  infoSlideFirstAccessTime: string;
  answer: string;
  selectedOptions: string;
  likertScaleOption: string;
};

/** The generated code, as the codename page groups it for reading. */
export const CODENAME_PATTERN = /^[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$/;

export type QuestionnaireCsvExport = {
  headers: string[];
  rows: QuestionnaireCsvRow[];
};

export class VignettesPage {
  readonly page: Page;
  /** The slide the reader is on, so submit() can wait for the next one. */
  private position = 1;

  constructor(page: Page) {
    this.page = page;
  }

  async openOverview(lectureId: number) {
    await this.page.goto(`/lectures/${lectureId}/questionnaires`);
  }

  row(title: string) {
    return this.page.getByRole("listitem").filter({ hasText: title });
  }

  /** Opens the vignette; lands on the consent page if it collects data. */
  async openQuestionnaire(title: string) {
    await this.row(title).getByRole("link", { name: /Start|Continue/ }).click();
    await this.page.waitForURL(/\/(take|consent)/);
    this.readPosition();
  }

  async declineDataCollection() {
    await this.page.getByRole("radio", { name: "No." }).check();
    await this.page.getByRole("button", { name: "Continue" }).click();
    await this.reachTakePage();
  }

  /** Consents, and returns the code the way the CSV stores it. */
  async consentWithNewCode(): Promise<string> {
    await this.page.getByRole("radio", { name: "Yes, and I need a code." }).check();
    await this.page.getByRole("button", { name: "Continue" }).click();
    await this.page.waitForURL(/\/codename/);

    return await this.acknowledgeCode();
  }

  /** Notes the code down and moves on into the vignette. */
  async acknowledgeCode(): Promise<string> {
    const shown = await this.page.getByText(CODENAME_PATTERN).innerText();
    await this.page.getByRole("link", { name: "I have written the code down" }).click();
    await this.reachTakePage();

    return shown.replaceAll("-", "");
  }

  async consentWithExistingCode(code: string) {
    await this.page.getByRole("radio", { name: "Yes, and I already have a code." }).check();
    await this.page.getByRole("textbox", { name: "Code" }).fill(code);
    await this.page.getByRole("button", { name: "Continue" }).click();
    await this.reachTakePage();
  }

  private async reachTakePage() {
    await this.page.waitForURL(/\/take/);
    // The slide's timings start when its script initialises, so nothing may
    // touch the clock before that.
    await this.page.locator("#vignette-take-card[data-vignette-take-ready]").waitFor();
    this.readPosition();
  }

  private readPosition() {
    const match = /[?&]position=(\d+)/.exec(this.page.url());
    this.position = match ? Number(match[1]) : 1;
  }

  async enableMockClock() {
    await this.page.clock.install({ time: new Date(0) });
  }

  async setMockTime(timeMs: number) {
    await this.page.clock.setFixedTime(new Date(timeMs));
  }

  async advanceMockTime(deltaSeconds: number) {
    await this.page.clock.runFor(deltaSeconds * 1000);
  }

  async answerText(value: string) {
    await this.page.getByRole("textbox").fill(value);
  }

  async answerNumber(value: string) {
    await this.page.getByRole("spinbutton").fill(value);
  }

  async answerMultipleChoice(optionText: string) {
    await this.page.getByRole("checkbox", { name: optionText }).check();
  }

  async answerLikert(optionText: string) {
    await this.page.getByText(optionText).click();
  }

  async openInfoSlide() {
    await this.page.locator(".open-info-slide-btn").first().click();
    await this.page.locator(".vignette-info-slide-modal.show").first().waitFor();
  }

  async closeInfoSlide() {
    await this.page.keyboard.press("Escape");
    await this.page.locator(".vignette-info-slide-modal.show").first().waitFor({
      state: "hidden",
    });
  }

  async submit(isLastSlide = false) {
    // The control is a button for a tracked run and a link for an untracked
    // one; both carry the same label.
    await this.page.getByLabel(isLastSlide ? "Finish vignette" : "Next slide").click();

    if (isLastSlide) {
      await this.page.waitForURL(/\/finish/);
      return;
    }

    this.position += 1;
    await this.page.waitForURL(new RegExp(`[?&]position=${this.position}(&|$)`));
    await this.page.locator("#vignette-take-card[data-vignette-take-ready]").waitFor();
  }

  async exportQuestionnaireCsv(questionnaireId: number): Promise<string[][]> {
    await this.page.goto(`/questionnaires/${questionnaireId}/edit`);
    const downloadPromise = this.page.waitForEvent("download");
    await this.page.getByRole("button", { name: "Export Statistics" }).click();
    const download = await downloadPromise;
    const filePath = await download.path();
    if (!filePath) {
      throw new Error("Missing download path");
    }

    const csvText = await readFile(filePath, "utf-8");

    return parseCsv(csvText)
      .filter(r => r.length > 1)
      .map((r): string[] => {
        const missingColumns = QUESTIONNAIRE_CSV_HEADERS.length - r.length;
        if (missingColumns <= 0) {
          return r;
        }
        return [...r, ...Array<string>(missingColumns).fill("")];
      });
  }

  async exportQuestionnaire(
    questionnaireId: number,
  ): Promise<QuestionnaireCsvExport> {
    const csvRows = await this.exportQuestionnaireCsv(questionnaireId);
    const [headers = QUESTIONNAIRE_CSV_HEADERS, ...rows] = csvRows;

    if (!this.matchesExpectedHeaders(headers)) {
      throw new Error("Unexpected questionnaire CSV headers");
    }

    return {
      headers,
      rows: rows.map(row => this.toQuestionnaireCsvRow(row)),
    };
  }

  private toQuestionnaireCsvRow(row: string[]): QuestionnaireCsvRow {
    return {
      answerId: row[0],
      createdAt: row[1],
      codename: row[2],
      slidePosition: row[3],
      slideTitle: row[4],
      totalTimeOnSlide: row[5],
      timeOnSlide: row[6],
      timeOnInfoSlide: row[7],
      infoSlideAccessCount: row[8],
      infoSlideFirstAccessTime: row[9],
      answer: row[10],
      selectedOptions: row[11],
      likertScaleOption: row[12],
    };
  }

  private matchesExpectedHeaders(headers: string[]): boolean {
    if (headers.length !== QUESTIONNAIRE_CSV_HEADERS.length) {
      return false;
    }

    return QUESTIONNAIRE_CSV_HEADERS.every(
      (expectedHeader, index) => headers[index] === expectedHeader,
    );
  }
}
