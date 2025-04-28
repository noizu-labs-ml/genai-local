
defmodule GenAI.Provider.LocalLLama.Models do
  def priv(path, options \\ nil) do
    priv_dir = cond do
      x = options[:priv_dir] -> {:ok, x}
      otp_app = options[:otp_app] ->
        case :code.priv_dir(otp_app) do
          x = {:error, _} -> x
          x -> {:ok, List.to_string(x)}
        end
      :else ->
        otp_app = Application.get_env(:genai_local, :local_llama)[:otp_app]
        case :code.priv_dir(otp_app) do
          x = {:error, _} -> x
          x -> {:ok, List.to_string(x)}
        end
    end
    with {:ok, pd} <- priv_dir do
      p = pd <> "/" <> path
      if File.exists?(p) do
        with {:ok, mref} <- ExLLama.load_model(p) do
          %GenAI.ExternalModel{
            resource_handle: UUID.uuid4(),
            manager: GenAI.Provider.LocalLLamaManager,
            external: mref,
            provider: GenAI.Provider.LocalLLama,
            details: %{}, # encoding details, formatter, etc.
          }
          # TODO extend nif to allow for a preload/not yet loaded wrapper
          # That can be populated at runtime using the model_name field.
        end
      
      else
        {:error, "Model not found"}
      end
    end
  end
end