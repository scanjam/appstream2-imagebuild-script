#AppStream Image Build Script - Created by James Scanlon at Masters of Cloud - www.mastersof.cloud for Introduction to AWS AppStream Online Course
#Version 1.00 - 03/07/2018 - JS - Initial Creation
#Version 1.01 - 04/07/2018 - JS - First round launch and build confirms few broken issues with -HKLM fix registry keys
#Version 1.02 - 10/07/2018 - JS - Added AWS Support IEES for Local admin, login script for HKCU
#Version 1.03 - 16/07/2018 - JS - GPO Setup and Import Export options
#Version 1.04 - 20/07/2018 - JS - Added Multiple Image Support
#Version 1.05 - 07/08/2018 - JS - Removed Erroneous entries and non required lines.
#Version 1.06 - 15/10/2018 - JS - Prepare for github upload



#PREPARE THE SCRIPT----------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Declare Variables
    #It is strongly recommended that you use a READ ONLY ACCOUNT for S3 Access and not an account with more access than is required.
    $buildpath = "C:\Users\ImageBuilderAdmin\My Files\Temporary Files\Build"
    $awsaccesskey = read-host "Please provide your AWS Access Key.(Recommended you use an S3 Read only user to your build bucket)"
    $awssecretkey = read-host "Please provide your AWS Secret key."
    $bucketname = read-host "Please provide your AWS Bucket Name"
    $bucketfolder = read-host "Please provide your AWS Bucket Folder Name"
    $imagetype = read-host "What Image Type Do You Want to Deploy? Options: IMAGE1, IMAGE2? (Case Sensitive)"


#PREPARE THE IMAGE----------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Clear the Screen
    clear
    #Start the Amazon Photon Image Assistant so it creates the default, blank SQLite Database.
    & "C:\Users\Public\Desktop\Image Assistant.lnk"
    #Load AWS Powershell Extensions. Its better to load PSH as the AWS CLI is not installed in the Amazon provided AppStream image(s).
        import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
    #Set your AWS Creds to connect to S3 as a read-only user with for this Script to access the complete AppStream build files.
        Set-AWSCredentials -AccessKey $awsaccesskey -SecretKey $awssecretkey -StoreAs default
    #Download AWS bucket folder called 'Build' using AWS Powershell Tools. Case Sensitive Names!
        read-s3object -BucketName $bucketname -keyprefix $bucketfolder -Folder $buildpath
    #Stop the Amazon Image Assistant Running
        stop-process -Name PhotonWindowsAppCatalogHelper

#GENERIC ENVIRONMENT CONFIGURATION FOR REGISTRY and LOCAL GPO-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    #This section 'attempts' to disable IEES as per AWS Provided support registry keys it need to be used in conjunction with a user logon script to disable it for HKCU as well. (added below)
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -value 0 -Type "DWORD"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "ComponentID" -value "IEHardenAdmin" -Type "String"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -value 0 -Type "DWORD"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "ComponentID" -value "IEHardenAdmin" -Type "String"
        New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -value 0 -Type "DWORD"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "ComponentID" -value "IEHardenAdmin" -Type "String"
        New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -value 0 -Type "DWORD"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "ComponentID" -value "IEHardenAdmin" -Type "String"
    # Set User Logon Script as HKLM Run Key, the script has to exist to disable IEES on a per user basis.
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Login Script" -value "powershell.exe -windowstyle hidden C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -Type "String"

#IMAGE LOGIN SCRIPT CREATION-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Create Logon Scripts Directory
        New-Item -ItemType Directory -Force -Path "C:\Users\Public\Scripts"

    #Create Logon Script and Export. This section writes a login script to the c:\users\public\scripts directory which is called at user login.
    #Script creation was added here line by line in order to 1) see what was being run as part of the login script and
    #2) remove the need for additional files and 3) to provide a method to turn on and off features as required.
    #This script also sets the users regional / locale to GB / London as logon without having to change the default user or system profile(s)
        set-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "& rundll32.exe iesetup.dll,IEHardenMachineNow" -Force
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "& rundll32.exe iesetup.dll,IEHardenUser" -Force
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "& rundll32.exe iesetup.dll,IEHardenAdmin" -Force
        #Changes Language and Regional settings for the users at Logon.
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "#set regional and language settings to UK / GB / GMT"
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "Set-WinSystemLocale en-gb" -force
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "Set-Culture en-GB" -force
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "Set-WinSystemLocale en-GB" -force
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "Set-WinHomeLocation -GeoId 242" -force
        add-content -path "C:\Users\Public\Scripts\AppStreamLogonScript.ps1" -value "Set-WinUserLanguageList en-GB -Force" -force

#SET IMAGE TIMEZONE----------------------
        Set-Timezone "GMT Standard Time"

#GENERIC APPLICATION INSTALLATION SECTION------------------------------------------------------------------------------------------------------------------------------------------------
    #Use This Section to install generic applications that are required across all your images like, Adobe PDF, Java Clients, etc.
        #Install Adobe PDF Reader.
        & "$buildpath\ins\<nameofmyadobereadereceutable>" /rps /SPB
        
        #Script the Explorer batch file. This file can be published from Image Assistant and opens explorer at the 'temporary files' directory.
        set-content -path "C:\Users\Public\Scripts\Start_Explorer.bat" -value "cd `"%userprofile%\my files\temporary files`"" -Force
        add-content -path "C:\Users\Public\Scripts\Start_Explorer.bat" -value "start ." -Force


#SCRIPT THE APPSTREAM APPLICATION INJECTION------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Copy Icon Files to be referenced by Published Application(s) in AppStream Photon Image Assistant - These should be manually created and provided.
    #If done via the Image assistant you can guarantee the icons will be of the correct size.
        cp $buildpath"\ins\AppIcons\*.*" C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons
    #Create the SQL Batch File for AppStream Injection
        set-content -path $buildpath"\sql_add_applications.bat" -value "type `"$buildpath\add_appstream_apps.sql`" | `"$buildpath\sqlite3.exe`" C:\ProgramData\Amazon\Photon\PhotonAppCatalog.sqlite" -Force


