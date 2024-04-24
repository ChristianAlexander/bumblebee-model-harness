defmodule Harness do
  require Logger

  @moduledoc """
  Harness keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def log_node_name do
    Logger.info("Node started with name #{Node.self()}")
  end
end
