Import-Module –Name PSWorkflow
$jobs = Get-Job -state Suspended
$resumedJobs = $jobs | resume-job -wait
$resumedJobs | wait-job