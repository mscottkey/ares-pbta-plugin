import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),
  tagName: '',
  selectPbtaRoll: false,

  actions: {
    pbtaRollStat(statKey) {
      this.gameApi.requestOne('pbtaRollStat',
        { scene_id: this.scene.id, stat: statKey }, null)
        .then((response) => {
          if (response.error) {
            this.flashMessages.danger(response.error);
          }
        });
      this.set('selectPbtaRoll', false);
    },

    pbtaRollMove(moveName) {
      this.gameApi.requestOne('pbtaRollMove',
        { scene_id: this.scene.id, move: moveName }, null)
        .then((response) => {
          if (response.error) {
            this.flashMessages.danger(response.error);
          }
        });
      this.set('selectPbtaRoll', false);
    }
  }
});
