Write-Host "======================================="
Write-Host " FIAP Cloud Games - Local Deploy Script"
Write-Host "======================================="

$ErrorActionPreference = "Stop"

# ----------------------------------------
# CONTEXTO CORRETO (RAIZ DO REPO)
# ----------------------------------------
# deploy.ps1 está em infra-k8s/
# raiz do repo = um nivel acima
$SCRIPT_DIR = $PSScriptRoot
$REPO_ROOT  = Resolve-Path "$SCRIPT_DIR\.."

Set-Location $SCRIPT_DIR

Write-Host "Diretorio do script : $SCRIPT_DIR"
Write-Host "Raiz do repositorio : $REPO_ROOT"

# ----------------------------------------
# CONFIGURACOES
# ----------------------------------------
$NAMESPACE = "fiap-cloud-games"

$SERVICES = @(
    @{ Name = "payments-api";      Path = "$REPO_ROOT\payments-api";      Image = "payments-api:latest" },
    @{ Name = "payments-consumer"; Path = "$REPO_ROOT\payments-consumer"; Image = "payments-consumer:latest" },
    @{ Name = "users-api";         Path = "$REPO_ROOT\users-api";         Image = "users-api:latest" },
    @{ Name = "games-api";         Path = "$REPO_ROOT\games-api";         Image = "games-api:latest" },
    @{ Name = "gateway-api";       Path = "$REPO_ROOT\gateway-api";       Image = "gateway-api:latest" }
)

# ----------------------------------------
# FUNCAO: localizar Dockerfile
# ----------------------------------------
function Find-DockerfileFolder {
    param ([string]$BasePath)

    if (-not (Test-Path $BasePath)) {
        throw "Caminho nao existe: $BasePath"
    }

    $dockerfile = Get-ChildItem `
        -Path $BasePath `
        -Recurse `
        -Filter "Dockerfile" `
        -File `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $dockerfile) {
        throw "Dockerfile nao encontrado em $BasePath"
    }

    return $dockerfile.Directory.FullName
}

# ----------------------------------------
# [0/6] VALIDAR AMBIENTE
# ----------------------------------------
Write-Host ""
Write-Host "[0/6] Validando ambiente..."

docker info > $null
kubectl version --client > $null
kubectl cluster-info > $null

Write-Host "Docker e Kubernetes OK"

# ----------------------------------------
# [1/6] BUILD DAS IMAGENS
# ----------------------------------------
Write-Host ""
Write-Host "[1/6] Buildando imagens Docker..."

foreach ($svc in $SERVICES) {
    Write-Host "Build: $($svc.Name)"

    $dockerPath = Find-DockerfileFolder $svc.Path
    Write-Host "Dockerfile em: $dockerPath"

    docker build -t $svc.Image $dockerPath
}

# ----------------------------------------
# [2/6] GARANTIR NAMESPACE
# ----------------------------------------
Write-Host ""
Write-Host "[2/6] Garantindo namespace..."

kubectl get namespace $NAMESPACE > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace $NAMESPACE
    Write-Host "Namespace criado"
} else {
    Write-Host "Namespace ja existe"
}

# ----------------------------------------
# [3/6] INFRAESTRUTURA
# ----------------------------------------
Write-Host ""
Write-Host "[3/6] Aplicando infraestrutura..."

kubectl apply -f "$SCRIPT_DIR\k8s\postgres"   -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\rabbitmq"   -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\monitoring" -n $NAMESPACE

# ----------------------------------------
# [4/6] MICROSSERVICOS
# ----------------------------------------
Write-Host ""
Write-Host "[4/6] Aplicando microsservicos..."

kubectl apply -f "$SCRIPT_DIR\k8s\payments-api"      -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\payments-consumer" -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\users-api"         -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\games-api"         -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\gateway-api"       -n $NAMESPACE

# ----------------------------------------
# [5/6] STATUS FINAL
# ----------------------------------------
Write-Host ""
Write-Host "[5/6] Status final:"

kubectl get pods -n $NAMESPACE
kubectl get svc  -n $NAMESPACE
kubectl get hpa  -n $NAMESPACE

Write-Host ""
Write-Host "Deploy finalizado com sucesso"
Write-Host "======================================="
