defmodule TwitterWeb.PageController do
  use TwitterWeb, :controller

  def index(conn, _params) do
    render conn, "index.html", user: "login"
  end

  def admin(conn, _params) do
    data = :ets.tab2list(:user)
    userslist = Enum.map(data, fn user ->
      {u,_,_} = user
      u
    end)
    render conn, "admin.html", user: "admin", list: userslist
  end

  def admincreate(conn, %{"count" => count}) do
    ucount = String.to_integer(count)
    if(is_integer(ucount) and count>0) do
      Enum.each(1..ucount, fn _x ->
        uname = generateRandomUsername()
        password = "password"
        email = uname <> "@twitter.com"
        :ets.insert_new(:user, {uname, password, email});
      end)
    end

    userslist = getusersnames()
    assignfollowers(userslist)
    sendtweet(userslist)

    if count != "" do
      conn
      |> put_flash(:info, count <> " Users created")
      |> render("admin.html", user: "admin", list: userslist)
    else
      render(conn, "admin.html", user: "admin", list: userslist)
    end
  end

  defp generateRandomUsername(length \\ 10) do
    commstr="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    generateRandomString(length, commstr)
  end

  defp generateRandomString(length, commstr) do
    list = commstr |> String.split("", trim: true) |> Enum.shuffle
    1..length |> Enum.reduce([], fn(_, acc) -> [Enum.random(list) | acc] end) |> Enum.join("")
  end

  def getusersnames do
    data = :ets.tab2list(:user)
    Enum.map(data, fn user ->
      {u,_,_} = user
      u
    end)
  end

  def assignfollowers(userlist) do
    count = div(Enum.count(userlist),2)
    Enum.each(userlist, fn u ->
      neighbourlist = userlist -- [u]
      followerlist = Enum.take_random(neighbourlist, count)
      :ets.insert(:user_follower, {u, followerlist})
      Enum.each(followerlist, fn x ->
        f = :ets.lookup(:user_following, x)
        if f != [] do
          [{_, lst}] = f
          new_lst = lst ++ [u]
          :ets.insert(:user_following, {x, new_lst})
        else
          :ets.insert(:user_following, {x, [u]})
        end
      end)
    end)
  end

  def sendtweet(userlist) do
    Enum.each(userlist , fn u ->
      followinglist = :ets.lookup(:user_following, u)
      if followinglist != [] do
        [{_, lst}] = followinglist
        tweet = generaterandomtweet(u)
        broadcasttweet(u, tweet, lst)
      end
    end)
  end

  def generaterandomtweet user do
    commstr="  abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789    "
    s = generateRandomString(10, commstr)
    userlist = getusersnames()
    randomuser = " @" <> Enum.random(userlist -- [user])
    randomhashtag = " #" <> gethashtag()
    s <> randomuser <> randomhashtag
  end

  def gethashtag do
    hashtags = ["monday", "dos", "mobile", "room", "laptop", "metoo", "keys", "bottle", "king", "fun", "youtube"]
    Enum.random(hashtags)
  end

  def broadcasttweet(u, tweet, lst) do
    who = "You tweeted this"
    cnt = :ets.update_counter(:table, "Tweet count", {2,1})
    u_t = :ets.lookup(:user_tweet, u)
    if u_t != [] do
      [{_, tweet_list}] = u_t
      tweet_list = tweet_list ++ [[cnt, who]]
      message = {u, tweet_list}
      :ets.insert(:user_tweet, message)
    else
      u_t = [[cnt, who]]
      message = {u, u_t}
      :ets.insert(:user_tweet, message)
    end

    IO.inspect u
    IO.inspect lst
    Enum.each(lst, fn f ->
      IO.puts "loop"
      IO.inspect f
      IO.inspect :ets.lookup(:user_tweet, f)
      whom = u <> " tweeted this"
      ut = :ets.lookup(:user_tweet, f)
      if ut != [] do
        [{_, tweet_list}] = ut
        tweet_list = tweet_list ++ [[cnt, whom]]
        IO.inspect tweet_list
        :ets.insert(:user_tweet, {f, tweet_list})
      else
        :ets.insert(:user_tweet, {f, [[cnt, whom]]})
      end
    end)

    :ets.insert(:tweet, {cnt, tweet})
  end
end

