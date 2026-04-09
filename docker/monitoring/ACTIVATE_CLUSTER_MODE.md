## How to activate cluster mode in development for testing purposes:

The following 3 files need to be changed:

### /docker/development/run.sh:

To avoid debugger conflicts replace the line

```bash
RUBY_DEBUG_ENABLE=$RUBY_DEBUG_ENABLE RUBY_DEBUG_OPEN=true RUBY_DEBUG_NONSTOP=true RUBY_DEBUG_HOST="0.0.0.0" RUBY_DEBUG_PORT=13254 bundle exec bin/rails s -p "$MAMPF_PORT" -b '0.0.0.0' &> >(tee -a /workspaces/mampf/log/runtime.log)
```
with

```bash
RUBY_DEBUG_ENABLE=$RUBY_DEBUG_ENABLE RUBY_DEBUG_HOST="0.0.0.0" RUBY_DEBUG_PORT=13254 bundle exec bin/rails s -p "$MAMPF_PORT" -b '0.0.0.0' &> >(tee -a /workspaces/mampf/log/runtime.log)
```
### /docker/development/compose.yml:
Uncomment the following line to spawn 3 workers. Can be changed to a different number.

```yaml
- WEB_CONCURRENCY=3
```
### /config/puma.rb

To tell Puma to use the number of workers configured in the compose file above, uncomment the following:

```ruby
workers ENV.fetch("WEB_CONCURRENCY") { 0 }

preload_app! if ENV.fetch("WEB_CONCURRENCY", 0).to_i > 0

# Specifies the `port` that Puma will listen on to receive requests
```
