# Using Sciurus

Created: Feb 15, 2018  
Updated: Feb 16, 2018

Author: AJR

---

## Connect to Sciurus

Here's my Sciurus account:
user: aroles
pass: cray12fish

Use ssh at the Terminal. Open a terminal window and type the following to log in:

```
ssh aroles@sciurus.hpc.oberlin.edu
```

To logout, simply type `logout` at the Terminal prompt.

### Details about Sciurus and stacks

Stacks is installed using openmpi-1.8/gcc-4.9.2. It's located in /usr/local/bin

Don't run jobs on the head node (login node) as it will cause other jobs to fail. Chris Mohler will cancel them without warning if he notices any jobs running on the head node.

All jobs must be submitted to the queue using a PBS script and the "qsub" command. If you google for Torque PBS job submission you will find lots of information. Chris has setup a template script for me to use in my home directory. It's called stacks.pbs you will need to edit it and put the stacks commands you want in the script before you submit it to the queue.

If any trouble or need help contact Chris Mohler (cmohler@oberlin.edu). There is some documentation on https://sciurus.hpc.oberlin.edu as well. 

## Sample PBS script (stacks.pbs)

```
#! /bin/bash
#PBS -j oe
#PBS -o output.txt
#PBS -N stacks
## #PBS -l nodes=1:ppn=10
#PBS -l nodes=1
## #PBS -m abe
## #PBS -M <email address here>
#set -x
echo $PATH
PATH=$PATH:/home/staff/aroles/
export PATH

module load openmpi-1.8/gcc-4.9.2

#Your Commands go below here. Look for cstacks, sstacks in /usr/local/bin
```

## Transferring files to Sciurus

Can do this using FTP client like FileZilla. Need to configure the client with your netid as the username, the cluster login node as the hostname and your private key as the authentication method.

Open FileZilla and connect with Sciurus. Needed to use ssh (sftp) using sciurus.hpc.oberlin.edu as the host and then the login above. Ask for password.

2/15/2018 Transferring the two fastq files with the raw data in them, in the "clean" directory. Looks to take ~1.5 hours. That didn't work, job failed for reasons unknown.

Called Chris Mohler (x58083) who helped me out. Now transferring the files, one at a time via storage02.hpc.oberlin.edu (files are not stored directly on sciurus but on storage01, 02, or 03). My password for this server is simply 'oberlin'. Chris says the job may be terminated by the system if it runs over an hour.

2/16/2018 I also transferred the smaller subset of those files for working with quickly, in a folder called subset.

# First PBS script

To run `process_radtags` on all of the samples at once, with the right flags to trim the data. 

```
#! /bin/bash
#PBS -j oe
#PBS -o output.txt
#PBS -N stacks
## #PBS -l nodes=1:ppn=10
#PBS -l nodes=1
## #PBS -m abe
#PBS -M <email address here>
#set -x
echo $PATH
PATH=$PATH:/home/staff/aroles/
export PATH

module load openmpi-1.8/gcc-4.9.2

#Your Commands go below here. Look for cstacks, sstacks in /usr/local/bin

/usr/local/bin/process_radtags -P -p /home/faculty/aroles/subset/ -o /home/faculty/aroles/demulti -b /home/faculty/aroles/barcodes.tsv --renz_1 ecoRI --renz_2 mseI -r --disable_rad_check --inline_inline -c -q -i fastq -t 80
```

That script worked, that was just on the subset of data. Now try the concatenation on the subset too. The ids.txt file must contain a single column of all your sample names.

Must cd to the demulti folder. See the stacks_merge.pbs script in Sciurus.

```
for i in $(cat ids.txt);
    do mkdir $i ;
    mv $i.* $i ;
	/usr/local/bin/process_radtags -p /home/faculty/aroles/$i/ -o /home/faculty/aroles/$i/ --disable_rad_check -i fastq --merge ;
	mv /home/faculty/aroles/$i/sample_unbarcoded.fq /home/faculty/aroles/$i.fq ;
done;
```

Now it's ok to run ustacks on the demultiplexed, concatenated files.

ustacks script:

```
cd $PWD

n=1
for id in $(cat ./pop_ids/ids.txt) ;
do
    /usr/local/bin/ustacks -f ./demulti/${id}.fq -o ./ustacks_out/ -i $n -m 3 -t fastq
    let "n+=1" ;
done;
```

All of that worked, going to go back and run process_radtags on the entire dataset instead of just the subset.

## Process radtags whole dataset

I removed the directories for each sample that had been created with the subset of the data in order to recreate them here. 

```
# stacks.pbs
cd $PWD 

/usr/local/bin/process_radtags -P -p ./clean/ -o ./demulti -b barcodes.tsv --renz_1 ecoRI --renz_2 mseI -r --disable_rad_check --inline_inline -c -q -i fastq -t 80
```

Retained 68% of the reads with 31.9% ambiguous barcode drops and a small fraction of low quality read drops.

Then, just like before, merging all the files for a single individual:

```
# stacks_merge.pbs
cd $PWD

mkdir concat

for i in $(cat ./pop_ids/ids.txt);
    do mkdir ./demulti/$i ;
    mv ./demulti/$i.* ./demulti/$i ;
	/usr/local/bin/process_radtags -p ./demulti/$i/ -o ./demulti/$i/ --disable_rad_check -i fastq --merge ;
	mv ./demulti/$i/sample_unbarcoded.fq ./concat/$i.fq ;
done;
```

Merged, demultiplexed files are in the concat folder, at the top level.


Next, can run ustacks on demultiplexed, concatenated files.

```
# ustacks.pbs
cd $PWD

mkdir out_ustacks_default

n=1
for id in $(cat ./pop_ids/ids.txt) ;
do
    /usr/local/bin/ustacks -f ./concat/${id}.fq -o ./out_ustacks_default/ -i $n -m 3 -t fastq -p 10;
    let "n+=1" ;
done;
```

Output is in the `out_ustacks_default` folder.

Then, cstacks on the ustacks stuff:

The `-P` flag points to the directory with the ustacks output.
The `-M` flag identifies the population map.
The `-p` flag gives the number of parallel threads to execute.


```
# cstacks.pbs

cd $PWD

mkdir ./out_ustacks_default/cstacks_default

/usr/local/bin/cstacks -P ./out_ustacks_default/ -M ./pop_ids/popset.txt -p 10 -o ./out_ustacks_default/cstacks_default
```

Output is in the `cstacks_default` sub-folder.

Finally, running sstacks, saving output in the `sstacks_default` sub-folder.

```
# sstacks.pbs

cd $PWD

mkdir ./out_ustacks_default/sstacks_default

/usr/local/bin/sstacks -P ./out_ustacks_default/ -M ./pop_ids/popset.txt -c ./out_ustacks_default/cstacks_default -p 10 -o ./out_ustacks_default/sstacks_default
```

Created pbs scripts on Sciurus for each step. They can be submitted with the qsub command. 

## Next up: Options?

Thing we need to figure out: what values should we be using for options here.