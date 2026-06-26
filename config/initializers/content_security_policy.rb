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

  # Staging rollout: run the policy in report-only mode first. The browser logs
  # every violation to its DevTools console but blocks nothing, so you can click
  # through staging and watch for warnings. Once the console stays clean, remove
  # this line to switch the policy to enforcing.
  config.content_security_policy_report_only = true
end
