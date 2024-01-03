// eslint-disable-next-line no-unused-vars
class CategoryEnum {
  constructor(name) {
    this.name = name;
  }

  /*
   * Returns the correct locale for the given category.
   * This method will only work if the given thyme player
   * has a div-tag with the id "annotation-locales" which
   * includes the name of the categories as data sets, e.g.
   * data-note="<%= t(...) %>".
   */
  locale() {
    return document.getElementById("annotation-locales").dataset[this.name];
  }

  /*
   * Return the object with the given name in the given array.
   *
   * Override in subclasses.
   */
  static getByName(name, array) {
    for (let a of array) {
      if (a.name === name) {
        return a;
      }
    }
  }

  /*
   * Returns an array with all objects of this enum.
   *
   * Override in subclasses.
   */
  static all(array) {
    return array.slice();
  }
}
