import React from 'react';
import PropTypes from 'prop-types';
import { withStyles } from 'material-ui/styles';
import { compose } from 'lib/util';
import Img from 'react-image'
import Logo from 'assets/logo.svg';
import Screen from 'lib/screen';

const styleSheet = {
  main: {
    height: Screen.height,
    width: '100%',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'column'
  },
  logo: {
    width: '25%',
    maxWidth: 200,
    filter: 'invert(10%)'
  }
};

const Empty = ({ classes }) => (
  <div className={classes.main}>
    <Img src={Logo} className={`${classes.logo} rotatable`} alt="asd" />
  </div>
);


Empty.propTypes = {
  classes: PropTypes.object.isRequired
};

export default compose(
  withStyles(styleSheet)
)(Empty);