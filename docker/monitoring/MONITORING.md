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

1. Visit http://localhost:2345/d/adzzdvc/mampf-general-overview

2. Or Manually: Go on localhost:2345, login with the credentials above, press on "Dashboards", then on the arrow to the right of "Mampf Dashboards" and then on "MaMpf General Overview"


### How to edit a dashboard

1. Head to your dashboard (e.g. http://localhost:2345/d/adzzdvc/mampf-general-overview)

2. Click `Edit` in the top right corner

3. Drag around or Add Visualizations as you wish
  a. If you query a system metric and don't care about differentiating sessions/pids:
      - In the top right corner of your panel click on the drop-down menu
      - Select `Edit`
      - In your query row switch to `Code` view
      - Change you Query to `sum by (job, role) (your_system_metric)`
      This Groups our data by job and role, meaning all data from the master process
      (and from indexed worker processes) is aggregated
      - If your legend includes different tags, include them in the grouping

4. Click `Save dashboard` in the top right corner

5. `Copy JSON to Clipboard` or `Save JSON to file`

6. Open `/workspaces/mampf/docker/monitoring/grafana/dashboards` and either paste into or replace existing JSON file (e.g. monitoring/grafana/dashboards/mampf-overview.json)

### How to add a contact point

Edit the file `.../docker/monitoring/grafana/provisioning/alerting/contact_points.yml` and add a new block like:

```yaml
- orgId: 1
  name: NameOfReceiver
  receivers:
    - uid: a_unique_technical_name
      type: email
      settings:
        addresses: new@mail.address
```


Fill out the lines `name:`, `uid:`, and `addresses:` accordingly.
To add multiple email addresses, separate them with commas in the `addresses` field (e.g., `addresses: user1@mail.com, user2@mail.com`).

To ensure the new address receives alert emails, one has to select this contact point in the alert rule configuration or update existing alert rules to use it. Another option would be to update the Notification Policies to route specific alerts to this new contact point.


### How to edit alerts

Here only the manual way is explained. One can also add another rule to `.../docker/monitoring/grafana/provisioning/alerting/alert_rules.yml`.

1. Go to http://localhost:2345/alerting/list or navigate via the menu: Alerting → Alert rules.
2. Press the blue button `New alert rule`.
3. Define the name, query, and alert condition for the new alert rule.
4. Add the folder the dashboard is in and set the evaluation behavior, which defines how long the condition must be true before sending an alert. Here, a new evaluation group has to be added and later changed to an existing one in step 8 if needed.
5. Choose a contact point or create one (as explained above) and configure the notification message.
6. Click on `save` at the bottom.
7. To export the alert, click on `More`, then on `Export`, and choose `With modifications`.
8. If needed, change the Evaluation group, then at the bottom press `Export` and `Copy code`.
9. Paste the code in the file `.../docker/monitoring/grafana/provisioning/alerting/alert_rules.yml` under the existing alerts. Remove the redundant headers `apiVersion` and `groups`, and ensure that the `- uid:` lines are aligned under the previous rules.
10. After editing any .yml files, the container has to be restarted to apply the changes.

### Metrics not yet added

- Change of registered users, deleted users, signups
- Sidekiq metrics