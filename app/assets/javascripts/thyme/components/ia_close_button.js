class IaCloseButton extends Component {

  constructor(element, iaButton) {
    super(element);
    this.iaButton = iaButton;
  }

  add() {
    const iaButton = this.iaButton;
    this.element.addEventListener('click', function() {
      iaButton.minus();
    });
  }

}