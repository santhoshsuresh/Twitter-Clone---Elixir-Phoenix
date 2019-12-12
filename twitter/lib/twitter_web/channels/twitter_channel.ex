defmodule TwitterWeb.TwitterChannel do
  use TwitterWeb, :channel

  def join("twitter:" <> user_id, _params, socket) do
    {:ok, %{channel: "twiiter:#{user_id}"}, assign(socket, :user_id, user_id)}
  end

  def handle_in("login", %{"username" => uname, "password" => password}, socket) do
    # user_id = socket.assigns[:user_id]
    user_exists = :ets.lookup(:user, uname)
    pass = (if user_exists ==[] do
        ""
      else
        [{_u,p,_e}] = user_exists
        p
      end)
    result = (if password=="" or pass != password do
        "Incorrect Username or Password"
      else
        uname
      end)

    push(socket, "Login_result", %{result: result})
    # broadcast!(socket, "twitter:#{user_id}:new_message",  %{"username" => uname, "password" => password})
    {:reply, :ok, socket}
  end

  def handle_in("createuser", %{"username" => uname, "password" => password, "email" => email}, socket) do
    user_exists = :ets.lookup(:user, uname)
    if(user_exists == []) do
      :ets.insert_new(:user, {uname, password, email});
    else
      push(socket, "Signup_invalid", %{error: true})
    end
    {:reply, :ok, socket}
  end

end
