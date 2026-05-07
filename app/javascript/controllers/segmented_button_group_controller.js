import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  select(event) {
    const clicked = event.currentTarget
    this.element.querySelectorAll("button[data-value]").forEach(btn => {
      btn.classList.toggle("active", btn === clicked)
    })
    this.fieldTarget.value = clicked.dataset.value
  }
}
