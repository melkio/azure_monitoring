## Hyper-V Logical Processor - % Total Run Time

```
Perf
| where ObjectName == "Hyper-V Hypervisor Logical Processor" and CounterName == "% Total Run Time"
| where InstanceName == "_Total"
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 
```

## Hyper-V Dynamic Memory Balancer - Average Pressure

```
Perf
| where ObjectName == "Hyper-V Dynamic Memory Balancer" and CounterName == "Average Pressure"
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 
```

## Hyper-V Virtual Processor - % Total Run Time

```
Perf
| where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
| where InstanceName != "_Total"
| project
    Computer,
    VirtualMachine = substring(InstanceName, 0, indexof(InstanceName, ":")),
    VirtualProcessor = substring(InstanceName, indexof(InstanceName, ":") + 1),
    CounterValue
| summarize avg=avg(CounterValue) by Computer, VirtualMachine, VirtualProcessor
| summarize total=count(), over=countif(avg > 80) by Computer, VirtualMachine
| project
    Computer,
    VirtualMachine,
    value=iff(over == 0, "Healty", iff(total > over, "Warning", "Critical"))
| summarize
    healty=countif(value == "Healty"),
    warning=countif(value == "Warning"),
    critical=countif(value == "Critical")
    by Computer
| render columnchart        
```

## Hyper-V Virtual Processor - % Total Run Time

```
Perf
| where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
| where InstanceName != "_Total"
| project
    Computer,
    VirtualMachine = substring(InstanceName, 0, indexof(InstanceName, ":")),
    VirtualProcessor = substring(InstanceName, indexof(InstanceName, ":") + 1),
    CounterValue
| summarize avg=avg(CounterValue) by Computer, VirtualMachine, VirtualProcessor
| summarize total=count(), over=countif(avg > 80) by Computer, VirtualMachine
| project
    Computer,
    VirtualMachine,
    Status=iff(over == 0, "Healty", iff(total > over, "Warning", "Critical"))
| where Status == "Warning" or Status == "Critical"
| order by Computer, VirtualMachine, Status
```

## Hyper-V Dynamic Memory VM - Average Pressure

```
Perf
| where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
| summarize avg=avg(CounterValue) by Computer, InstanceName
| project Computer, VirtualMachine=InstanceName, status=iif(avg < 80, "Healty", iif(avg < 100, "Warning", "Critical"))
| summarize
    healty=countif(status == "Healty"),
    warning=countif(status == "Warning"),
    critical=countif(status == "Critical")
    by Computer
| render columnchart  
```

## Hyper-V Dynamic Memory VM - Average Pressure

```
Perf
| where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
| summarize avg=avg(CounterValue) by Computer, InstanceName
| project Computer, VirtualMachine=InstanceName, Status=iif(avg < 80, "Healty", iif(avg < 100, "Warning", "Critical"))
| where Status == "Warning" or Status == "Critical"
| order by Computer, VirtualMachine, Status
```

## Event errors - Aggregated graph

```
Event
| where EventID in (32022, 32332, 32354, 32086, 33680, 32552, 32088, 32315)
| summarize Count=count() by Computer, EventID
| project Computer, Count, tostring(EventID)  
| render columnchart 
```

## Event errors - List 
```
Event
| where EventID in (32022, 32332, 32354, 32086, 33680, 32552, 32088, 32315)
| summarize Count=count() by Computer, EventID, RenderedDescription
| project Computer, tostring(EventID), Count, RenderedDescription
```