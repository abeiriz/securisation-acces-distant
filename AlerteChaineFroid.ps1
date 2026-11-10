<#
.SYNOPSIS
    Surveille le service de supervision de la chambre froide et alerte par courriel.

.DESCRIPTION
    Vérifie l'état du service toutes les cinq minutes, via une tâche planifiée.
    En cas d'arrêt, écrit dans un journal local et envoie une alerte SMTP.

    Ce mécanisme est volontairement indépendant du compte du prestataire,
    du tunnel VPN et de toute intervention humaine. Il continue de fonctionner
    quand le compte est verrouillé, ce qui est précisément le scénario
    qu'il doit couvrir.

    Les identifiants SMTP ne figurent pas dans ce fichier. Ils sont lus depuis
    un fichier chiffré par DPAPI, déchiffrable uniquement par le compte qui
    l'a créé, sur la machine qui l'a créé. Voir Initialiser-Identifiants.ps1.

.NOTES
    Déposé dans C:\Scripts\ sur le serveur applicatif.
    Le fichier d'identifiants ne doit jamais être versionné.
#>

[CmdletBinding()]
param(
    [string]$NomService     = 'FrigoMonitor',
    [string]$FichierJournal = 'C:\Scripts\frigo.log',
    [string]$FichierIdent   = 'C:\Scripts\smtp.cred.xml',
    [string]$Destinataire   = 'alerte-froid@exemple.test',
    [string]$Expediteur     = 'alerte-froid@exemple.test',
    [string]$ServeurSmtp    = 'smtp.exemple.test',
    [int]   $PortSmtp       = 587
)

function Write-Journal {
    param([string]$Message)
    $ligne = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    try {
        Add-Content -Path $FichierJournal -Value $ligne -Encoding UTF8 -ErrorAction Stop
    } catch {
        # Si le journal est inaccessible, l'alerte courriel reste prioritaire :
        # on continue plutôt que d'interrompre le script.
        Write-Warning "Journal inaccessible : $($_.Exception.Message)"
    }
}

# --- État du service -------------------------------------------------------

$service = Get-Service -Name $NomService -ErrorAction SilentlyContinue

if ($null -eq $service) {
    # Un service absent est plus grave qu'un service arrêté : il a été
    # désinstallé, renommé, ou le nom attendu est faux.
    $sujet  = '[ALERTE] Chaine du froid - service introuvable'
    $corps  = "Le service '$NomService' est introuvable sur $env:COMPUTERNAME."
}
elseif ($service.Status -ne 'Running') {
    $sujet  = '[ALERTE] Chaine du froid - service arrete'
    $corps  = "Le service '$NomService' est en etat '$($service.Status)' sur $env:COMPUTERNAME."
}
else {
    # Rien à signaler. On sort sans écrire dans le journal, pour éviter
    # de le remplir de lignes inutiles toutes les cinq minutes.
    exit 0
}

Write-Journal $corps

# --- Alerte courriel -------------------------------------------------------

if (-not (Test-Path $FichierIdent)) {
    Write-Journal "Echec de l'alerte : fichier d'identifiants introuvable ($FichierIdent)."
    exit 1
}

try {
    # Import-Clixml ne peut déchiffrer le mot de passe que sous le compte
    # et sur la machine qui ont servi à l'écrire. C'est ce que garantit DPAPI.
    $identifiants = Import-Clixml -Path $FichierIdent

    $parametres = @{
        To         = $Destinataire
        From       = $Expediteur
        Subject    = $sujet
        Body       = "$corps`n`nHorodatage : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        SmtpServer = $ServeurSmtp
        Port       = $PortSmtp
        UseSsl     = $true
        Credential = $identifiants
        Encoding   = [System.Text.Encoding]::UTF8
    }

    Send-MailMessage @parametres -ErrorAction Stop
    Write-Journal 'Alerte envoyee.'
}
catch {
    Write-Journal "Echec de l'envoi de l'alerte : $($_.Exception.Message)"
    exit 1
}

exit 0
