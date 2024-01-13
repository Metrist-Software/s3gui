defmodule S3GuiServer.Samly do
  def refresh_idps() do
    idps =
      S3GuiData.Accounts.list_identity_providers()
      |> Enum.filter(&(not is_nil(&1.metadata)))
      |> Enum.map(fn idp -> %{
        id: idp.id,
        sp_id: "s3gui-sp",
        base_url: "#{S3GuiWeb.Endpoint.url()}/sso",
        metadata: idp.metadata,
        sign_requests: idp.sign_requests,
        sign_metadata: idp.sign_metadata,
        signed_assertion_in_resp: idp.signed_assertion_in_resp,
        signed_envelopes_in_resp: idp.signed_envelopes_in_resp,
        allow_idp_initiated_flow: true,
        allowed_target_urls: [""],
        pre_session_create_pipeline: S3GuiWeb.SamlPipline
      }
      end
      )

    sps = Application.get_env(:samly, Samly.Provider)[:service_providers]

    Application.put_env(:samly, Samly.Provider,
      identity_providers: idps,
      service_providers: sps,
      idp_id_from: :path_segment
    )
    Samly.Provider.refresh_providers()

  end
end
