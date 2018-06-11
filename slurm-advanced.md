---
title: Advanced Slurm usage
author: Janne Blomqvist
theme: white
---

# Scope

Previously we have covered the basics of using slurm via the various
slurm command line tools. In this session we'll focus on slightly more
advanced usage, namely:

- Array jobs
- GPU jobs
- Job dependencies
- Multithreaded jobs (e.g. openMP)
- Parallel jobs with MPI

---

## Advanced slurm features

For running these "non-standard" types of jobs, you need additional
options in your job submission.

### Lets begin!

---

# Array jobs

Array jobs are the tool of choice when you are faced with a bunch of
data sets, and you need to run the same program on all the data
sets. In other words, you have an *embarrassingly parallel*
problem. For array jobs, the crucial additional parameter is
`--array=` where you specify the array indices for the job. For each
individual job in the array, Slurm sets the environment variable
`$SLURM_ARRAY_TASK_ID` to the current array index.

---

## Array jobs example

```{.bash}
#!/bin/bash
#SBATCH -n 1
#SBATCH -t 04:00:00
#SBATCH --mem-per-cpu=2500
#SBATCH --array=0-29
  
cd $SLURM_ARRAY_TASK_ID
srun ./my_application -input input_data_$SLURM_ARRAY_TASK_ID
cd ..
```

---

# GPU jobs

In order to allocate a GPU for your jobs, you need to use the slurm
GRES (Generic Resources) system. The syntax of the `--gres` option is:

```
--gres=gpuname[[:type]:count]
```

where you can optionally specify the type of GPU you want, and how
many of those GPU's you want.

---

## GPU simple job

```bash
#!/bin/bash -l
#SBATCH -p gpushort
#SBATCH --gres=gpu

module load CUDA

srun --gres=gpu path/to/my_GPU_binary
```

---

## GPU type selection

To see which kinds of GPU's are available, run

```bash
slurm features
```

If you want to run a GPU job which requires two Tesla K80 GPU's, you need a GRES specification like

```bash
--gres=gpu:teslak80:2
```

---

# Job dependencies

Job dependencies allow you to specify dependencies between slurm
jobs. E.g. if job B needs some results that are calculated and written
to a file by job A, then job B can specify a dependency saying that it
can start only after A has finished successfully.

---

## Job dependency example

```bash
--dependency=<dependency list>
```

where `<dependency list>` is a list of dependecies. E.g.

```bash
--dependency=afterok:123:124
```

meaning that the job can start only after jobs with ID's 123 and 124
have both completed successfully.

---

## Job dependency usual problem

- So you have a workflow where you want, say, job B to start only
  after job A finishes successfully.

- However, you don't know the job ID of job A before you have submitted it!

    - So how to automate it?

- Slurm, by itself, offers no good solution to this.

---

### Solving the problem

Create a shell script for submitting your dependent jobs

```bash
idA=$(sbatch jobA.sh | perl -lane 'print $F[3]')
sbatch --dependency=afterok:${idA} jobB.sh
```

(Error handling above omitted for brevity. For real work you'll want
to handle errors when submitting jobA.)

*Note*: This also works for job arrays!

---

# Parallel jobs

Slurm makes a distinction between multiple processes (tasks) and the
number of threads for each task.

- If you ask for multiple tasks you might get allocated CPU's on
  multiple nodes, which won't work if you want to run a single process
  with multiple threads.

---

## Multithreaded jobs

To specify the number of threads per task, use the
`-c`/`--cpus-per-task=` option.

```bash
#SBATCH -c 4
```

If you're using OpenMP, always set

```bash
export OMP_PROC_BIND=true
```

---

## Multiple tasks

To specify the number of tasks, use the `-n`/`--ntasks=` option

```bash
#SBATCH -n 48
```

*Note*: Slurm runs the job script on the first allocated node, it's up
to you to make use of all the other task slots allocated!

In most cases, you're using MPI, and the MPI runtime Slurm integration
takes care of setting up all the MPI ranks.

---

## Combining all of the above

- Yes, you can create an array job using multiple tasks, multiple
  threads per task, dependencies on other jobs etc.

- Most likely, you won't need to do all of this at once!

---

## Hands-on exercise

1. Create a chain of jobs A -> B -> C each depending on the succesful
   completion of the previous job. In each job, run e.g. `sleep 120`
   (sleep for 2 minutes) to give you time to investigate the
   queue. What happens if at the end of the job A script, you put
   `exit 1`?

---

### Hands-on 2

2. Run a GPU job where you run the deviceQuery sample application.
   *Hint*: To compile deviceQuery, you need to copy the samples
   directory and run make:

```bash
cp -a $CUDA_HOME/samples .
cd samples/1_Utilities/deviceQuery
make
```

---

### Hands-on 3

3. Create a parallel job script with `-n 10`. Run `hostname`, then
   `srun hostname`. What happens?
