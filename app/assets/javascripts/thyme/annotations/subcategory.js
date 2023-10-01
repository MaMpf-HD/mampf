class Subcategory extends CategoryEnum {

  static _subcategories = []; // do not manipulate this array outside of this class!

  static DEFINITION = new Subcategory('definition');
  static ARGUMENT = new Subcategory('argument');
  static STRATEGY = new Subcategory('strategy');

  constructor(name) {
    super(name);
    Subcategory._subcategories.push(this);
  }

  static getByName(name) {
    return super.getByName(name, Subcategory._subcategories);
  }

  static all() {
    return super.all(Subcategory._subcategories);
  }

}