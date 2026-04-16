import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  gameApi: service(),

  model(params) {
    return this.gameApi.requestOne('hgTavernNight', { id: params.night_id }, null);
  },

  setupController(controller, model) {
    this._super(controller, model);
    controller.set('nightId', model.id);

    const poll = setInterval(() => {
      this.gameApi.requestOne('hgTavernNight', { id: model.id }, null)
        .then((data) => { controller.set('model', data); });
    }, 15000);
    controller.set('pollTimer', poll);
  },

  deactivate() {
    clearInterval(this.controller.get('pollTimer'));
  }
});
