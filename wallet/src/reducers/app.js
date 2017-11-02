import { ReducerFactory, Assing } from 'lib/util';
import {
  APP_LOADING_START,
  APP_LOADING_END,
  APP_LOADING_TOGGLE
} from 'constants/action';

const DState = {
  loading: false
};

const Actions = {

  [APP_LOADING_START]:
    state =>
      Assing(state, { loading: true }),

  [APP_LOADING_END]:
    state =>
      Assing(state, { loading: false }),

  [APP_LOADING_TOGGLE]:
    state =>
      Assing(state, { loading: !state.loading })

};

export default ReducerFactory(DState, Actions);