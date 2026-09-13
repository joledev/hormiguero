defmodule HormigueroWeb.PageController do
  use HormigueroWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
