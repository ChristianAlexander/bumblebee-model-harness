defmodule Harness.WhisperTiny do
  @moduledoc """
  Define the Whisper Tiny serving.

  - https://huggingface.co/openai/whisper-tiny
  """

  def serving(stream \\ false, chunk_num_seconds \\ 30, batch_size \\ 10) do
    whisper = {:hf, "openai/whisper-tiny", offline: false}

    {:ok, model_info} = Bumblebee.load_model(whisper, backend: EXLA.Backend)
    {:ok, featurizer} = Bumblebee.load_featurizer(whisper)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(whisper)

    {:ok, generation_config} = Bumblebee.load_generation_config(whisper)

    serving =
      Bumblebee.Audio.speech_to_text_whisper(model_info, featurizer, tokenizer, generation_config,
        chunk_num_seconds: chunk_num_seconds,
        timestamps: :segments,
        defn_options: [compiler: EXLA, lazy_transfers: :never],
        compile: [batch_size: batch_size],
        stream: stream
      )

    Nx.Serving.client_preprocessing(serving, fn
      {:file_url, url} ->
        {:ok, file_path} = download_file(url)

        {stream, info} = serving.client_preprocessing.({:file, file_path})

        {stream, [{:file_needs_disposal, file_path}] ++ Tuple.to_list(info)}

      input ->
        serving.client_preprocessing.(input)
    end)
    |> Nx.Serving.client_postprocessing(fn
      output_or_stream, [{:file_needs_disposal, file_path} | rest] ->
        File.rm(file_path)

        serving.client_postprocessing.(output_or_stream, List.to_tuple(rest))

      output_or_stream, _info ->
        serving.client_postprocessing.(output_or_stream, {})
    end)
  end

  defp download_file(url) do
    download_directory = Path.join(System.tmp_dir!(), "downloads")
    File.mkdir_p!(download_directory)

    filename = URI.parse(url) |> Map.fetch!(:path) |> Path.basename()
    out_path = Path.join(download_directory, filename)

    with {:ok, _res} <- Req.get(url: url, into: File.stream!(out_path)) do
      {:ok, out_path}
    end
  end
end
