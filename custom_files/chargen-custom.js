import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
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
        .then(() => {
          this.get('flashMessages').success('Playbook stats initialized!');
        });
    },
    selectGimmick(gimmickName) {
      this.gameApi.requestOne('setHeroesGuildGimmick', { gimmick: gimmickName }, null)
        .then(() => {
          this.set('char.heroesguild_gimmick', gimmickName);
        });
    }
  }
});
