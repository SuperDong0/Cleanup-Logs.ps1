# Cleanup-Logs.ps1

Script finds log-files older than some date in list of folders offered by user.

Log-files can be compressed and moved to some local or network folder.

Log-files can be deleted without archiving.

# Parameters

-workFolder

	This optional parameter allows point out work folder that contains Folders.txt file with list of folder
	to archive. Default value is "C:\Scripts\CleanLogFiles".
	
-timeLimit

	This optional parameter allows specify retention period for log-files. Default time limit is 90 days.
	
-Archive

	This optional parameter allows specify should script move compressed log-files to archive. Default value 
	is $true, files should be moved.
	
-archiveFolder

	This optional parameter allows point out target folder that contains compressed log-files. Default value 
	is "C:\Scripts\CleanLogFiles\Archive".
	
-DeleteFiles

	This optional parameter allows specify should script delete compressed log-files to archive. Default value is 
	$true, files should be deleted.

# Examples

## Example1

.\Cleanup-Logs.ps1
	
	Finds list of folders for archiving in file C:\Scripts\CleanLogFiles\Folders.txt, finds in these folders 
	log-files older than 90 days, compress them, move compressed files to folder C:\Scripts\CleanLogFiles\Archive 
	and deletes them.
	
## Example2

.\Cleanup-Logs.ps1 -timeLimit 60 -archiveFolder \\server\LogArchive\servername
	
	Finds list of folders for archiving in file C:\Scripts\CleanLogFiles\Folders.txt, finds in these folders 
	log-files older than 60 days, compress them, move compressed files to network folder \\server\LogArchive\servername 
	and deletes them.
