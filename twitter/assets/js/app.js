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

socket.connect()
let User_name = window.UserName
// Now that you are connected, you can join channels with a topic:
if (User_name) {
  let channelName = "twitter:" + User_name
  console.log(channelName)
  let channel = socket.channel(channelName, {})
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  if (document.getElementById("login")) {
    document.getElementById("login").onclick = function () {
      var username = $("#uname").val();
      var password = $("#pass").val();
      channel.push('login', { username: username, password: password });
    };
  }

  channel.on("Login_result", (message) => {
    console.log(message)
    if(message["result"] == "Incorrect Username or Password") {
      document.getElementById("alert").style.display = "block"; 
      document.getElementById("alertmsg").innerHTML = message["result"];
    } else {
      window.location.href = "/home/" + message["result"]
    }
  });

  if (document.getElementById("createuser")) {
    document.getElementById("createuser").onclick = function () {
      var username = $("#uname").val();
      var password = $("#pass").val();
      var email = $("#email").val();
      channel.push('createuser', { username: username, password: password, email: email });
    };
  }

  channel.on("Signup_invalid", (message) => {
    document.getElementById("alert").style.display = "block";    
  });

  if (document.getElementById("user_count")) {
    document.getElementById("user_count").onclick = function () {
      let count = $("#count").val();
      window.location.href = "/admin/" + count
    };
  }

  if (document.getElementById("dashboard")) {
    document.getElementById("dashboard").onclick = function () {
      window.location.href = "/home/" + User_name
    };
  }

  if (document.getElementById("followers")) {
    document.getElementById("followers").onclick = function () {
      window.location.href = "/home/followers/" + User_name
    };
  }

}
