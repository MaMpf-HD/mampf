/**
 * Adds data as hidden inputs to a form.
 *
 * Inspired by: https://stackoverflow.com/a/53366001/
 *
 * @param {HTMLFormElement} form - The form to which data should be added.
 * @param {Object} data - An object containing key-value pairs to be added as hidden inputs.
 */
export function addDataToForm(form, data) {
  Object.entries(data).forEach(([name, value]) => {
    let input = form.querySelector(`input[name='${name}']`);
    if (!input) {
      input = document.createElement("input");
      input.type = "hidden";
      input.name = name;
      form.appendChild(input);
    }
    input.value = value;
  });
}
