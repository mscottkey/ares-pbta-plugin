import Component from '@ember/component';
import { inject as service } from '@ember/service';

// Extends the scene play component with Heroes Guild container controls.
// HUDs open in a new tab so the player keeps the scene view.
export default Component.extend({
  gameApi:       service(),
  flashMessages: service(),

  actions: {
    hgStartDungeonRun() {
      this.gameApi.requestOne('hgStartDungeonRun', { scene_id: this.scene.id }, null)
        .then((result) => {
          if (result.run_id) {
            window.open(`/heroesguild/dungeon/${result.run_id}`, '_blank');
          } else if (result.error) {
            this.flashMessages.danger(result.error);
          }
        });
    },

    hgEndDungeonRun() {
      const runId = this.custom && this.custom.heroesguild && this.custom.heroesguild.dungeon_run_id;
      if (!runId) return;
      this.gameApi.requestOne('hgEndDungeonRun', { run_id: runId }, null)
        .then((result) => {
          if (result.error) {
            this.flashMessages.danger(result.error);
          } else {
            this.flashMessages.success('Dungeon run ended.');
          }
        });
    },

    hgStartTavernNight() {
      this.gameApi.requestOne('hgStartTavernNight', { scene_id: this.scene.id }, null)
        .then((result) => {
          if (result.night_id) {
            window.open(`/heroesguild/tavern/${result.night_id}`, '_blank');
          } else if (result.error) {
            this.flashMessages.danger(result.error);
          }
        });
    },

    hgCloseTavernNight() {
      const nightId = this.custom && this.custom.heroesguild && this.custom.heroesguild.tavern_night_id;
      if (!nightId) return;
      this.gameApi.requestOne('hgCloseTavernNight', { night_id: nightId }, null)
        .then((result) => {
          if (result.error) {
            this.flashMessages.danger(result.error);
          } else {
            this.flashMessages.success('Tavern night closed.');
          }
        });
    }
  }
});
