param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Invoke-Compose {
    & docker compose @args
}

function Invoke-Forge {
    Invoke-Compose run --rm forge @args
}

function Initialize-LabKey {
    $keyDir = Join-Path $PSScriptRoot ".lab\ssh"
    $keyFile = Join-Path $keyDir "id_ed25519"
    $publicKeyFile = "$keyFile.pub"
    $authorizedKeysFile = Join-Path $keyDir "authorized_keys"

    New-Item -ItemType Directory -Force -Path $keyDir | Out-Null

    if (-not (Test-Path $keyFile)) {
        if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
            throw "ssh-keygen was not found in PATH. Install the Windows OpenSSH client or use WSL."
        }
        & ssh-keygen -t ed25519 -N "" -C "ansible-practical-lab" -f $keyFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create the lab SSH key."
        }
    }

    Copy-Item -Force $publicKeyFile $authorizedKeysFile
}

switch ($Command) {
    "doctor" {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git was not found in PATH."
        }
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw "Docker was not found in PATH."
        }
        if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
            throw "ssh-keygen was not found in PATH. Install the Windows OpenSSH client or use WSL."
        }
        & docker info *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker is installed, but the Docker daemon is not reachable. Start Docker Desktop or the Docker service, then run this command again."
        }
        & docker compose version

        # Port clashes are the most common first-run failure. The lab publishes
        # these host ports in docker-compose.yml, so check they are free before
        # `up`. Skip the check when the lab is already running, since it holds
        # these ports itself.
        $labPorts = 2222, 2223, 2224, 2225, 8080
        $labRunning = & docker ps --filter "name=apl-" --format "{{.Names}}"
        if (-not $labRunning) {
            $busyPorts = @()
            foreach ($port in $labPorts) {
                if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) {
                    $busyPorts += $port
                }
            }
            if ($busyPorts.Count -gt 0) {
                throw "These lab ports are already in use by another process: $($busyPorts -join ', '). Free them or change the port mapping in docker-compose.yml, then run doctor again."
            }
        }

        Write-Host "Doctor checks passed."
    }
    "up" {
        Initialize-LabKey
        Invoke-Compose build forge
        Invoke-Compose up -d --build atlas beacon ledger vaultbox
    }
    "down" {
        Invoke-Compose down
    }
    "reset" {
        Invoke-Compose down --volumes --remove-orphans
        Initialize-LabKey
        Invoke-Compose build forge
        Invoke-Compose up -d --build atlas beacon ledger vaultbox
    }
    "status" {
        Invoke-Compose ps
    }
    "ping" {
        Invoke-Forge ansible all -i inventory/lab.yml -m ansible.builtin.ping
    }
    "facts" {
        Invoke-Forge ansible-playbook -i inventory/lab.yml playbooks/01_facts.yml
    }
    "play" {
        if ($Rest.Count -lt 1) {
            throw "Usage: .\lab.ps1 play <playbook> [extra ansible-playbook args]"
        }
        Invoke-Forge ansible-playbook -i inventory/lab.yml @Rest
    }
    "shell" {
        Invoke-Forge bash
    }
    "logs" {
        Invoke-Compose logs @Rest
    }
    { $_ -in @("help", "-h", "--help") } {
        @"
Usage: .\lab.ps1 <command>

Commands:
  doctor   Check local prerequisites
  up       Build and start the lab
  down     Stop and remove lab containers
  reset    Rebuild the lab from scratch
  status   Show container status
  ping     Run ansible.builtin.ping against all managed hosts
  facts    Gather a few useful facts from all managed hosts
  play     Run a playbook through the control-node container
  shell    Open a shell in the control-node container
  logs     Show Docker Compose logs
"@
    }
    default {
        throw "Unknown command: $Command. Run .\lab.ps1 help"
    }
}
