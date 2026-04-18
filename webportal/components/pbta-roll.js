import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),

  actions: {
    cancelRoll() {
      this.onClose();
    },

    hgRollStat(statKey) {
      this.gameApi.requestOne('pbta_roll_stat',
        { scene_id: this.scene.id, stat: statKey }, null)
        .then((result) => {
          if (result.error) {
            this.flashMessages.danger(result.error);
          } else {
            this.onClose();
          }
        });
    },

    hgRollMove(moveName) {
      this.gameApi.requestOne('pbta_roll_move',
        { scene_id: this.scene.id, move: moveName }, null)
        .then((result) => {
          if (result.error) {
            this.flashMessages.danger(result.error);
          } else {
            this.onClose();
          }
        });
    }
  }
});
