---
title: Advanced Slurm usage
author: Janne Blomqvist
theme: serif
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

# Advanced slurm features

For running these "non-standard" types of jobs, you need additional
options in your job submission.

## Lets begin!

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
