# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src(:self)
    policy.base_uri(:self)
    policy.font_src(:self,
                    :data,
                    "https://cdn.jsdelivr.net")
    policy.frame_ancestors(:self)
    policy.frame_src(:self,
                     "https://www.geogebra.org",
                     "https://*.geogebra.org")
    policy.img_src(:self,
                   :blob,
                   :data,
                   :https)
    policy.media_src(:self,
                     :blob)
    policy.object_src(:none)
    policy.script_src(:self,
                      :unsafe_inline,
                      :wasm_unsafe_eval,
                      "https://cdn.jsdelivr.net",
                      "https://cdnjs.cloudflare.com",
                      "https://www.geogebra.org",
                      "https://*.geogebra.org")
    policy.style_src(:self,
                     :unsafe_inline,
                     "https://cdn.jsdelivr.net",
                     "https://cdnjs.cloudflare.com")
    policy.connect_src(:self,
                       "https://cdn.jsdelivr.net",
                       "https://cdnjs.cloudflare.com",
                       "https://www.geogebra.org",
                       "https://*.geogebra.org")
    policy.form_action(:self)

    if Rails.env.development?
      vite_host = ViteRuby.config.host_with_port
      vite_port = vite_host.split(":").last
      vite_http_sources = [
        "http://#{vite_host}",
        "http://localhost:#{vite_port}",
        "http://127.0.0.1:#{vite_port}"
      ].uniq
      vite_ws_sources = [
        "ws://#{vite_host}",
        "ws://localhost:#{vite_port}",
        "ws://127.0.0.1:#{vite_port}"
      ].uniq

      policy.script_src(*policy.script_src,
                        :unsafe_eval,
                        *vite_http_sources)
      policy.font_src(*policy.font_src,
                      *vite_http_sources)
      policy.img_src(*policy.img_src,
                     *vite_http_sources)
      policy.style_src(*policy.style_src,
                       *vite_http_sources)
      policy.connect_src(*policy.connect_src,
                         *vite_http_sources,
                         *vite_ws_sources)
    end
  end

  # Report-only logs every violation to the browser console but blocks nothing, so
  # the policy can be validated by clicking through the app. Toggled by env so the
  # switch to enforcing (and an instant rollback under real traffic) needs no rebuild:
  # CSP_REPORT_ONLY=false enforces. Defaults to report-only.
  config.content_security_policy_report_only =
    ENV.fetch("CSP_REPORT_ONLY", "true") == "true"
end
