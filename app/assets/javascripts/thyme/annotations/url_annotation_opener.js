// eslint-disable-next-line no-unused-vars
function openAnnotationIfSpecifiedInUrl() {
  const annotationValue = new URLSearchParams(window.location.search).get("ann");
  if (!annotationValue) {
    return;
  }
  const annotationId = Number(annotationValue);
  thymeAttributes.annotationArea.showAnnotationWithId(annotationId);
}
