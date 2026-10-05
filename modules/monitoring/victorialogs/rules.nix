# vmalert LogsQL rules (type vlogs); thresholds are counts over the explicit _time window.
let
  homeserver = ''{_HOSTNAME="homeserver"}'';
  # Our own log pipeline echoes these patterns in query/error logs; don't alert on that.
  notSelf = ''-_SYSTEMD_UNIT:in("victorialogs.service", "vmalert-logs.service")'';
in {
  groups = [
    {
      name = "journal-error-rate";
      type = "vlogs";
      interval = "2m";
      rules = [
        {
          alert = "HighErrorRate";
          expr = "_time:5m ${homeserver} level:in(error, critical, alert, emerg) | stats count() as errors | filter errors:>150";
          for = "5m";
          labels.severity = "warning";
          annotations = {
            summary = "High error rate in systemd journal";
            description = "More than 150 error/critical log lines (0.5/s) over the last 5 minutes.";
          };
        }
        {
          alert = "ServiceCrashLoop";
          expr = ''_time:10m ${homeserver} ${notSelf} "Start request repeated too quickly" | stats count() as n | filter n:>3'';
          for = "0m";
          labels.severity = "critical";
          annotations = {
            summary = "Service crash loop detected on homeserver";
            description = "A systemd service is crashing repeatedly (>3 times in 10 minutes).";
          };
        }
        {
          alert = "OOMKilled";
          expr = ''_time:10m ${homeserver} ${notSelf} ~"Out of memory|oom_kill|Memory cgroup out of memory" | stats count() as n | filter n:>0'';
          for = "0m";
          labels.severity = "critical";
          annotations = {
            summary = "OOM kill detected on homeserver";
            description = "A process was killed by the OOM killer in the last 10 minutes.";
          };
        }
        {
          alert = "SshAuthFailures";
          expr = ''_time:5m {_HOSTNAME="homeserver", _SYSTEMD_UNIT="sshd.service"} ~"Failed password|Invalid user|authentication failure" | stats count() as n | filter n:>300'';
          for = "2m";
          labels.severity = "warning";
          annotations = {
            summary = "High SSH authentication failure rate";
            description = "More than 300 SSH auth failures (1/s) over 5 minutes — possible brute force attempt.";
          };
        }
        {
          alert = "DiskIoErrors";
          expr = ''_time:5m ${homeserver} ${notSelf} ~"I/O error|blk_update_request|Buffer I/O error" | stats count() as n | filter n:>0'';
          for = "0m";
          labels.severity = "critical";
          annotations = {
            summary = "Disk I/O errors detected on homeserver";
            description = "Kernel reported block device I/O errors — possible disk failure.";
          };
        }
      ];
    }
  ];
}
