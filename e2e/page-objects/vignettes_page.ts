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

  async submitWithStats(stats: SlideStats) {
    await this.page.evaluate((currentStats) => {
      const setValue = (id: string, value: string) => {
        const element = document.getElementById(id) as HTMLInputElement | null;
        if (!element) {
          throw new Error(`Missing input field '${id}'`);
        }
        element.value = value;
      };

      const jquery = (window as any).$;
      if (jquery) {
        jquery("#vignettes-answer-form").off("submit");
      }

      setValue("time-on-slide-field", String(currentStats.timeOnSlide));
      setValue("total-time-on-slide-field", String(currentStats.totalTimeOnSlide));
      setValue("time-on-info-slides-field", currentStats.timeOnInfoSlides);
      setValue("info-slides-access-count-field", currentStats.infoSlidesAccessCount);
      setValue("info-slides-first-access-times-field", currentStats.infoSlidesFirstAccessTime);
    }, stats);

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
}
