defmodule GenAI.Provider.LocalLLama do
  @moduledoc """
  This module implements the GenAI provider for Local AI.
  """
  use GenAI.InferenceProviderBehaviour
  

  @doc """
  Retrieves a list of available Local models.

  This function calls the Local API to retrieve a list of models and returns them as a list of `GenAI.Model` structs.
  """
  def models(settings \\ [])
  def models(settings) do
    GenAI.Provider.LocalLLamaManager.models(settings)
  end
  
  
  
  def do_run(session, context, options \\ nil) do
    with {:ok, {model = %{external: runner}, session}} <- GenAI.ThreadProtocol.effective_model(session, context, options),
         {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model),
         {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         {:ok, {effective, session}} <-
           effective_settings(model, session, context, options),
         {:ok, {tools, session}} <-
           GenAI.ThreadProtocol.effective_tools(session, model, context, options),
         {:ok, {messages, session}} <-
           GenAI.ThreadProtocol.effective_messages(session, model, context, options) do
      # Build Request
      with {:ok, {req_body, session}} <-
             request_body(model, messages, tools, effective, session, context, options)
        do
        with {:ok, completion = %GenAI.ChatCompletion{}} <- ExLLama.chat_completion(runner, messages, effective.settings) do
          {:ok, {%GenAI.ChatCompletion{completion| provider: provider}, session}}
        end
      end
    end
  end
end
