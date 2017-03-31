#!/bin/bash

BACKUP_DIR="/media/usb/photobooth"
SLIDESHOW_DIR="priv/static/images/slideshow"
MAX_IMAGES=10

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
    # cp image to backup folder
    #cp $ARGUMENT $BACKUP_DIR/$(date +'%Y_%m_%d_%H_%M_%S').jpg
    # cp image to slideshow folder
    cp $ARGUMENT $SLIDESHOW_DIR/$(date +'%Y_%m_%d_%H_%M_%S').jpg
    # remove oldest image if to many images
    file_count=$(/bin/ls $SLIDESHOW_DIR | wc -l)
    if [ $file_count -gt $MAX_IMAGES ]; then
      rm "`/bin/ls -rt $SLIDESHOW_DIR | head -1`"
    fi
    # create photo strip
#    convert $SLIDESHOW_DIR/*.jpg +append $SLIDESHOW_DIR/strip.png
    ;;
  stop)
    echo "stop"
    ;;
  *)
    echo "unknown ACTION"
    ;;
esac

exit 0
