import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';
import RSVP from 'rsvp';

export default Route.extend({
  gameApi: service(),
  model() {
    return this.gameApi.requestOne('heroesguildJobBoard', {}, null);
  }
});
