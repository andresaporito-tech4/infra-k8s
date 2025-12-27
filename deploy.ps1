Write-Host "======================================="
Write-Host " FIAP Cloud Games - Infra Kubernetes"
Write-Host "======================================="

$ErrorActionPreference = "Stop"

# ----------------------------------------
# CONFIGURACOES
# ----------------------------------------
$NAMESPACE  = "fiap-cloud-games"
$SCRIPT_DIR = $PSScriptRoot

Set-Location $SCRIPT_DIR

# ----------------------------------------
# [0/5] VALIDAR AMBIENTE
# ----------------------------------------
Write-Host ""
Write-Host "[0/5] Validando ambiente local..."

docker info > $null
kubectl version --client > $null

Write-Host "Validando cluster Kubernetes..."
kubectl cluster-info > $null

Write-Host "Docker e Kubernetes ativos OK"

# ----------------------------------------
# [1/5] GARANTIR NAMESPACE
# ----------------------------------------
Write-Host ""
Write-Host "[1/5] Garantindo namespace..."

$ns = kubectl get namespace $NAMESPACE -o name --ignore-not-found
if (-not $ns) {
    kubectl create namespace $NAMESPACE
    Write-Host "Namespace criado"
}
else {
    Write-Host "Namespace ja existe"
}

# ----------------------------------------
# [2/5] INFRAESTRUTURA BASE
# ----------------------------------------
Write-Host ""
Write-Host "[2/5] Aplicando infraestrutura base..."

kubectl apply -f "$SCRIPT_DIR\k8s\namespace.yaml"
kubectl apply -f "$SCRIPT_DIR\k8s\postgres"   -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\rabbitmq"   -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\monitoring" -n $NAMESPACE

# ----------------------------------------
# [3/5] MICROSSERVICOS (SOMENTE MANIFESTS)
# ----------------------------------------
Write-Host ""
Write-Host "[3/5] Aplicando manifests de microsservicos..."

kubectl apply -f "$SCRIPT_DIR\k8s\payments-api"      -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\payments-consumer" -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\users-api"         -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\games-api"         -n $NAMESPACE
kubectl apply -f "$SCRIPT_DIR\k8s\gateway-api"       -n $NAMESPACE

# ----------------------------------------
# [4/5] STATUS FINAL
# ----------------------------------------
Write-Host ""
Write-Host "[4/5] Status final do cluster:"

kubectl get pods -n $NAMESPACE
kubectl get svc  -n $NAMESPACE
kubectl get hpa  -n $NAMESPACE

# ----------------------------------------
# [5/5] FINALIZACAO
# ----------------------------------------
Write-Host ""
Write-Host "Infra Kubernetes aplicada com sucesso"
Write-Host "======================================="
