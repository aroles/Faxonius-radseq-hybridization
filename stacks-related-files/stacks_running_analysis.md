# Analyzing data using STACKS

We will run the analyses on the cluster, named Sciurus. You interact with Sciurus via the terminal.

## Log in to Sciurus

To log in, open a terminal window and type

ssh aroles@sciurus.hpc.oberlin.edu

When asked for the password, type

cray12fish

Then you will be logged in and see the new prompt. To logout, simply type `logout` at the Terminal prompt.

To see where you are in the file directory, type:

echo $PWD

To see a list of the files in the current folder type:

ls

In the list, you will see a number of files with the extension .pbs. These are the scripts that we use to run our analyses on the cluster. For each new analysis, you need to modify those scripts as needed before you run them.

To run one of the scripts you simply type:

qsub scriptname.pbs

That submits the job to the cluster. You can check the status of jobs (are they still running?) using:

qstat

To edit an existing script you want to open the text editor nano using:

nano scriptname.pbs

And then you must navigate with the arrow keys (not the mouse), using the keyboard commands at the bottom of the screen. Crtl-o, followed by enter, will save the current version of the file. Ctrl-x will close the file.

## PBS script meanings

In the header to the PBS file, here's what those commands mean: (note that a single or double hash (#) symbol followed by a space causes the computer to ignore what follows the hash, thus it is a comment. 

#! /bin/bash  (this line tells the machine it's going to be a shell script)
#PBS -j oe (this merges the two log files that PBS usually outputs)
#PBS -o output.txt (this is the name of the output log file, will overwrite if you don't change it)
#PBS -N stacks (this is the name of the job you are running)
## #PBS -l nodes=1:ppn=10 (this specifies how much computing power you are using: -l refers to limit, nodes is how many nodes you are requesting and ppn is processors per node that you want to run)
#PBS -l nodes=1:ppn=10 (the single hash symbol in front of PBS means the computer will execute this command)
#PBS -m abe (this says do you want to be sent email when the job aborts (a), begins (b), or ends (e))
#PBS -M <aroles@oberlin.edu> (this is the email to send the notifications to)
#set -x (I think this tells the computer to print out the commands it is running, but not sure)
echo $PATH
PATH=$PATH:/home/staff/aroles/
export PATH

## Process radtags script

This program will demultiplex the data and then we'll also use it to merge the 4 files it creates for each sample. This has already been done for our dataset.

### De-multiplex the original sequencing files

Used the stacks.pbs script for this step. Options include trimming the sequences to 80bp (all must be trimmed to the same length for later analyses). Output goes into the demulti folder.

### Concatenate all files for a single individual

The above step creates 4 files for each sample and we need to merge them. Used the stacks_merge.pbs script for this. Output is in the concat folder.

## ustacks

Use the ustacks.pbs script. Below is the content of that script using the default settings:

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


## cstacks

Use the cstacks.pbs script. Content of that script is below.

Run cstacks to assemble the catqstatalog.

* The `-P` flag points to the directory with the ustacks output.
* The `-M` flag identifies the population map.
* The `-p` flag gives the number of parallel threads to execute.
* Note that you can't specify -P/-M and -s/-o, only one of those pairs can be specified.


```
# cstacks.pbs

cd $PWD

/usr/local/bin/cstacks -P ./out_ustacks_default/ -M ./pop_ids/popset.txt -p 10
```

Output is saved to the `out_ustacks_default` folder. 


## sstacks

Run sstacks to match samples to the catalog.

Finally, running sstacks, saving output in the `sstacks_default` sub-folder.

```
# sstacks.pbs

cd $PWD

/usr/local/bin/sstacks -P ./out_ustacks_default/ -M ./pop_ids/popset.txt -p 10 
```


NOTE: I also created a single pbs script with all 3 of the above calls, ucsstacks.pbs.

That way, perhaps we can run things all in one go. If it works out, we may want to add populations to it as well.

## populations 

Run this to get population analysis, need this to evaluate what parameter values to use in the analysis.

```
# populations.pbs

cd $PWD

mkdir ./out_ustacks_default/populations

/usr/local/bin/populations -P ./out_ustacks_default/ -O ./out_ustacks_default/ -M ./pop_ids/popset.txt -t 10 

```

