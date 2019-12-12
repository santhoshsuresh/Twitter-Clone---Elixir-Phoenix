defmodule TwitterWeb.TweetController do
  use TwitterWeb, :controller

  def home(conn, %{"user" => user}) do
    user_exists = :ets.lookup(:user, user)
    if user_exists != [] do
      content = get_tweets(user)
      render conn, "home.html", user: user, tweets: content
    else
      conn
      |> put_flash(:error, "User doesnt exist")
      |> redirect(external: "/")
    end
  end

  def get_tweets(user) do
    tweets_ids = :ets.lookup(:user_tweet, user)
    if tweets_ids == [] do
      []
    else
      ord_tweets = Enum.sort(tweets_ids, &(&1 >= &2))
      Enum.each(ord_tweets, fn tweet ->
        :ets.lookup(:tweet, tweet)
      end)
    end
  end

  def followers(conn, %{"user" => user}) do
    user_exists = :ets.lookup(:user, user)
    if user_exists != [] do
      followerslist = get_followers(user)
      rest_userlist = extractusernames(user, followerslist)
      render conn, "followers.html", user: user, list: rest_userlist, followerslist: followerslist
    else
      conn
      |> put_flash(:error, "User doesnt exist")
      |> redirect(external: "/")
    end
  end

  def get_followers(user) do
    followers = :ets.lookup(:user_following, user)
    Enum.sort(followers)
  end

  def extractusernames(username, followerslist) do
    data = :ets.tab2list(:user) ++ [username]
    userslist = Enum.map(data, fn user ->
      {u,_,_} = user
      if(u not in followerslist) do
        u
      end
    end)
    Enum.filter(userslist, & &1)
  end

end