#IMAGE SPECIFIC OPTIONS, CHANGES AND APPLICATIONS INSTALLATIONS------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Image - IMAGE1 - Office 365----------------------------------------------------------------------------------------------------------------------------
            if ($imagetype -eq "IMAGE1") {
            #Inject Registry and Configuration Changes
                #Import Local GPO Backup
                #You can create your image builder, manipulate local GPedit.msc settings and then export them using the below commands and tool.
                #It can be imported on any W2012 machine with the below command. '.\LGPO.exe /g <PathtoGPOBackup>'
                #Backup of the current local group policy can be called by '.\LGPO /b <PathtoGPOBackup>'
                #Path can also be left blank to write to the current directory and this must be run as a local administrator or it will fail.
                #Import existing local GPO
                    #& $buildpath"\ins\GPO\LGPO.exe" /g $buildpath"\ins\GPO\<PATHTOMYGPOBACKUP>"
                    #& gpupdate /force

             #Inject Image Specific Applications
                #Microsoft O365 Installation
                    New-Item -ItemType Directory -Force -Path "C:\ODT"
                    cp $buildpath"\Ins\O365\*.*" C:\ODT
                    & "C:\ODT\setup.exe" /download C:\odt\installOfficeProPlus32.xml
                    & "C:\ODT\setup.exe" /configure C:\odt\installOfficeProPlus32.xml

            #Create the SQL File for AppStream Injection
                    add-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"windowsexplorer`", `"C:\Users\Public\Scripts\Start_Explorer.bat`", `"Windows Explorer`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\windowsexplorer.png`", `"`");" -Force
                    add-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"Access`", `"C:\Program Files (x86)\Microsoft Office\root\Office16\MSACCESS.EXE`", `"Access`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\access.png`",`"`");" -Force
                    add-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"Excel`", `"C:\Program Files (x86)\Microsoft Office\root\Office16\excel.exe`", `"Excel`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\excel.png`",`"`");" -Force
                    add-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"Word`", `"C:\Program Files (x86)\Microsoft Office\root\Office16\winword.EXE`", `"Word`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\word.png`",`"`");" -Force

            }

    #Next Image - IMAGE2 - Visio and Project ONLY----------------------------------------------------------------------------------------------------------------------------
            if ($imagetype -eq "IMAGE2") {
             #Inject Registry and Configuration Changes
                #Import Local GPO Backup
                #You can create your image builder, manipulate local GPedit.msc settings and then export them using the below commands and tool.
                #It can be imported on any W2012 machine with the below command. '.\LGPO.exe /g <PathtoGPOBackup>'
                #Backup of the current local group policy can be called by '.\LGPO /b <PathtoGPOBackup>'
                #Path can also be left blank to write to the current directory and this must be run as a local administrator or it will fail.
                #Import existing local GPO
                    #& $buildpath"\ins\GPO\LGPO.exe" /g $buildpath"\ins\GPO\<PATHTOMYGPOBACKUP>"
                    #& gpupdate /force

              #Inject Image Specific Installations
                #Microsoft VISIO and PROJECT Installation
                    New-Item -ItemType Directory -Force -Path "C:\ODT"
                    cp $buildpath"\Ins\O365\*.*" C:\ODT
                    & "C:\ODT\setup.exe" /download C:\odt\Visioprox86.xml
                    & "C:\ODT\setup.exe" /download C:\odt\ProjectProx86.xml
                    & "C:\ODT\setup.exe" /configure C:\odt\ProjectProx86.xml
                    & "C:\ODT\setup.exe" /configure C:\odt\Visioprox86.xml

            #Create the SQL File for AppStream Injection
                set-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"windowsexplorer`", `"C:\Users\Public\Scripts\Start_Explorer.bat`", `"Windows Explorer`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\windowsexplorer.png`", `"`");" -Force
                add-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"Visio2016`", `"C:\Program Files (x86)\Microsoft Office\root\Office16\VISIO.EXE`", `"Visio 2016`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\visio.png`",`"`");" -Force
                add-content -path $buildpath"\add_appstream_apps.sql" -value "INSERT INTO Applications (Name, AbsolutePath, DisplayName, IconFilePath, LaunchParameters) VALUES (`"Project2016`", `"C:\Program Files (x86)\Microsoft Office\root\Office16\WINPROJ.EXE`", `"Project 2016`", `"C:\ProgramData\Amazon\Photon\AppCatalogHelper\AppIcons\project.png`",`"`");" -Force

            }

    #Finally - Execute the Injection of your Appstream applications into the AppStream Photon Image Assistant.
        & $buildpath"\sql_add_applications.bat"

#CLOSING THE IMAGE SETUP----------------------------------------------------------------------------------------------------------------------------------------------------------------
    #Remove AWS Credentials before resealing the image. Your credentials must be removed else the image creation process fails and will not complete.
        Remove-AWSCredentialProfile -ProfileName default -Force

    #As the script is now completed you will still need to run the Wizard to snapshot the image and shut it down.
    #Start the Amazon Photon Image Assistant to complete the image creation process, then 'Next, Next Next'
        & "C:\Users\Public\Desktop\Image Assistant.lnk"
