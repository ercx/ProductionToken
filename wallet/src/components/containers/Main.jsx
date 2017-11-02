import React from 'react';
import PropTypes from 'prop-types';

import { withStyles } from 'material-ui/styles';
import { compose } from 'lib/util';


const styleSheet = theme => ({
  main: {
    backgroundColor: theme.palette.background.default,
    height: Screen.height,
    width: Screen.width,
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'column'
  }
})

const Main = ({ classes, children }) => (
  <div className={classes.main}>{children}</div>
);

Main.propTypes = {
  classes: PropTypes.object.isRequired
};

export default compose(
  withStyles(styleSheet)
)(Main);