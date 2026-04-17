import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  gameApi: service(),

  model() {
    return this.gameApi.requestOne('hgGuildBoard', {}, null);
  },

  setupController(controller, model) {
    this._super(controller, model);
    // Refresh every 60 seconds — board changes slowly
    let poll = setInterval(() => {
      this.gameApi.requestOne('hgGuildBoard', {}, null)
        .then((data) => controller.set('model', data));
    }, 60000);
    controller.set('pollTimer', poll);
  },

  deactivate() {
    clearInterval(this.controller.get('pollTimer'));
  }
});
