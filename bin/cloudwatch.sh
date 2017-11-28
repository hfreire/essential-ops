#!/usr/bin/env bash

HOSTNAME=${HOSTNAME:-$(cat /etc/hostname)}
[ -z "$HOSTNAME" ] && exit 1

CONFIG_DIR=${CONFIG_DIR:-"/etc/cloudwatch"}
[ -z "$CONFIG_DIR" ] && exit 1

AWS_CLI=$(which aws)
[ -z "$AWS_CLI" ] && exit 1

collect_metric_data () {
  local config_dir="$1"
  local metric_data=

  for file in $(ls $config_dir);
  do
    data=$($config_dir/$file)

    for line in $data; do
      if [ -n "$metric_data" ]; then
        metric_data="$metric_data,"
      fi

      metric_name=${line%%;*}
      metric_name_and_unit=${line%;*}
      unit=${metric_name_and_unit##*;}
      value=${line##*;}

      part="{\"MetricName\": \"$metric_name\", \"Dimensions\": [ {\"Name\": \"Hostname\", \"Value\": \"$HOSTNAME\"} ], \"Value\": $value, \"Unit\": \"$unit\"}"

      metric_data="$metric_data$part"
    done
  done

  echo "[ $metric_data ]"
}

put_metric_data () {
  local metric_data="$1"

  $($AWS_CLI cloudwatch put-metric-data --namespace "LinuxServers" --metric-data "$metric_data")
}

metric_data=$(collect_metric_data $CONFIG_DIR)
put_metric_data "$metric_data"
