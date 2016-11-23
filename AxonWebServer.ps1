#enable winrm first so this command will run
#e.g. 'c:\> winrm quickconfig'
# - better yet -
#Enable-PSRemoting

Configuration AxonWebServer
{
    param 
    ( 
        # Target nodes to apply the configuration 
        [string[]]$NodeName = 'localhost' 
    ) 

    Import-DscResource –ModuleName PSDesiredStateConfiguration, xNetworking

    Node $NodeName
    {
        # Install the IIS role 
        WindowsFeature IIS 
        { 
            Ensure          = "Present" 
            Name            = "Web-Server" 
        } 
        # Install the ASP .NET 4.5 role 
        WindowsFeature AspNet45 
        { 
            Ensure          = "Present" 
            Name            = "Web-Asp-Net45" 
        } 

        WindowsFeature WebStaticContent
        { 
            Ensure          = "Present" 
            Name            = "Web-Static-Content" 
        } 

        WindowsFeature WebStatCompression
        { 
            Ensure          = "Present" 
            Name            = "Web-Stat-Compression"
        } 

        WindowsFeature WebDynCompression
        { 
            Ensure          = "Present" 
            Name            = "Web-Dyn-Compression"
        } 

        WindowsFeature WebMgmtConsole
        { 
            Ensure          = "Present" 
            Name            = "Web-Mgmt-Console"
        }
        
        xFirewall HTTP
		{
			Name = 'WebServer-HTTP-In-TCP'
			Group = 'Web Server'
			Ensure = 'Present'
			Action = 'Allow'
			Enabled = 'True'
			Profile = 'Any'
			Direction = 'Inbound'
			Protocol = 'TCP'
			LocalPort = 80
			DependsOn = '[WindowsFeature]webServer'
		}

        Package UrlRewrite
		{
			#Install URL Rewrite module for IIS
			#DependsOn = "[WindowsFeaturesWebServer]windowsFeatures"
			Ensure = "Present"
			Name = "IIS URL Rewrite Module 2"
			Path = "http://download.microsoft.com/download/6/7/D/67D80164-7DD0-48AF-86E3-DE7A182D6815/rewrite_2.0_rtw_x64.msi"
			Arguments = "/quiet"
			ProductId = "EB675D0A-2C95-405B-BEE8-B42A65D23E11"
		}

#        File MyFile {
#            DestinationPath = "C:\MyFile.txt"
#            Contents = "Hello World"
#        }        
        
#        File MyOtherFile {
#            DestinationPath = "C:\MyOtherFile.txt"
#            Contents = "Goodbye World"
#        }
    }
}

# AxonWebServer
#Start-DscConfiguration -Path .\AxonWebServer -Wait -Verbose -ComputerName localhost