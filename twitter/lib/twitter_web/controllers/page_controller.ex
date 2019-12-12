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

    data = :ets.tab2list(:user)
    userslist = Enum.map(data, fn user ->
      {u,_,_} = user
      u
    end)

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

end

