# Notification channel – email
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "${var.app_name}-${var.environment}-email-alerts"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# Alert: backend request error rate > 5 % over 5 minutes (MQL ratio)
resource "google_monitoring_alert_policy" "backend_error_rate" {
  project      = var.project_id
  display_name = "${var.app_name}-${var.environment}: Backend 5xx Error Rate > 5%"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Cloud Run backend 5xx error rate > 5% of total requests"

    condition_monitoring_query_language {
      query    = <<-EOT
        fetch cloud_run_revision
        | metric 'run.googleapis.com/request_count'
        | filter resource.service_name == '${var.backend_service_name}'
        | align rate(1m)
        | group_by [resource.service_name], [
            total: sum(val()),
            errors: sum(if(metric.response_code_class == '5xx', val(), 0))
          ]
        | value [error_ratio: div(errors, if(total > 0, total, 1))]
        | condition error_ratio > 0.05
      EOT
      duration = "300s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
  }

  documentation {
    content   = "Backend 5xx error rate has exceeded 5% of total requests over the last 5 minutes. Investigate Cloud Run logs."
    mime_type = "text/markdown"
  }
}

# Alert: backend request latency p99 > 3 s
resource "google_monitoring_alert_policy" "backend_latency" {
  project      = var.project_id
  display_name = "${var.app_name}-${var.environment}: Backend High Latency (p99 > 3s)"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Cloud Run backend p99 latency > 3 s"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.backend_service_name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3000
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
  }

  documentation {
    content   = "Backend p99 latency has exceeded 3 seconds. Investigate application performance or resource limits."
    mime_type = "text/markdown"
  }
}

# Log-based metric: application errors
resource "google_logging_metric" "app_errors" {
  project = var.project_id
  name    = "${var.app_name}-${var.environment}-app-errors"
  filter  = "resource.type=\"cloud_run_revision\" AND severity>=ERROR AND resource.labels.service_name=\"${var.backend_service_name}\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "${var.app_name} application errors"
  }
}

# Alert on log-based error metric
resource "google_monitoring_alert_policy" "app_error_logs" {
  project      = var.project_id
  display_name = "${var.app_name}-${var.environment}: Application Error Logs"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Application error log count > 10 in 5 min"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.app_errors.name}\" AND resource.type=\"cloud_run_revision\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content   = "More than 10 ERROR-level log entries detected in the last 5 minutes."
    mime_type = "text/markdown"
  }
}
