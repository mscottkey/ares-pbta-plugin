import Component from '@ember/component';

export default Component.extend({
  tagName: '',
  selectPbtaRoll: false,

  actions: {
    hgRollStat(statKey) {
      this.send('sendInput', `+roll ${statKey}`);
      this.set('selectPbtaRoll', false);
    },
    hgRollMove(moveName) {
      this.send('sendInput', `+move ${moveName}`);
      this.set('selectPbtaRoll', false);
    }
  }
});
