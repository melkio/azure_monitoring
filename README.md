# azure_monitoring

MSVMI-default
MSMVI-hyperv

http://wiki.webperfect.ch/index.php?title=Hyper-V:_Performance_(Counters)
https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/detecting-virtualized-environment-bottlenecks

Hyper-V Hypervisor Logical Processor(*)\% Total Run Time
Hyper-V Hypervisor Virtual Processor(*)\% Total Run Time
Hyper-V Hypervisor Root Virtual Processor(*)\% Total Run Time

Hyper-V Dynamic Memory Balancer(*)\Available Memory
Hyper-V Dynamic Memory Balancer(*)\Average Pressure
Hyper-V Dynamic Memory VM(*)\Guest Visible Physical Memory
Hyper-V Dynamic Memory VM(*)\Physical Memory
Hyper-V Dynamic Memory VM(*)\Average Pressure

Hyper-V Hypervisor(*)\Partitions


Perf
| where ObjectName == "Hyper-V Hypervisor Root Virtual Processor" and CounterName == "% Total Run Time"
| summarize value = avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
| render timechart 

Perf
| where ObjectName == "Hyper-V Hypervisor Logical Processor" and CounterName == "% Total Run Time"
| summarize value = avg(CounterValue) by bin(TimeGenerated, 5m), InstanceName
| render timechart

Perf
| where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
| summarize value = avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| render timechart

Perf
| where ObjectName == "Hyper-V Dynamic Memory Balancer" and CounterName == "Average Pressure"
| summarize value = avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| render timechart

Perf
| where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
| summarize value = avg(CounterValue) by bin(TimeGenerated, 5m), InstanceName
| top 10 by value
| render timechart


Perf
| distinct ObjectName, CounterName





Perf
| where ObjectName == "Hyper-V Hypervisor Logical Processor" and CounterName == "% Total Run Time"
| where InstanceName == "_Total"
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 


Perf
| where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
| where InstanceName != "_Total"
| distinct Computer, InstanceName
| summarize count() by Computer

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



Perf
| where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
| where InstanceName == "_Total"
| summarize avg=avg(CounterValue) by Computer

Perf
| where ObjectName == "Hyper-V Dynamic Memory Balancer" and CounterName == "Average Pressure"
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 


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

Perf
| where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
| distinct Computer, InstanceName
| summarize vm=count() by Computer

Perf
| where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
| summarize value = avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
| top 10 by value
| render timechart





https://github.com/RehanSaeed/EditorConfig/blob/main/.editorconfig




OnPrem

Disk usage

InsightsMetrics
| where Namespace == "LogicalDisk" and Name == "FreeSpacePercentage"
| summarize arg_max(TimeGenerated, *) by Computer, Tags
| project Status = iif(Val > 50, "Healty", iif(Val < 15, "Critical", "Warning"))
| summarize count() by Status
| render piechart 

Disk usage
Critical disk (less than 15% available)

InsightsMetrics
| where Namespace == "LogicalDisk" and Name == "FreeSpacePercentage"
| summarize arg_max(TimeGenerated, *) by Computer, Tags
| project Computer, Disk = substring(Tags, 22, 2), Value = Val, Status = iif(Val > 50, "Healty", iif(Val < 15, "Critical", "Warning"))
| where Status == "Critical"


HyperV

Hyper-V Hypervisor Logical Processor
% Total Run Time

Perf
| where ObjectName == "Hyper-V Hypervisor Logical Processor" and CounterName == "% Total Run Time"
| where InstanceName == "_Total"
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 

Hyper-V Dynamic Memory Balancer
Average Pressure

Perf
| where ObjectName == "Hyper-V Dynamic Memory Balancer" and CounterName == "Average Pressure"
| summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
| render timechart 

Hyper-V Hypervisor Virtual Processor
% Total Run Time

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

Hyper-V Dynamic Memory VM
Average Pressure

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






