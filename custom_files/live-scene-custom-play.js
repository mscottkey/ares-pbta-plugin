import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),
  selectPbtaRoll: false,

  actions: {
    hgStartDungeonRun() {
      this.gameApi.requestOne('heroesguildStartDungeon',
        { scene_id: this.scene.id }, null)
        .then((result) => {
          if (result.error) { this.flashMessages.danger(result.error); }
        });
    },
    hgEndDungeonRun() {
      this.gameApi.requestOne('heroesguildEndDungeon',
        { scene_id: this.scene.id }, null)
        .then((result) => {
          if (result.error) { this.flashMessages.danger(result.error); }
        });
    },
    hgStartTavernNight() {
      this.gameApi.requestOne('heroesguildStartTavern',
        { scene_id: this.scene.id }, null)
        .then((result) => {
          if (result.error) { this.flashMessages.danger(result.error); }
        });
    },
    hgCloseTavernNight() {
      this.gameApi.requestOne('heroesguildCloseTavern',
        { scene_id: this.scene.id }, null)
        .then((result) => {
          if (result.error) { this.flashMessages.danger(result.error); }
        });
    }
  }
});
