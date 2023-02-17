Notes on trying to analyze crayfish RADseq data 2017

Trying to follow protocols from Peterson et al., Plos ONE (2012).

First, downloaded the rtd-master folder from GitHub (https://github.com/brantp/rtd). Unzipped into BioinformaticsTools folder in Documents.

Then, looking at the README file, have to install 8 dependencies:

1. gdata (included with the rtd-master folder)
2. blat (http://hgdownload.soe.ucsc.edu/downloads.html#source_downloads)
3. mcl/mcxload (https://www.micans.org/mcl/)
4. muscle (http://www.drive5.com/muscle/downloads.htm)
5. samtools (https://sourceforge.net/projects/samtools/?source=typ_redirect)
6. numpy (https://sourceforge.net/projects/numpy/?source=typ_redirect) available from brew
7. editdist (https://code.google.com/archive/p/py-editdist/downloads)
8. GNU parallel (ftp://ftp.gnu.org/gnu/parallel) available from brew
***

Now, installing those programs...

1. gdata: Not sure if this worked quite properly. I followed the directions in the INSTALL.txt file but did get a couple of errors in the test run. Proceeding anyway, we'll see! (Couldn't find anything helpful online to fix the problem.)

2. blat: Following README. Uh, not sure what MACHTYPE is but I changed it to an environmental variable (instead of just a local one by running: export MACHTYPE

	+ To see what MACHTYPE value is: set | grep MACHTYPE (checks local variable)  
		printenv | grep MACHTYPE (checks environmental variable)  
		which returns:  
		MACHTYPE=x86_64-apple-darwin16

	+ The dashes cause a problem in the install so need to rename this MACHTYPE variable (machine type) to exclude everything after the first dash:  
		MACHTYPE=x86_64  
		export MACHTYPE

	+ make sure it worked:  
	set | grep MACHTYPE

	+ Then need to create a new directory and add it to my path:  
	mkdir ~/bin/$MACHTYPE  
	export PATH=$PATH:~/bin/$MACHTYPE

		then try make

		got an error about not finding png.h file... googling tells me I need to install yet another package, libpng
	+ Downloaded libpng from http://www.libpng.org/pub/png/libpng.html  
		Also needs to be compiled... that seems to have worked fine. Now can retry blatSrc
	+ cd to blatSrc directory, then make  
		I guess that worked... some warnings but I guess not fatal
3. mcl/mcxload: following INSTALL file directions.
	+ cd to the directory (use cd .. to move up one level in the filesystem)
	+ run ./configure 
	+ type make to compile
	+ optionally run make check to do self-tests
	+ make install
	+ make clean will remove binaries
	+ I can't really tell whether or not that worked. I'm going to assume that it did since I don't think it game me any fatal errors.

4. muscle: single binary file. Just unzip the tar.gz file. Then rename the file to just 'muscle' so it's not necessary to type a long name to refer to it.
	+ put the binary file in my path variable:  
		echo $PATH (will print out what's in my path right now) 
		 
		Then do the following to add the BioinformaticsTools folder to my path:  
		export PATH=$PATH:~/Documents/BioinformaticsTools/  
		echo $PATH again to check that it worked
		I think that's it...
5. samtools: following the README and INSTALL files
	+ first cd to the samtools-1.6 directory and then run:  
		./configure  
		I think this determines whether I have everything the program needs to properly compile. Seems to be ok.
		
	+ make
	
	+ then copied the file into the BioninformaticsTools folder so accessible to the path:  
		cp samtools ~/Documents/BioinformaticsTools/
		
	+ seems to have worked, I think!
6. numpy: starting with the INSTALL.rst.txt file... says I should install numpy some other way. Found that I should be able to install from brew though wasn't working, updating brew
	
	+ Updating brew required changing /usr/local to be writable (owned by my username):  
		  sudo chmod g+w /usr/local  
		  sudo chgrp staff /usr/local
	
	+ Then, to update homebrew:  
		  brew update  
		Can return /usr/local to default ownership with:  
		sudo chown root:wheel /usr/local
	
	+ Now can try again to install numpy:  
		  brew install numpy  
		Seems to have worked!  
		
		Python3 needs to be installed and brew says I should install Apple Command Line Tools using:  
		
		  xcode-select --install  
		
	+ Caveats from brew when installing numpy:  
		If you use system python (that comes - depending on the OS X version - with older versions of numpy, scipy and matplotlib), you may need to ensure that the brewed packages come earlier in Python's sys.path with:  
		
		  mkdir -p /Users/aroles/Library/Python/2.7/lib/python/site-packages  
		  
		  echo 'import sys; sys.path.insert(1, "/usr/local/lib/python2.7/site-packages")' >> /Users/aroles/Library/Python/2.7/lib/python/site-packages/homebrew.pth  
		  
		Python modules have been installed and Homebrew's site-packages is not in your Python sys.path, so you will not be able to import the modules this formula installed. If you plan to develop with these modules, please run:  
		  
		    mkdir -p /Users/aroles/Library/Python/2.7/lib/python/site-packages  
		    echo 'import site; site.addsitedir("/usr/local/lib/python2.7/site-packages")' >> /Users/aroles/Library/Python/2.7/lib/python/site-packages/homebrew.pth  
		    
	+ Going ahead and installing the Apple Command Line Tools:  
	
		  xcode-select --install

7. py-editdist: Unzipped the tarball. From the README file, looks like I just run a couple of Python scripts, presumably from within the directory.  

	python setup.py build  
	python setup.py install  
	
	Some weird random error messages but I think it worked?!

8. GNU parallel: I think this can also be installed via brew as follows,  
	brew install parallel  
	
	Worked beautifully! :) Not even 1 error message.

***

After installing all dependencies, then I'll need to look at the USAGE_NOTES.txt for my next step.