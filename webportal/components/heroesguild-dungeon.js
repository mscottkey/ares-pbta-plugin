import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi:       service(),
  flashMessages: service(),
  selectedMove:  null,

  actions: {
    selectMove(moveName) {
      this.set('selectedMove', moveName);
    },

    selectContract(contractId) {
      this.gameApi.requestOne('hgSelectContract',
        { run_id: this.model.id, contract_id: contractId }, null)
        .then((data) => {
          if (data.error) {
            this.flashMessages.danger(data.error);
          } else {
            this.set('model', data);
          }
        });
    },

    rollMove() {
      if (!this.selectedMove) return;
      this.gameApi.requestOne('hgHudRollMove',
        { run_id: this.model.id, move_name: this.selectedMove }, null)
        .then((data) => {
          if (data.error) {
            this.flashMessages.danger(data.error);
          } else {
            this.set('model', data);
            this.flashMessages.success(`Rolled ${this.selectedMove} — see scene for result.`);
          }
        });
    },

    advanceDoom() {
      this.gameApi.requestOne('hgDungeonGmAction',
        { run_id: this.model.id, action: 'doom' }, null)
        .then((data) => { if (!data.error) this.set('model', data); });
    },

    randomThreat() {
      this.gameApi.requestOne('hgDungeonGmAction',
        { run_id: this.model.id, action: 'threat' }, null)
        .then((data) => { if (!data.error) this.set('model', data); });
    },

    markProgress(boxes) {
      this.gameApi.requestOne('hgDungeonGmAction',
        { run_id: this.model.id, action: 'progress', boxes: boxes }, null)
        .then((data) => { if (!data.error) this.set('model', data); });
    },

    endRun() {
      this.gameApi.requestOne('hgEndDungeonRun',
        { run_id: this.model.id }, null)
        .then((result) => {
          if (result.error) {
            this.flashMessages.danger(result.error);
          } else {
            this.flashMessages.success(`Run ended: ${result.status}.`);
          }
        });
    }
  }
});
