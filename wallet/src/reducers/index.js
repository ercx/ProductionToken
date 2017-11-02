import { routerReducer } from 'react-router-redux';

import AppReducer from 'reducers/app';
import NetReducer from 'reducers/net';

export default {
  routing: routerReducer,
  
  app: AppReducer,
  net: NetReducer
};