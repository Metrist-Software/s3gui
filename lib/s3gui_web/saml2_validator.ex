defmodule S3GuiWeb.Saml2Validator do
  require Logger

  def validate(path_to_xml, path_to_schema) do
    path = System.find_executable("xmllint")

    {output, exit_code} = System.cmd(path, ["--schema", "#{path_to_schema}", "#{path_to_xml}", "--noent", "--nonet", "--noout"], stderr_to_stdout: true)
    Logger.info("Exit code #{exit_code}. Output #{inspect output}")
    exit_code == 0
  end

  def validate_string(xml, path_to_schema) do
    cmd = System.find_executable("xmllint")
    {_, %{status: status_code}} = Rambo.run(cmd, ["--schema", "#{path_to_schema}", "--noent", "--nonet", "--noout", "-"], in: xml)
    status_code == 0
  end
end
