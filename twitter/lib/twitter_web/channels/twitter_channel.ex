defmodule TwitterWeb.TwitterChannel do
  use TwitterWeb, :channel

  def join("twitter:" <> user_id, _params, socket) do
    {:ok, %{channel: "twiiter:#{user_id}"}, assign(socket, :user_id, user_id)}
  end

  def handle_in("login", %{"username" => uname, "password" => password}, socket) do
    # user_id = socket.assigns[:user_id]
    user_exists = :ets.lookup(:user, uname)

    pass =
      if user_exists == [] do
        ""
      else
        [{_u, p, _e}] = user_exists
        p
      end

    result =
      if password == "" or pass != password do
        "Incorrect Username or Password"
      else
        uname
      end

    push(socket, "Login_result", %{result: result})


    # broadcast!(socket, "twitter:#{user_id}:new_message",  %{"username" => uname, "password" => password})
    {:reply, :ok, socket}
  end

  def handle_in(
        "createuser",
        %{"username" => uname, "password" => password, "email" => email},
        socket
      ) do
    user_exists = :ets.lookup(:user, uname)

    if(user_exists == []) do
      :ets.insert_new(:user, {uname, password, email})
      push(socket, "Signup_Result", %{error: false})

      socket = :ets.tab2list(:user_sockets)
      if socket!= [] do
        Enum.each(socket, fn x ->
          {uname, socket} = x
          retrievefollowers(uname, socket)
        end)
      end

    else
      push(socket, "Signup_Result", %{error: true})
    end

    {:reply, :ok, socket}
  end

  def handle_in("gettweets", %{"username" => uname}, socket) do
    :ets.insert(:user_sockets, {uname, socket})
    gettweets(uname, socket)
    {:reply, :ok, socket}
  end

  def gettweets(uname, socket) do
    user_exists = :ets.lookup(:user, uname)

    if(user_exists != []) do
      u_t = :ets.lookup(:user_tweet, uname)

      if(u_t != []) do
        fav = :ets.lookup(:user_fav, uname)

        fav_list =
          if fav != [] do
            [{_, favlist}] = fav
            favlist
          else
            []
          end

        rt = :ets.lookup(:user_retweet, uname)

        rt_list =
          if rt != [] do
            [{_, rtlist}] = rt
            rtlist
          else
            []
          end

        [{_, tweetlist}] = u_t

        tweets =
          Enum.map(tweetlist, fn t ->
            [t_id, who] = t
            [{_, message}] = :ets.lookup(:tweet, t_id)

            result =
              if t_id in fav_list do
                [t_id, who, message, 1]
              else
                [t_id, who, message, 0]
              end

            result =
              if t_id in rt_list do
                result ++ [1]
              else
                result ++ [0]
              end
          end)

        desc_tweets = Enum.reverse(tweets)
        push(socket, "receive_tweets", %{tweets: desc_tweets})
      end
    end
  end

  def handle_in("getfollowers", %{"username" => uname}, socket) do
    retrievefollowers(uname, socket)
    {:reply, :ok, socket}
  end

  def retrievefollowers(uname, socket) do
    user_exists = :ets.lookup(:user, uname)

    if user_exists != [] do
      followerslist = get_followers(uname)
      followerslist = Enum.uniq(followerslist)
      IO.inspect(followerslist)
      rest_userlist = extractusernames(uname, followerslist)
      rest_userlist = Enum.uniq(rest_userlist)
      IO.inspect(rest_userlist)

      push(socket, "receive_followers", %{
        followerslist: followerslist,
        rest_userlist: rest_userlist
      })
    end
  end

  def get_followers(user) do
    followers = :ets.lookup(:user_follower, user)

    if(followers != []) do
      [{_, lst}] = followers
      Enum.sort(lst)
    else
      []
    end
  end

  def extractusernames(username, followerslist) do
    data = :ets.tab2list(:user)

    userslist =
      Enum.map(data, fn user ->
        {u, _, _} = user

        if(u not in followerslist and u != username) do
          u
        end
      end)

    Enum.filter(userslist, & &1)
  end

  def handle_in("addfollower", %{"username" => uname, "follower" => fol}, socket) do
    fol_list = get_followers(uname)

    if(fol_list != []) do
      lst = fol_list ++ [fol]
      :ets.insert(:user_follower, {uname, lst})
    else
      :ets.insert(:user_follower, {uname, [fol]})
    end

    retrievefollowers(uname, socket)

    followinglist = getfollowinglist(fol)

    if(followinglist != []) do
      lst = followinglist ++ [uname]
      :ets.insert(:user_following, {fol, lst})
    else
      :ets.insert(:user_following, {fol, [uname]})
    end

    {:reply, :ok, socket}
  end

  def handle_in("unfollower", %{"username" => uname, "unfollower" => fol}, socket) do
    fol_list = get_followers(uname)

    if(fol_list != []) do
      lst = fol_list -- [fol]
      :ets.insert(:user_follower, {uname, lst})
    end

    retrievefollowers(uname, socket)

    followinglist = getfollowinglist(fol)

    if(followinglist != []) do
      lst = followinglist -- [uname]
      :ets.insert(:user_following, {fol, lst})
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "tweetaction",
        %{"tweetid" => id, "username" => uname, "action" => action},
        socket
      ) do
    tid = String.to_integer(id)

    if action == "like" do
      fav = :ets.lookup(:user_fav, uname)

      if fav != [] do
        [{_, favlist}] = fav

        if(tid not in favlist) do
          favlist = favlist ++ [tid]
          :ets.insert(:user_fav, {uname, favlist})
        end
        else
          :ets.insert(:user_fav, {uname, [tid]})
        end
    else
      foll_list = getfollowinglist(uname)
      addretweet(uname, tid)

      whom = uname <> " retweeted this"
      [{_, message}] = :ets.lookup(:tweet, tid)
      tc = SocialParser.extract(message, [:hashtags, :mentions])
      men = tc[:mentions]
      if men != nil do
        Enum.each(men, fn x ->
          user = String.slice(x, 1..-1)
          assigntweets(whom, user, tid)
        end)
      end

      Enum.each(foll_list, fn x ->
        who = uname <> " retweeted this"
        t_id = String.to_integer(id)
        assigntweets(who, x, t_id)
      end)
    end

    gettweets(uname, socket)
    {:reply, :ok, socket}
  end

  def addretweet(x, id) do
    r_t = :ets.lookup(:user_retweet, x)

    if r_t != [] do
      [{_, tweet_list}] = r_t
      tweet_list = tweet_list ++ [id]
      message = {x, tweet_list}
      :ets.insert(:user_retweet, message)
    else
      r_t = [id]
      message = {x, r_t}
      :ets.insert(:user_retweet, message)
    end

    who = "You retweeted this"
    assigntweets(who, x, id)
  end

  def getfollowinglist(u) do
    followinglist = :ets.lookup(:user_following, u)

    if followinglist != [] do
      [{_, lst}] = followinglist
      lst
    else
      []
    end
  end

  def assigntweets(who, u, id) do
    u_t = :ets.lookup(:user_tweet, u)

    if u_t != [] do
      [{_, tweet_list}] = u_t
      tweet_list = tweet_list ++ [[id, who]]
      message = {u, tweet_list}
      :ets.insert(:user_tweet, message)
    else
      u_t = [[id, who]]
      message = {u, u_t}
      :ets.insert(:user_tweet, message)
    end

    socket = :ets.lookup(:user_sockets, u)

    if socket != [] do
      [{_, soc}] = socket
      gettweets(u, soc)
    end
  end

  def handle_in("getuserdetails", %{"username" => uname}, socket) do
    [{name, pass, email}] = :ets.lookup(:user, uname)
    push(socket, "receive_details", %{name: name, pass: pass, email: email})
    {:reply, :ok, socket}
  end

  def handle_in("searchtweets", %{"username" => uname, "search" => search}, socket) do
    tweetcomponents = SocialParser.extract(search, [:hashtags, :mentions])
    hash_list = tweetcomponents[:hashtags]
    mention_list = tweetcomponents[:mentions]

    result = []

    hashtag =
      if(hash_list) do
        hash = Map.fetch!(tweetcomponents, :hashtags)

        tweets_ht =
          Enum.map(hash, fn x ->
            lst = :ets.lookup(:hashtag_tweet, x)

            if lst != [] do
              [{_, ht}] = :ets.lookup(:hashtag_tweet, x)
              ht
            else
              []
            end
          end)
      else
        []
      end

    mention =
      if(mention_list) do
        men = Map.fetch!(tweetcomponents, :mentions)

        tweets_men =
          Enum.map(men, fn x ->
            lst = :ets.lookup(:mention_tweet, x)

            if lst != [] do
              [{_, mn}] = :ets.lookup(:mention_tweet, x)
              mn
            else
              []
            end
          end)
      else
        []
      end

    hashtag = List.flatten(hashtag)
    mention = List.flatten(mention)

    result =
      if mention_list != nil and hash_list != nil do
        findcommontweet(hashtag, mention)
      else
        hashtag ++ mention
      end

    # result = mention ++ hashtag
    result = Enum.filter(result, & &1)

    IO.inspect(result)
    result = Enum.uniq(List.flatten(result))

    IO.inspect(result)

    searchresult =
      Enum.map(result, fn x ->
        [{_, t}] = :ets.lookup(:tweet, x)
        t
      end)

    IO.inspect(result)
    push(socket, "searchresults", %{result: searchresult})
    {:reply, :ok, socket}
  end

  def findcommontweet(hashtag, mention) do
    Enum.map(hashtag, fn x ->
      if x in mention do
        x
      else
        []
      end
    end)
  end

  def handle_in("new_tweet", %{"username" => username, "tweet" => tweet}, socket) do
    # fetch all users following the current user
    followers_list =
      if :ets.lookup(:user_following, username) != [] do
        [{_, flist}] = :ets.lookup(:user_following, username)
        flist
      else
        []
      end

    ## add tweet for self
    tweetId = addTweet2Self(username, tweet)

    Enum.map(followers_list, fn f ->
      sendTweet2Follower(username, f, tweet, tweetId)
    end)

    whom = username <> " mentioned you"
    tc = SocialParser.extract(tweet, [:hashtags, :mentions])
    men = tc[:mentions]
    if men != nil do
      Enum.each(men, fn x ->
        user = String.slice(x, 1..-1)
        assigntweets(whom, user, tweetId)
      end)
    end

    push(socket, "TweetSuccess", %{result: "success"})
    {:reply, :ok, socket}
  end

  defp sendTweet2Follower(tweeter, follower, tweet, tweetId) do
    if :ets.lookup(:user_tweet, follower) != [] do
      [{_, allfollowertweetfeeds}] = :ets.lookup(:user_tweet, follower)
      allfollowertweetfeeds = allfollowertweetfeeds ++ [[tweetId, tweeter <> " tweeted this"]]
      followerfeed = {follower, allfollowertweetfeeds}
      :ets.insert(:user_tweet, followerfeed)
    else
      allfollowertweetfeeds = [[tweetId, tweeter <> " tweeted this"]]
      followerfeed = {follower, allfollowertweetfeeds}
      :ets.insert(:user_tweet, followerfeed)
    end

    socket = :ets.lookup(:user_sockets, follower)

    if socket != [] do
      [{_, soc}] = socket
      gettweets(follower, soc)
    end
  end

  defp addTweet2Self(tweeter, tweet) do
    ## update the total tweet count
    curr_total_tweets = :ets.update_counter(:table, "Tweet count", {2, 1})

    if :ets.lookup(:user_tweet, tweeter) != [] do
      [{_, allmytweetfeeds}] = :ets.lookup(:user_tweet, tweeter)
      allmytweetfeeds = allmytweetfeeds ++ [[curr_total_tweets, "You tweeted this"]]
      myfeed = {tweeter, allmytweetfeeds}
      :ets.insert(:user_tweet, myfeed)
    else
      allmytweetfeeds = [[curr_total_tweets, "You tweeted this"]]
      myfeed = {tweeter, allmytweetfeeds}
      :ets.insert(:user_tweet, myfeed)
    end

    # add tweet to the tweets table
    :ets.insert(:tweet, {curr_total_tweets, tweet})

    IO.puts("Extracting hashtags/mentions from tweet #{inspect(tweet)}")
    tweetcomponents = SocialParser.extract(tweet, [:hashtags, :mentions])

    ## if hastags exists, add them to table
    if Map.has_key?(tweetcomponents, :hashtags) do
      addhashtag2table(curr_total_tweets, Map.get(tweetcomponents, :hashtags))
    end

    ## if mentions exists, add them to table
    if Map.has_key?(tweetcomponents, :mentions) do
      addmention2table(curr_total_tweets, Map.get(tweetcomponents, :mentions))
    end

    ## return the tweetId
    curr_total_tweets
  end

  defp addhashtag2table(tweetId, hashtaglist) do
    for hashtag <- Enum.uniq(hashtaglist) do
      # check for the existence of the hashtag in the table
      if :ets.lookup(:hashtag_tweet, hashtag) == [] do
        hashlist = [tweetId]
        inserttotable(:hashtag_tweet, {hashtag, hashlist})
      else
        [{_, hashlist}] = :ets.lookup(:hashtag_tweet, hashtag)
        hashlist = hashlist ++ [tweetId]
        inserttotable(:hashtag_tweet, {hashtag, hashlist})
      end
    end
  end

  defp addmention2table(tweetId, mentionlist) do
    for mention <- Enum.uniq(mentionlist) do
      if :ets.lookup(:mention_tweet, mention) == [] do
        mentionlist = [tweetId]
        inserttotable(:mention_tweet, {mention, mentionlist})
      else
        [{_, mentionlist}] = :ets.lookup(:mention_tweet, mention)
        mentionlist = mentionlist ++ [tweetId]
        inserttotable(:mention_tweet, {mention, mentionlist})
      end
    end
  end

  defp inserttotable(table, tuple) do
    :ets.insert(table, tuple)
  end
end
