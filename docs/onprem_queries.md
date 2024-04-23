## CPU utilization

```
Perf
| where ObjectName == "Processor Information" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| join kind=inner ( 
    Perf
    | where ObjectName == "Processor Information" and CounterName == "% Processor Time"
    | where InstanceName == "_Total"
    | summarize avg(CounterValue) by Computer
    | order by avg_CounterValue desc 
    | take 5
) on $left.Computer == $right.Computer
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 
```

## Disk usage

```
Perf
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| where strlen(InstanceName) < 5 and InstanceName endswith ":"
| summarize arg_max(TimeGenerated, *) by Computer, InstanceName
| project Status = iif(CounterValue > 50, "Healty", iif(CounterValue < 15, "Critical", "Warning"))
| summarize count() by Status
| render piechart 
```

## Disk usage - Critical disks (less than 15% free space available)
```
Perf
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| where strlen(InstanceName) < 5 and InstanceName endswith ":"
| summarize arg_max(TimeGenerated, *) by Computer, InstanceName
| project Computer, Disk = InstanceName, Value = CounterValue, Status = iif(CounterValue > 50, "Healty", iif(CounterValue < 10, "Critical", "Warning"))
| where Status == "Critical"
```