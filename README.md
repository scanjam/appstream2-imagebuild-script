#appstream2-imagebuild-script
A basic Powershell build script for AWS AppStream 2.0 Images using the AWS Powershell tools available in the AWS AppStream image(s)

#requirements
Its assumed you are running this as the Image Build Admin - and the primary writable location in the user profile is hardcoded as: 'C:\Users\ImageBuilderAdmin\My Files\Temporary Files\Build'

S3 Read Only IAM user with access to the specific bucket.

There are other components of this script for it to run successfully. You should take the Build folder and place that anywhere into your s3 bucket called 'Build'. The script refers to the layout of the files and folder 'under' this directory (doesn't need to -it just does currently due to simplicity and so you dont end up with a giant folder with all sorts of confusing files)

The script references windows executables for the following:
LGPO.exe for import and export of local group policy settings.
Available from: <a href>https://www.microsoft.com/en-us/download/details.aspx?id=55319</a>

sqlite.exe for injection of the application details into the appstream image assistant 
Available from: <a href>https://www.sqlite.org/download.html</a>

setup.exe for Deployment of Office 365 (example.xml files provide) you will need to licenses your office versions accordingly.
Available from: <a href>https://go.microsoft.com/fwlink/p/?LinkID=626065</a>


Application installation files.
Preferably all obtained via wget or online fetch for the latest version however the sceipt has some example references to standard installation things like AdobePro, WinZip, or Java. All these need to be scripted, added and copies of them stored in the Build\Ins folder (assuming you can't wget direct from internet)


#how to use
1) Loginto AppStream2 Build Instance<br>
2) Copy powershell locally<br>
3) Open ise.exe or cmd.exe <strong>as administrator</strong><br>
4) Run the script i.e - './MastersofCloud-AppStream2-Build-Script.ps1'<br>

there are only some commands that need 'runas admin' (like the LGPO GPO importation)

The script will prompt for the variables it will use throughout its execution:

Variables for your AWS Access and Secret key (temporarily) of a user with read ony access to your S3 bucket.

Variable for the name of the bucket to 'pull other build files from (like shortcuts, icon files, O365 installation files etc) 

Variable for the Build folder to 'read' from within your chose bucket (usually called 'Build'). 

Variable for the image type you would like to deploy (image 1 or 2) where an image specific set of commands can run later on in the script depending on the selection.