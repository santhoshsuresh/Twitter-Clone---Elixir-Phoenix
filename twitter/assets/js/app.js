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
        document.getElementById("login").onclick = function() {
            var username = $("#uname").val();
            var password = $("#pass").val();
            channel.push('login', { username: username, password: password });
        };
    }

    channel.on("Login_result", (message) => {
        console.log(message)
        if (message["result"] == "Incorrect Username or Password") {
            document.getElementById("alert").style.display = "block";
            document.getElementById("alertmsg").innerHTML = message["result"];
        } else {
            window.location.href = "/home/" + message["result"]
        }
    });

    if (document.getElementById("createuser")) {
        document.getElementById("createuser").onclick = function() {
            var username = $("#uname").val();
            var password = $("#pass").val();
            var email = $("#email").val();
            channel.push('createuser', { username: username, password: password, email: email });
        };
    }

    channel.on("Signup_Result", (message) => {
        if (message["error"]) {
            document.getElementById("alert").style.display = "block";
        } else {
            var username = $("#uname").val();
            window.location.href = "/home/" + username
        }
    });

    if (document.getElementById("user_count")) {
        document.getElementById("user_count").onclick = function() {
            let count = $("#count").val();
            $("#user_count").attr('disabled', true);
            window.location.href = "/admin/" + count
        };
    }

    if (document.getElementById("search")) {
        document.getElementById("search").onclick = function() {
            let searchtext = $("#srchbox").val();
            channel.push('searchtweets', { username: User_name, search: searchtext });
        };
    }

    // if (document.getElementById("dashboard")) {
    //   document.getElementById("dashboard").onclick = function () {
    //     window.location.href = "/home/" + User_name
    //   };
    // }

    if (!(User_name == "login") && !(User_name == "admin") && !(User_name == "signup")) {
        channel.push('gettweets', { username: User_name });
        $(".dashboard").show();
        $(".followers").hide();
    };

    $("#dashboard").click(function() {
        if ($("#followers").hasClass("btn-primary")) {
            $("#followers").removeClass("btn-primary")
            $("#followers").addClass("btn-default")
        }
        if ($("#about").hasClass("btn-primary")) {
            $("#about").removeClass("btn-primary")
            $("#about").addClass("btn-default")
        }
        if ($("#dashboard").hasClass("btn-default")) {
            $("#dashboard").removeClass("btn-default")
            $("#dashboard").addClass("btn-primary")
        }
        $(".dashboard").show("slow");
        $(".followers").hide("slow");
        $(".about").hide("slow");
        channel.push('gettweets', { username: User_name });
    });

    $("#followers").click(function() {
        if ($("#dashboard").hasClass("btn-primary")) {
            $("#dashboard").removeClass("btn-primary")
            $("#dashboard").addClass("btn-default")
        }
        if ($("#about").hasClass("btn-primary")) {
            $("#about").removeClass("btn-primary")
            $("#about").addClass("btn-default")
        }
        if ($("#followers").hasClass("btn-default")) {
            $("#followers").removeClass("btn-default")
            $("#followers").addClass("btn-primary")
        }

        $(".dashboard").hide("slow");
        $(".followers").show("slow");
        $(".about").hide("slow");
        channel.push('getfollowers', { username: User_name });
    });

    $("#about").click(function() {
        if ($("#followers").hasClass("btn-primary")) {
            $("#followers").removeClass("btn-primary")
            $("#followers").addClass("btn-default")
        }
        if ($("#dashboard").hasClass("btn-primary")) {
            $("#dashboard").removeClass("btn-primary")
            $("#dashboard").addClass("btn-default")
        }
        if ($("#about").hasClass("btn-default")) {
            $("#about").removeClass("btn-default")
            $("#about").addClass("btn-primary")
        }
        $(".dashboard").hide("slow");
        $(".followers").hide("slow");
        $(".about").show("slow");
        channel.push('getuserdetails', { username: User_name });
    });

    channel.on("receive_tweets", (message) => {
        var tweets = message["tweets"]
        console.log(tweets)
        var html = ""
        var cardtitle = `<div class="card-body">
                    <h5 class="card-title text-capitalize font-weight-bold">`
        var cardtext = `</h5> <p class="card-text">`

        tweets.forEach(element => {
            var like = `</p> <button type="button" class="btn btn-default btn-sm" id="like` + element[0] + `">
                    <span class="glyphicon glyphicon-thumbs-up"></span> Like
                </button>;`
            var liked = `</p> <button type="button" class="btn btn-primary btn-sm" id="like` + element[0] + `">
                <span class="glyphicon glyphicon-thumbs-up"></span> Like
            </button>;`
            var isliked = like;
            if (element[3] == 1) {
                isliked = liked;
            };

            var retweet = `<button type="button" class="btn btn-default btn-sm" id="retweet` + element[0] + `" name="retweet">
                        <span class="glyphicon glyphicon-retweet"></span> Retweet
                    </button> </div>`
            var retweeted = `<button type="button" class="btn btn-default btn-sm" id="retweet` + element[0] + `" name="retweet" disabled>
                    <span class="glyphicon glyphicon-retweet"></span> Retweet
                </button> </div>`
            var is_retweeted = retweet
            if (element[4] == 1) {
                is_retweeted = retweeted;
            };
            html += cardtitle + element[1] + cardtext + element[2] + isliked + is_retweeted
        });
        document.getElementById("tweets").innerHTML = html
        document.getElementById("title").innerHTML = ""
    });

    channel.on("receive_followers", (message) => {
        let followerslist = message["followerslist"]
        let rest_userlist = message["rest_userlist"]

        var html = ""
        var startitem = `<li class="list-group-item">`
        var enditem = `</li>`
        followerslist.forEach(element => {
            var addunfoll = `<button type="button" class="btn btn-default btn-sm" style="margin: 8px;" id="unfol` + element + `"> 
      <span class="glyphicon glyphicon-minus"></span> Unfollow
                  </button>`
            html += startitem + element + addunfoll + enditem
        })
        document.getElementById("fol_list").innerHTML = html

        var listhtml = ""
        rest_userlist.forEach(element => {
            var addfol = `<button type="button" class="btn btn-primary btn-sm" style="margin: 8px;" id="usrfol` + element + `"> 
      <span class="glyphicon glyphicon-plus"></span> Follow
                  </button>`
            listhtml += startitem + element + addfol + enditem
        })
        document.getElementById("restuser_list").innerHTML = listhtml
    });

    channel.on("receive_details", (message) => {
        var html = ""
        var startitem = `<li class="list-group-item">`
        var enditem = `</li>`

        let name = startitem + `<h5 class="font-weight-bold">Name: </h5>` + message["name"] + enditem
        let pass = startitem + `<h5 class="font-weight-bold">Password: </h5>` + message["pass"] + enditem
        let mail = startitem + `<h5 class="font-weight-bold">Email: </h5>` + message["email"] + enditem

        html = name + pass + mail
        document.getElementById("details").innerHTML = html

    });

    channel.on("searchresults", (message) => {
        let searchtext = $("#srchbox").val();
        var results = message["result"]
        var html = ""
        if (results.length) {
            var cardtitle = `<div class="card-body">`
            var cardtext = `<p class="card-text">`
            var cardend = `</p> </div>`
            results.forEach(element => {
                html += cardtitle + cardtext + element + cardend
            });
            document.getElementById("tweets").innerHTML = html
            document.getElementById("title").innerHTML = "Search results for " + searchtext + " are follows"
        } else {
            document.getElementById("tweets").innerHTML = ""
            document.getElementById("title").innerHTML = "No results found for " + searchtext
        }
    });

    $(newFunction()).click(function(e) {
        var t = e.target.id
        if (t.startsWith("like")) {
            var id = t.slice(4)
            channel.push('tweetaction', { tweetid: id, username: User_name, action: "like" });
        } else if (t.startsWith("retweet")) {
            var id = t.slice(7)
            channel.push('tweetaction', { tweetid: id, username: User_name, action: "retweet" });
        } else if (t.startsWith("usrfol")) {
            var fol = t.slice(6)
            channel.push('addfollower', { username: User_name, follower: fol });
        } else if (t.startsWith("unfol")) {
            var unfol = t.slice(5)
            channel.push('unfollower', { username: User_name, unfollower: unfol });
        }
    });

    if (document.getElementById("msg-submit")) {
        document.getElementById("msg-submit").onclick = function() {
            let msg_input = document.getElementById("msg-input");
            // console.log(User_name);
            // console.log(msg_input.value);
            channel.push('new_tweet', { username: User_name, tweet: msg_input.value });
            msg_input.value = "";
        };
    }

    channel.on("TweetSuccess", (message) => {
        // window.location.reload(true);
        channel.push('gettweets', { username: User_name });
    });

}


function newFunction() {
    return "body";
}