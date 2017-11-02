import {
  APP_LOADING_START,
  APP_LOADING_END,
  APP_LOADING_TOGGLE
} from 'constants/action';

export const loading = {

  start(){
    return {
      type: APP_LOADING_START
    }
  },

  end(){
    return {
      type: APP_LOADING_END
    }
  },

  toggle(){
    return {
      type: APP_LOADING_TOGGLE
    }
  }

};