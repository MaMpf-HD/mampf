import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { datasourceMap: Array };
  datasource = [];

  connect() {
    console.log(this.datasourceMapValue);
    this.datasource = this.datasourceMapValue.map((item) => {
      return { index: item.preference_rank, ...item };
    });
  }

  down(event) {
    console.log("down event");
    const index = parseInt(event.currentTarget.dataset.index, 10);
    console.log("down", index);
    this.reorder(index);
    // this.render();
  }

  up(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    console.log("up", index);
    this.reorder(index - 1);
  }

  reorder(index) {
    [this.datasource[index], this.datasource[index + 1]] = [this.datasource[index + 1], this.datasource[index]];
  }

  render() {
    // re-render table rows based on this.datasource
  }

  getData() {
    return this.datasource;
  }
}
