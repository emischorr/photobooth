// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

document.updateState = function(state) {
  switch (state["current_state"]) {
    case "counting":
      $('#screensaver').hide();
      $('#preview').hide();
      $('#countdown').show().find('h2').html(state["count"]);
      $('#capturing').hide();
      break;
    case "capturing":
      $('#screensaver').hide();
      $('#preview').hide();
      $('#countdown').hide();
      $('#capturing').show();
      break;
    case "showing":
      $('#screensaver').hide();
      $('#preview').show().find("img").attr("src", "/images/capture.jpg");
      $('#countdown').hide();
      $('#capturing').hide();
      break;
    case "waiting":
      $('#screensaver').show();
      $('#preview').hide();
      $('#countdown').hide();
      $('#capturing').hide();
      break;
    default:
      console.log("unknown status "+state["current_state"])
  }
}
