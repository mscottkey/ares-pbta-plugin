import Component from '@ember/component';

export default Component.extend({
  tagName: '',

  actions: {
    cancelRoll() {
      this.onClose();
    },
    pbtaRollStat(statKey) {
      this.onRollStat(statKey);
    },
    pbtaRollMove(moveName) {
      this.onRollMove(moveName);
    }
  }
});
