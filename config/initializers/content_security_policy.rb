# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src(:self)
    policy.base_uri(:self)
    policy.font_src(:self,
                    :data)
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
    # ALTCHA (the registration captcha) runs its proof-of-work in Web Workers
    # created from blob: URLs. Without an explicit worker-src the browser falls back
    # to script-src, which does not allow blob:. Allow it for workers only.
    policy.worker_src(:self, :blob)
    policy.script_src(:self,
                      "https://www.geogebra.org",
                      "https://*.geogebra.org")
    policy.style_src(:self,
                     :unsafe_inline)
    policy.connect_src(:self,
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

    # The servers of the browser tests use Vite's dev server as well. A page
    # opens its socket for live updates on the host the browser knows the app
    # by, so the socket is allowed on Vite's port of any host.
    if Rails.env.test?
      policy.connect_src(*policy.connect_src,
                         "ws://*:#{ViteRuby.config.port}")
    end
  end

  # Report-only logs every violation to the browser console but blocks nothing, so
  # the policy can be validated by clicking through the app. Toggled by env so the
  # switch to enforcing (and an instant rollback under real traffic) needs no rebuild:
  # CSP_REPORT_ONLY=false enforces. Defaults to report-only, except in tests:
  # there a script that the policy blocks should fail the test.
  config.content_security_policy_report_only =
    ENV.fetch("CSP_REPORT_ONLY", Rails.env.test? ? "false" : "true") == "true"

  # An inline script runs only if it carries this nonce. A page also gets
  # scripts from later requests, in markup that jQuery inserts or that Turbo
  # renders into the document it keeps, so the nonce stays the same for a
  # session. Signing in starts a new session without a new document: until the
  # next full page load only the script answers that rails-ujs and jQuery
  # evaluate run there, since they take the nonce from the document.
  config.content_security_policy_nonce_generator = lambda do |request|
    request.session.id.to_s.presence || SecureRandom.base64(16)
  end
  # Only for scripts. A `style` attribute cannot carry a nonce, and a nonce in
  # `style-src` would switch `unsafe-inline` off for the attributes too.
  config.content_security_policy_nonce_directives = ["script-src"]
end
