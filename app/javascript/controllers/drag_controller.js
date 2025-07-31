import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { post } from "@rails/request.js"

// Connects to data-controller="drag"
export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".drag-handle",
      animation: 150,
      ghostClass: "sortable-ghost",  // Class name for the drop placeholder
	    chosenClass: "sortable-chosen",  // Class name for the chosen item
	    dragClass: "sortable-drag",  // Class name for the dragging item
      filter: ".ignore-elements",
      draggable: ".item",
      onEnd: this.onDragEnd.bind(this),
    })
  }

  onDragEnd(event) {
    const list = this.sortable.toArray() // This gets an array of IDs based on the current DOM order
    const positions = {}
    list.forEach((id, index) => {
      positions[id] = index + 1
    })

    this.update_positions(positions)
  }

  async update_positions(positions) {
    try {
      const response = await post(
        `${this.urlValue}`, {
          body: { positions },
          contentType: "application/json",
          responseKind: "turbo-stream"
        }
      )
      if (response.ok) {
      }
    } catch (error) {
      console.error("Failed to process request:", error)
    }
  }
}
