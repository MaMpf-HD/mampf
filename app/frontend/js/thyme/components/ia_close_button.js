import { Component } from "~/js/thyme/components/component";

/**
 * The Interactive Area button gives a shortcut
 * for the minus event of an IaButton.
 */
export class IaCloseButton extends Component {
  constructor(element, iaButton) {
    super(element);
    this.iaButton = iaButton;
  }

  add() {
    const iaButton = this.iaButton;
    this.element.addEventListener("click", function () {
      iaButton.plus();
    });
  }
}
