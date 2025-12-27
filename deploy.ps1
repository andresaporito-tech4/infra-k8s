Write-Host "======================================="
Write-Host " FIAP Cloud Games - Infra Deploy"
Write-Host "======================================="

$ErrorActionPreference = "Stop"

# ----------------------------------------
# CONTEXTO
# ----------------------------------------
$SCRIPT_DIR = $PSScriptRoot
Set-Location $SCRIPT_DIR
Write-Host "Diretorio de execucao: $SCRIPT_DIR"

# ----------------------------------------
# CONFIGURACOES
# ----------------------------------------
$NAMESPACE = "fiap-cloud-games"

# ----------------------------------------
# [0/4] VALIDAR AMBIENTE
# ----------------------------------------
Write-Host ""
Write-Host "[0/4] Validando ambiente local..."

docker info > $null
kubectl cluster-info > $null

Write-Host "Docker e Kubernetes OK"

# ----------------------------------------
# [1/4] GARANTIR NAMESPACE (IDEMPOTENTE)
# ----------------------------------------
Write-Host ""
Write-Host "[1/4] Garantindo namespace..."

kubectl create namespace $NAMESPACE `
    --dry-run=client `
    -o yaml | kubectl apply -f -

Write-Host "Namespace garantido: $NAMESPACE"

# ----------------------------------------
# [2/4] INFRAESTRUTURA BASE
# ----------------------------------------
Write-Host ""
Write-Host "[2/4] Aplicando infraestrutura base..."

kubectl apply -f k8s/postgres              -n $NAMESPACE
kubectl apply -f k8s/rabbitmq              -n $NAMESPACE
kubectl apply -f k8s/monitoring/prometheus -n $NAMESPACE
kubectl apply -f k8s/monitoring/grafana    -n $NAMESPACE

# ----------------------------------------
# [3/4] STATUS FINAL
# ----------------------------------------
Write-Host ""
Write-Host "[3/4] Status final da infraestrutura:"

kubectl get pods -n $NAMESPACE
kubectl get svc  -n $NAMESPACE

Write-Host ""
Write-Host "Infraestrutura Kubernetes aplicada com sucesso"
Write-Host "======================================="
