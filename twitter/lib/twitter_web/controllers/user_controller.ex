defmodule TwitterWeb.UserController do
  use TwitterWeb, :controller

  def create(conn, _params) do
    render conn, "new.html", user_id: "signup"
  end
end
