Write-Host "======================================="
Write-Host " FIAP Cloud Games - Local Deploy Script"
Write-Host "======================================="

$ErrorActionPreference = "Stop"

# ----------------------------------------
# CONTEXTO
# ----------------------------------------
# O script SEMPRE roda na raiz do repositório
$ROOT = Get-Location
Write-Host "Diretorio atual: $ROOT"

# ----------------------------------------
# CONFIGURACOES
# ----------------------------------------
$NAMESPACE = "fiap-cloud-games"

$SERVICES = @(
    @{ Name = "payments-api";      Path = "..\payments-api";      Image = "payments-api:latest" },
    @{ Name = "payments-consumer"; Path = "..\payments-consumer"; Image = "payments-consumer:latest" },
    @{ Name = "users-api";         Path = "..\users-api";         Image = "users-api:latest" },
    @{ Name = "games-api";         Path = "..\games-api";         Image = "games-api:latest" },
    @{ Name = "gateway-api";       Path = "..\gateway-api";       Image = "gateway-api:latest" }
)

# ----------------------------------------
# FUNCAO: localizar Dockerfile
# ----------------------------------------
function Find-DockerfileFolder {
    param ([string]$BasePath)

    if (-not (Test-Path $BasePath)) {
        throw "Caminho base nao existe: $BasePath"
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

kubectl apply -f k8s/postgres   -n $NAMESPACE
kubectl apply -f k8s/rabbitmq   -n $NAMESPACE
kubectl apply -f k8s/monitoring -n $NAMESPACE

# ----------------------------------------
# [4/6] MICROSSERVICOS
# ----------------------------------------
Write-Host ""
Write-Host "[4/6] Aplicando microsservicos..."

kubectl apply -f k8s/payments-api      -n $NAMESPACE
kubectl apply -f k8s/payments-consumer -n $NAMESPACE
kubectl apply -f k8s/users-api         -n $NAMESPACE
kubectl apply -f k8s/games-api         -n $NAMESPACE
kubectl apply -f k8s/gateway-api       -n $NAMESPACE

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