Run the populations analysis with whatever subset of the samples you choose. I created population map files for the native sites (BOK, STW, CRM, SCL, VSG), the Kokosing River sites, and the Huron River sites.

Notes:

* When I tried to run all samples with all populations in one go (as noted in the above script), the job was killed by the computer. Chris Mohler suggested altering the pbs script to run the job as "long" instead of "batch". To do this, I added the line "#PBS -q long" to the script header. However, when I ran the job again, it failed again. with the same termination code (137).
* If you created the catalog as batch 1, then you need to be sure that you specify batch 1 in your populations script too. Otherwise it won't find the catalog.


## Exporting results from Sciurus

In order to use the web interface on our lab machine, we need to export the files produced by ustacks, cstacks, sstacks (and populations) from Sciurus to the lab machine. We will use secure-file-transfer-protocol (sftp) to do this. 

Use `ls -lh out_ustacks_default` in the Terminal to see how big the folder is. It seems like this can be slow to execute for some reason.

To export, use CyberDuck, which allows you to sftp the files from Sciurus to your machine.

Use SFTP with the following settings,
	server: storage02.hpc.oberlin.edu
	user: aroles
	password: oberlin

Once the directory opens, you can right-click and choose Download for any files or folders you choose.

To upload the analysis to the web interface as a database, you will need all of the output of ustacks, cstacks, sstacks, and populations (if this has been run).


## Uploading a stacks analysis to the database for use with the web interface

First, you must run an analysis, using ustacks, cstacks, and sstacks to create the catalog for upload. Then, copy the output files to the local computer and note the full path.

For general reference: on the lab computer, when you are asked by a password for a sudo command, it is 'darwin12' (no quotes). But for stacks itself, or mysql, the password is 'stacks1'.

### Create database in mysql

Now, you need to create the database in mysql:

```
sudo mysql -u root -p -e "create database namehere_radtags"
```

* First password is for the sudo command and is darwin12
* Second password is for mysql: 'stacks1'

* Note that the database name must end in _radtags or else the web interface will not recognize it.

### Prepare database to receive files

Next, prepare the database to receive files (tell it where to store them, I think):

```
mysql -u root -p namehere_radtags < /usr/local/share/stacks/sql/stacks.sql
```

* Again, password here is 'stacks1'

### Add data to database using load_radtags.pl script

Next we run the load_radtags.pl script to add the files to that database. Note that this step can be slow. To do this for all 217 samples takes >1 day (I think it took about 3 days on my machine for all 217 samples).

```
cd /Users/student/Documents/BioinformaticsTools/stacks_analysis

load_radtags.pl -D namehere_radtags -p ./out_test -b 1 -c -B -e "Description of analysis here"

cd /Users/student/Documents/BioinformaticsTools/stacks_analysis

load_radtags.pl -D kokosing_default_radtags -p ./out_kokosing_default -b 1 -c -B -e "Kokosing only, default settings"
```

Meaning of options in the above load_radtags.pl command?
* -D is the database as we just defined it
* -p is the path to our files to add to the database
* -b is the batch ID
* -c is the command to load the catalog into the database
* -B is the command to load information into the batch table
* -e (optional) is where you can place a batch description
* -t (optional) tells the program whether you were making a genetic map or doing a population analysis; must be either 'map' or 'population'

### Index the database for faster processing

Once load_radtags has finished, you should index the database to speed up the web interface. Including -t will add a tags index of the samples. This slows the process as it needs to run for each sample. Otherwise, it only takes a few minutes to run the index.

```
index_radtags.pl -D namehere_radtags -c -t

index_radtags.pl -D kokosing_default_radtags -c -t
```

And that's it, once index_radtags is finished, you can use the web interface to view the data!

Go to http://localhost/stacks to enter the web interface.

### Exporting from the web interface

So far, I can get it to create an export file but then I don't get an email notification and the only way I can see to get the file downloaded is to go to the export folder: /usr/local/share/stacks/php/export and manually move it elsewhere or use it from there (the naming convention is horrid, just adds random letters and numbers to the end).

To move the exported file into the stacks_analysis folder:

```
cd /usr/local/share/stacks/php/export

ls # to see the file names, note the one you want

ls -l # will also give you dates/times of creation of files

sudo mv ./stacks_export_qupUn6C3.tsv /Users/student/Documents/BioinformaticsTools/stacks_analysis
```