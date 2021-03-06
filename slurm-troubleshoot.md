---
attr_reveal: ':frag (none none appear)'
author:
- Janne Blomqvist
title: Slurm problems
theme: white
---


## Reason for queuing jobs

-   See the list of pending jobs with `squeue -t PD`
-   The last column, `NODELIST (REASON)` shows why the job isn't running
-   Open the manual page for squeue with `man squeue`
    -   See the section `JOB REASON CODES` towards the end
        -   The list is NOT exhaustive

---

### The most common reason codes

-   **Priority**: There is another pending job with higher priority
-   **Resources**: The job has the highest priority, but waiting for
    resources to become available, that is, for some running job to
    finish.
-   **AssocMaxJobsLimit**: The association (=user/group) has a limit on
    the number of resources (e.g. GPU's) that can be used by running
    jobs. You must wait for some of your running jobs to finish before
    this one can be started.
-   **QOSResourceLimit**: Hitting QoS limits.

---

### Most common reason codes 2

-   **launch failed requeued held**: Job launch failed, slurm requeued
    the job but it must be released with `scontrol release JOBID`
-   **Dependency**: Job cannot start before some other job is finished.
-   **DependencyNeverSatisfied**: Job cannot start before some other job
    is finished, but that other job failed. You must cancel the job with
    `scancel JOBID`

---

### GrpTRESRunMins?

To prevent a single user from monopolizing all resources, we use
GrpTRESRunMins. See your limits with 

```bash
sacctmgr list user $USER witha \
format=Account,MaxCPUs,GrpTRESRunMins%50,GrpTRES%40
```

-   E.g. a GrpTRESRunMins limit `cpu=1500000` means that the remaining
    runtime of your running jobs must be less than 1500000 cpu-minutes
-   Check out the [GrpCPURunMins
    simulator](https://marylou.byu.edu/simulation/grpcpurunmins.php) and
    [In-depth
    explanation](http://tech.ryancox.net/2014/04/scheduler-limit-remaining-cputime-per.html)

---

## Queue priority

In triton we use a hierarchical fair share algorithm which assings a
priority value to each pending job.

-   The goal is to balance usage so that each department and user gets
    their own fair share of the available resources.
-   Historical usage is taken into account, exponetially decayed with
    half-life of 2 weeks.
    
---

### Queue prio 2

-   That is:
    -   Use lots of resources =&gt; lower priority
    -   Use less resources =&gt; higher priority
-   See the `sprio` tool
- Also: `scontrol show job JOBID` will show the estimated start time
  of your job (if the scheduler has ever reached it)

---

## Job failure

-   Check the your recently completed jobs: `slurm history 3days`
-   Check an individual job record: `sacct -j JOBID`
-   More info with `-l` switch
-   See the `State` and `ExitCode` columns
    -   `State=COMPLETED` and `ExitCode=0:0` means (slurm thinks) the
        job completed successfully

---

### Job failure 2

-   If the job failed
    -   The stdout file (e.g. `slurm-JOBID.out` by default) often
        contains the reason.
        -   E.g. job was killed due to breaching the time limit, or
            memory limit

