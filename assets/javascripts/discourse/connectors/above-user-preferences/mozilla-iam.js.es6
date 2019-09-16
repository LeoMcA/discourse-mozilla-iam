import showModal from "discourse/lib/show-modal"
import { ajax } from "discourse/lib/ajax"

export default {
  setupComponent(args, component) {
    console.log(args.model)
  },

  reload() {
    window.location.reload()
  },

  actions: {
    link() {
      const container = Discourse.__container__;
      const controller = container.lookup("controller:dinopark-link-modal")
      const dinopark_profile = {
        username: "ayylmao"
      }
      controller.setProperties({
        showingConfirm: true,
        mode: "preferences",
        values: dinopark_profile,
        options: {
          dinopark_profile
        }
      })
      showModal("dinopark-link-modal")
    },

    unlink() {
      const container = Discourse.__container__;
      const controller = container.lookup("controller:dinopark-unlink-modal")
      controller.setProperties({
        user: this.get("model")
      })
      showModal("dinopark-unlink-modal")
    },
  },

  shouldRender(args, component) {
    return args.model.get("mozilla_iam.dinopark_enabled")
  }
}
