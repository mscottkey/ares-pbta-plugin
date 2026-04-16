import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  
  actions: {
    initStats() {
      this.gameApi.requestOne('initHeroesGuildStats', {}, null)
        .then(() => {
          this.get('flashMessages').success('Playbook stats initialized from your Group setting!');
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
