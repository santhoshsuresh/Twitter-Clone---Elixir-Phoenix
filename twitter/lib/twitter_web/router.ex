defmodule TwitterWeb.Router do
  use TwitterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/user/new", UserController, :create

    get "/home/:user", TweetController, :home
    get "/home/followers/:user", TweetController, :followers

    get "/admin", PageController, :admin
    get "/admin/:count", PageController, :admincreate
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterWeb do
  #   pipe_through :api
  # end
end
