# Monitoring

### Credentials

Standard Grafana Login
  Username: admin
  Password: admin

Standard MaMpf Login
  Username: admin@mampf.edu
  Password: dockermampf


### How to get to the dashboard

After `just up`:

1. http://localhost:2345/d/adzzdvc/mampf-general-overview

2. Manually: Go on localhost:2345, login with the credentials above, press on "Dashboards", then on the arrow to the right of "Local" and then on "MaMpf General Overview"

### TODO

- rename users to registered users
- add online users
- Mimir Database
- add other metrics:
    - http metrics
    - request duration
    - alerts
    - error rate
    - signups...
    - sidekiq
    - ...
-  Node exporter?