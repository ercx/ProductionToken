import { ReducerFactory, Assing } from 'lib/util';
import {
  NET_CONNECT_INIT,
  NET_CONNECT_START,
  NET_CONNECT_END,
  NET_CONNECT_ERROR
} from 'constants/action';

const DState = {
  network: null,
  connecting: false,
  error: null
};

const Actions = {

  [NET_CONNECT_INIT]:
    (state, { network }) =>
      Assing(state, { network }),

  [NET_CONNECT_START]:
    state =>
      Assing(state, { connecting: true }),

  [NET_CONNECT_END]:
    state =>
      Assing(state, { connecting: false }),

  [NET_CONNECT_ERROR]:
    (state, { error }) =>
      Assing(state, { error })

};

export default ReducerFactory(DState, Actions);