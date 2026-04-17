import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi:       service(),
  flashMessages: service(),

  actions: {
    addClue(leadId) {
      this.gameApi.requestOne('hgAddClue', { lead_id: leadId }, null)
        .then((data) => {
          if (data.error) {
            this.flashMessages.danger(data.error);
          } else if (data.converted) {
            this.flashMessages.success('Lead converted to a contract and posted to the board!');
            this.gameApi.requestOne('hgGuildBoard', {}, null)
              .then((board) => this.set('model', board));
          } else {
            this.flashMessages.success('Clue added. Check the forum thread for details.');
            this.gameApi.requestOne('hgGuildBoard', {}, null)
              .then((board) => this.set('model', board));
          }
        });
    }
  }
});
