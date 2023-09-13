/**
  The basic component class from which every thyme related components (slider, selector, etc.)
  should be a subclass.
*/
class Component {

  /*
    element = The id of the HTML element associated to this button.
   */
  constructor(element) {
    this.element = document.getElementById(element);
  }

  /* This method should add the button functionality to the given player.
     Override it in the given subclass! */
  add() { }

}
