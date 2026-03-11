import { readFile } from "node:fs/promises";
import { Page } from "../_support/fixtures";
import { parseCsv } from "../_support/csv";

export type SlideStats = {
  timeOnSlide: number;
  totalTimeOnSlide: number;
  timeOnInfoSlides: string;
  infoSlidesAccessCount: string;
  infoSlidesFirstAccessTime: string;
};

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

export type QuestionnaireCsvExport = {
  headers: string[];
  rows: QuestionnaireCsvRow[];
};

export class VignettesPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async setPersonalCode(lectureId: number, personalCode: string) {
    await this.page.goto(`/lectures/${lectureId}/questionnaires`);
    await this.page.getByRole("textbox").first().fill(personalCode);
    await this.page.getByRole("button", { name: /save/i }).click();
  }

  async openQuestionnaire(questionnaireId: number) {
    await this.page.goto(`/questionnaires/${questionnaireId}/take`);
  }

  async enableMockClock(startTimeMs = 0) {
    await this.page.clock.install({ time: new Date(startTimeMs) });
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

  async submitWithStats() {
    await this.page.locator("#vignettes-answer-form button[type='submit']").click();
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
