import showModal from "discourse/lib/show-modal"

export default {
  setupComponent(args, component) {
    console.log(component)
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
  },

  shouldRender(args, component) {
    return true
  }
}
