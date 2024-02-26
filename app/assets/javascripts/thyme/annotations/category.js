// eslint-disable-next-line no-unused-vars
class Category extends CategoryEnum {
  static _categories = [];

  static NOTE = new Category("note", "#f78f19");
  static CONTENT = new Category("content", "#A333C8");
  static PRESENTATION = new Category("presentation", "#2185D0");
  static MISTAKE = new Category("mistake", "#fc1461");

  constructor(name, color) {
    super(name);
    this.color = color;
    Category._categories.push(this);
  }

  static getByName(name) {
    return super.getByName(name, Category._categories);
  }

  static all() {
    return super.all(Category._categories);
  }
}
