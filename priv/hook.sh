#!/bin/bash

case "$ACTION" in
  init)
    echo "init"
    ;;
  start)
    echo "start"
    ;;
  download)
    echo "got image $ARGUMENT"
    redis-cli publish photobooth.event show
    ;;
  stop)
    echo "stop"
    ;;
  *)
    echo "unknown ACTION"
    ;;
esac

exit 0
