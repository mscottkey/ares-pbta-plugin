import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi:       service(),
  flashMessages: service(),

  doAction(actionName) {
    this.gameApi.requestOne('hgTavernAction',
      { night_id: this.model.id, action: actionName }, null)
      .then((data) => {
        if (data.error) {
          this.flashMessages.danger(data.error);
        } else {
          this.set('model', data);
          this.flashMessages.success('See scene for result.');
        }
      });
  },

  actions: {
    doCarouse()     { this.doAction('carouse');     },
    doImbibe()      { this.doAction('imbibe');      },
    doSober()       { this.doAction('sober');       },
    doInvestigate() { this.doAction('investigate'); },

    addClue(leadId) {
      this.gameApi.requestOne('hgAddClue', { lead_id: leadId }, null)
        .then((data) => {
          if (data.error) {
            this.flashMessages.danger(data.error);
          } else {
            this.set('model', data);
            if (data.converted) {
              this.flashMessages.success('Lead converted to contract!');
            } else {
              this.flashMessages.success('Clue added.');
            }
          }
        });
    },

    closeNight() {
      this.gameApi.requestOne('hgCloseTavernNight',
        { night_id: this.model.id }, null)
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
