import Component from '@ember/component';
import { action, computed } from '@ember/object';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),
  chargenData: null,
  previewedGimmick: null,

  statList: computed('chargenData.char_stats', function() {
    const stats = this.get('chargenData.char_stats') || {};
    return ['brawn', 'cunning', 'flow', 'heart', 'luck'].map(key => {
      const val = stats[key] || 0;
      return { label: key.slice(0, 3).toUpperCase(), value: val >= 0 ? `+${val}` : `${val}` };
    });
  }),

  init() {
    this._super(...arguments);
    this.loadChargenData();
  },

  loadChargenData() {
    this.gameApi.requestOne('heroesguildChargenData', {}, null)
      .then((data) => {
        this.set('chargenData', data);
        if (data.char_gimmick) {
          const current = data.gimmicks.find(g => g.name === data.char_gimmick);
          if (current) { this.set('previewedGimmick', current); }
        }
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
  previewGimmick(event) {
    const name = event.target.value;
    if (!name) {
      this.set('previewedGimmick', null);
      return;
    }
    const gimmick = this.chargenData.gimmicks.find(g => g.name === name);
    this.set('previewedGimmick', gimmick || null);
  },

  @action
  selectGimmick(gimmickName) {
    this.gameApi.requestOne('setHeroesGuildGimmick', { gimmick: gimmickName }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
        } else {
          this.flashMessages.success(`${gimmickName} selected!`);
          this.loadChargenData();
          if (this.updated) { this.updated(); }
        }
      });
  }
});
