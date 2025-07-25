import { Category } from "~/js/thyme/annotations/category";

function colorAnnotationCardsSharedByStudents() {
  const annotationCards = $("[data-annotation-card-category]");
  for (let card of annotationCards) {
    const category = card.dataset.annotationCardCategory;
    if (!category) {
      continue;
    }
    const color = Category.getByName(category).color;
    card.style.borderColor = color;
  }
}

colorAnnotationCardsSharedByStudents();
