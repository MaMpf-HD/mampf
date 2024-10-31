RSpec::Matchers.define(:include_in_html_body) do |expected|
  # ignore \r and \n in the comparison
  mail_body_stripped = ->(mail) { mail.html_part.body.decoded.gsub(/[\r\n]/, "") }
  expected_stripped = expected.gsub(/[\r\n]/, "")

  match do |mail|
    mail_body_stripped.call(mail).include?(expected_stripped)
  end

  failure_message do |mail|
    "Expected that the HTML body would include:\n#{expected_stripped}\n" \
      + "But got:\n#{mail_body_stripped.call(mail)}"
  end
end
