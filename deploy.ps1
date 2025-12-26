Write-Host "======================================="
Write-Host " FIAP Cloud Games - Local Deploy Script"
Write-Host "======================================="

$ErrorActionPreference = "Stop"

# -------------------------------
# CONFIGURAÇÕES
# -------------------------------
$NAMESPACE = "fiap-cloud-games"

$SERVICES = @(
    @{
        Name = "payments-api"
        Path = "..\payments-api"
        Image = "payments-api:latest"
    },
    @{
        Name = "payments-consumer"
        Path = "..\payments-consumer"
        Image = "payments-consumer:latest"
    },
    @{
        Name = "users-api"
        Path = "..\users-api"
        Image = "users-api:latest"
    },
    @{
        Name = "games-api"
        Path = "..\games-api"
        Image = "games-api:latest"
    },
    @{
        Name = "gateway-api"
        Path = "..\gateway-api"
        Image = "gateway-api:latest"
    }
)

# -------------------------------
# FUNÇÕES
# -------------------------------

function Find-DockerfileFolder {
    param ([string]$BasePath)

    $dockerfile = Get-ChildItem -Path $BasePath -Recurse -Filter "Dockerfile" -File -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $dockerfile) {
        throw "Dockerfile não encontrado em $BasePath"
    }

    return $dockerfile.Directory.FullName
}

# -------------------------------
# 0️⃣ VALIDAR AMBIENTE
# -------------------------------
Write-Host "`n[0/6] Validando ambiente..."

docker info > $null
kubectl version --client > $null

Write-Host "✅ Docker e Kubernetes OK"

# -------------------------------
# 1️⃣ BUILD DAS IMAGENS
# -------------------------------
Write-Host "`n[1/6] Buildando imagens Docker..."

foreach ($svc in $SERVICES) {
    Write-Host "-> Build $($svc.Name)"

    $dockerPath = Find-DockerfileFolder $svc.Path
    Write-Host "   Dockerfile encontrado em: $dockerPath"

    docker build `
        -t $svc.Image `
        $dockerPath

    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao buildar $($svc.Name)"
    }
}

# -------------------------------
# 2️⃣ CRIAR NAMESPACE (SE NÃO EXISTIR)
# -------------------------------
Write-Host "`n[2/6] Garantindo namespace..."

kubectl get namespace $NAMESPACE > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace $NAMESPACE
    Write-Host "Namespace criado: $NAMESPACE"
} else {
    Write-Host "Namespace já existe"
}

# -------------------------------
# 3️⃣ APLICAR INFRA (DB, MQ, MONITORING)
# -------------------------------
Write-Host "`n[3/6] Aplicando infraestrutura..."

kubectl apply -f k8s/postgres -n $NAMESPACE
kubectl apply -f k8s/rabbitmq -n $NAMESPACE
kubectl apply -f k8s/monitoring/prometheus -n $NAMESPACE
kubectl apply -f k8s/monitoring/grafana    -n $NAMESPACE


# -------------------------------
# 4️⃣ APLICAR MICROSSERVIÇOS
# -------------------------------
Write-Host "`n[4/6] Aplicando APIs..."

kubectl apply -f k8s/payments-api -n $NAMESPACE
kubectl apply -f k8s/payments-consumer -n $NAMESPACE
kubectl apply -f k8s/users-api -n $NAMESPACE
kubectl apply -f k8s/games-api -n $NAMESPACE
kubectl apply -f k8s/gateway-api -n $NAMESPACE

# -------------------------------
# 5️⃣ STATUS FINAL
# -------------------------------
Write-Host "`n[5/6] Status final do cluster:`n"

kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
kubectl get hpa -n $NAMESPACE

Write-Host "`n🚀 Deploy local finalizado com sucesso!"
Write-Host "======================================="
Write-Host " FIAP Cloud Games - Local Deploy Script "
Write-Host "======================================="

$ErrorActionPreference = "Stop"

# ----------------------------------------
# CONFIGURAÇÕES
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
# FUNÇÃO: localizar Dockerfile automaticamente
# ----------------------------------------
function Find-DockerfileFolder {
    param ([string]$BasePath)

    $dockerfile = Get-ChildItem `
        -Path $BasePath `
        -Recurse `
        -Filter "Dockerfile" `
        -File `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $dockerfile) {
        throw "Dockerfile não encontrado em $BasePath"
    }

    return $dockerfile.Directory.FullName
}

# ----------------------------------------
# [0/6] VALIDAR AMBIENTE
# ----------------------------------------
Write-Host "`n[0/6] Validando ambiente..."

# Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker não encontrado. Instale o Docker Desktop."
    exit 1
}

# kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl não encontrado."
    exit 1
}

# Kubernetes ativo?
kubectl cluster-info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Kubernetes NÃO está ativo no Docker Desktop." -ForegroundColor Red
    Write-Host "➡️  Ative em: Docker Desktop > Settings > Kubernetes > Enable Kubernetes"
    Write-Host "➡️  Aguarde o status ficar 'Running' e execute novamente."
    Write-Host ""
    exit 1
}

Write-Host "✅ Docker e Kubernetes OK" -ForegroundColor Green

# ----------------------------------------
# [1/6] BUILD DAS IMAGENS
# ----------------------------------------
Write-Host "`n[1/6] Buildando imagens Docker..."

foreach ($svc in $SERVICES) {
    Write-Host "-> Build $($svc.Name)"

    $dockerPath = Find-DockerfileFolder $svc.Path
    Write-Host "   Dockerfile encontrado em: $dockerPath"

    docker build -t $svc.Image $dockerPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erro ao buildar $($svc.Name)"
        exit 1
    }
}

# ----------------------------------------
# [2/6] GARANTIR NAMESPACE
# ----------------------------------------
Write-Host "`n[2/6] Garantindo namespace..."

kubectl get namespace $NAMESPACE > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace $NAMESPACE
    Write-Host "Namespace criado: $NAMESPACE"
} else {
    Write-Host "Namespace já existe"
}

# ----------------------------------------
# [3/6] INFRAESTRUTURA
# ----------------------------------------
Write-Host "`n[3/6] Aplicando infraestrutura..."

kubectl apply -f k8s/postgres    -n $NAMESPACE
kubectl apply -f k8s/rabbitmq    -n $NAMESPACE
kubectl apply -f k8s/monitoring  -n $NAMESPACE

# ----------------------------------------
# [4/6] MICROSSERVIÇOS
# ----------------------------------------
Write-Host "`n[4/6] Aplicando microsserviços..."

kubectl apply -f k8s/payments-api       -n $NAMESPACE
kubectl apply -f k8s/payments-consumer  -n $NAMESPACE
kubectl apply -f k8s/users-api          -n $NAMESPACE
kubectl apply -f k8s/games-api          -n $NAMESPACE
kubectl apply -f k8s/gateway-api        -n $NAMESPACE

# ----------------------------------------
# [5/6] STATUS FINAL
# ----------------------------------------
Write-Host "`n[5/6] Status final:`n"

kubectl get pods -n $NAMESPACE
kubectl get svc  -n $NAMESPACE
kubectl get hpa  -n $NAMESPACE

Write-Host "`n🚀 Deploy finalizado com sucesso!" -ForegroundColor Green
