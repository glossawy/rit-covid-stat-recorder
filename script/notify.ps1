Param([string]$Type)

if (-Not (Get-Module -ListAvailable -Name BurntToast)) {
    Write-Host "BurntToast is not installed as a powershell module. Install BurntToast by running: Install-Module -Name BurntToast"
} else {
    Switch($Type) {
      "New-Statistic" {
        $Title = "New RIT Covid Statistics"
        $Message = "Data on the dashboard has updated, persist and sync soon!"
        break
      }

      "Error" {
        $Title = "RIT Covid Statistic"
        $Message = "Error fetching RIT dashboard data!"
      }

      default {
        $Title = "RIT Covid Statistics"
        $Message = "Unknown notification type: $Type"
      }
    }

    $DismissBtn = New-BTButton -Dismiss
    New-BurntToastNotification -AppLogo ./notification-logo.png -Text "$Title", "$Message" -Button $DismissBtn
}
