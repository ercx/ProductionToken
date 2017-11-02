import {
  NET_CONNECT_INIT,
  NET_CONNECT_START,
  NET_CONNECT_END,
  NET_CONNECT_ERROR
} from 'constants/action';

export const connect = {

  init(network){
    return {
      type: NET_CONNECT_INIT,
      network
    }
  },
  
  start(){
    return {
      type: NET_CONNECT_START
    }
  },
  
  end(){
    return {
      type: NET_CONNECT_END
    }
  },
  
  error(error){
    return {
      type: NET_CONNECT_ERROR,
      error
    }
  }
  
};