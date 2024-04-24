defmodule Harness.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HarnessWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Harness.PubSub},
      # Start Finch
      {Finch, name: Harness.Finch},
      # Start the Endpoint (http/https)
      HarnessWeb.Endpoint,

      # Delayed servings config. Select the model to host.
      #
      # Client must use the serving name specified here.
      # -----

      # {Harness.DelayedServing,
      #  serving_name: Llama2ChatModel,
      #  serving_fn: fn -> Harness.Llama2Chat.serving() end},

      # {Harness.DelayedServing,
      #  serving_name: ZephyrModel, serving_fn: fn -> Harness.Zephyr.serving() end},

      # {Harness.DelayedServing,
      #  serving_name: MistralInstructModel, serving_fn: fn -> Harness.MistralInstruct.serving() end}
    ]

    Harness.log_node_name()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Harness.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HarnessWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
