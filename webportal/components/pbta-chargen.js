import Component from '@ember/component';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),
  chargenData: null,

  init() {
    this._super(...arguments);
    this.loadChargenData();
  },

  loadChargenData() {
    this.gameApi.requestOne('heroesguildChargenData', {}, null)
      .then((data) => {
        this.set('chargenData', data);
      });
  },

  @action
  initStats() {
    this.gameApi.requestOne('initHeroesGuildStats', {}, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
        } else {
          this.flashMessages.success('Playbook stats initialized!');
          this.loadChargenData();
          if (this.updated) { this.updated(); }
        }
      });
  },

  @action
  selectGimmickFromEvent(event) {
    const gimmickName = event.target.value;
    if (!gimmickName) { return; }
    this.gameApi.requestOne('setHeroesGuildGimmick', { gimmick: gimmickName }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
        } else {
          this.flashMessages.success('Gimmick selected!');
          this.loadChargenData();
          if (this.updated) { this.updated(); }
        }
      });
  }
});
