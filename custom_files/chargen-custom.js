import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),
  chargenData: null,

  init() {
    this._super(...arguments);
    this.gameApi.requestOne('heroesguildChargenData', {}, null)
      .then((data) => {
        this.set('chargenData', data);
      });
  },

  actions: {
    initStats() {
      this.gameApi.requestOne('initHeroesGuildStats', {}, null)
        .then((response) => {
          if (response.error) {
            this.get('flashMessages').danger(response.error);
          } else {
            this.get('flashMessages').success('Playbook stats initialized!');
          }
        });
    },
    selectGimmick(gimmickName) {
      if (!gimmickName) { return; }
      this.gameApi.requestOne('setHeroesGuildGimmick', { gimmick: gimmickName }, null)
        .then((response) => {
          if (response.error) {
            this.get('flashMessages').danger(response.error);
          } else {
            this.get('flashMessages').success('Gimmick selected!');
          }
        });
    }
  }
});
