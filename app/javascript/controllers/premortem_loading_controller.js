import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["idle", "loading"]

  start() {
    this.idleTargets.forEach(el => el.classList.add("d-none"))
    this.loadingTargets.forEach(el => el.classList.remove("d-none"))
  }
}
