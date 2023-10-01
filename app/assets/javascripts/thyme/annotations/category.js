class Category extends CategoryEnum {

  static _categories = [];

  static NOTE = new Category('note', '#44ee11'); //green
  static CONTENT = new Category('content', '#eeee00'); //yellow
  static PRESENTATION = new Category('presentation', '#ff9933'); //orange
  static MISTAKE = new Category('mistake', '#ff0000'); //red

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