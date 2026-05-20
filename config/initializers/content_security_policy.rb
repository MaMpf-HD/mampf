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
                      "https://cdn.jsdelivr.net",
                      "https://cdnjs.cloudflare.com",
                      "https://www.geogebra.org",
                      "https://*.geogebra.org")
    policy.style_src(:self,
                     :unsafe_inline,
                     "https://cdn.jsdelivr.net",
                     "https://cdnjs.cloudflare.com")
    policy.connect_src(:self,
                       "https://www.geogebra.org",
                       "https://*.geogebra.org")
    policy.form_action(:self)

    if Rails.env.development?
      vite_host = ViteRuby.config.host_with_port

      policy.script_src(*policy.script_src,
                        :unsafe_eval,
                        "http://#{vite_host}")
      policy.style_src(*policy.style_src,
                       "http://#{vite_host}")
      policy.connect_src(*policy.connect_src,
                         "http://#{vite_host}",
                         "ws://#{vite_host}")
    end
  end

  config.content_security_policy_nonce_generator = lambda { |request|
    request.session.id.to_s
  }
  config.content_security_policy_nonce_directives = ["script-src"]
  config.content_security_policy_report_only = true
end
