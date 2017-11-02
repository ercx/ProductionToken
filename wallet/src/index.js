import 'normalize.css';
import 'core-js/es6/map';
import 'core-js/es6/set';
import 'index.css';

import React from 'react';
import ReactDOM from 'react-dom';

import registerServiceWorker from 'registerServiceWorker';

import { Router, Route, IndexRoute } from 'react-router';
import { Provider } from 'react-redux';
import { Store, History } from 'store/index';

import Empty from 'components/views/Empty';
import Start from 'components/views/Start';
import Main from 'components/containers/Main';

const requireAuth = () => {
};

History.push('/');

ReactDOM.render(
  <Provider store={Store}>
    <Router history={History}>
      <Route path='/start' component={Start} />
      <Route path='/' onEnter={requireAuth} component={Main}>
        <IndexRoute component={Empty} />
        <Route path='*' component={Empty} />
      </Route>
    </Router>
  </Provider>,
  document.getElementById('root')
);

registerServiceWorker();
