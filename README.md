# FIAP Cloud Games – Arquitetura em Kubernetes

## Visão Geral

Este projeto implementa uma arquitetura de microsserviços para uma plataforma de jogos, desenvolvida como parte da pós-graduação em Arquitetura de Software.  
A solução utiliza Kubernetes como orquestrador, com foco em escalabilidade, observabilidade, mensageria e boas práticas de arquitetura.

Toda a infraestrutura é declarativa e versionada, permitindo reprodutibilidade do ambiente.

---

## Arquitetura da Solução

A arquitetura segue o padrão de microsserviços, onde cada serviço possui responsabilidade única e pode ser escalado de forma independente.

O sistema é composto por APIs síncronas, mensageria assíncrona, banco de dados relacional e uma camada de observabilidade.

---

## Microsserviços

A solução é composta pelos seguintes microsserviços:

- **gateway-api**  
  Atua como ponto de entrada da aplicação, orquestrando chamadas aos demais serviços.

- **users-api**  
  Responsável pelo gerenciamento de usuários.

- **games-api**  
  Responsável pelo gerenciamento de jogos.

- **payments-api**  
  Responsável pelo processamento de pagamentos e publicação de eventos.

- **payments-consumer**  
  Consumidor assíncrono de eventos de pagamento, processando mensagens provenientes do RabbitMQ.

---

## Comunicação

### Comunicação Síncrona

A comunicação síncrona ocorre via HTTP entre o **gateway-api** e os demais microsserviços.  
O Kubernetes Service Discovery é utilizado através do DNS interno do cluster.

### Comunicação Assíncrona

A comunicação assíncrona é realizada via **RabbitMQ**, onde o `payments-api` publica eventos que são consumidos pelo `payments-consumer`.

Esse modelo reduz acoplamento e melhora a resiliência do sistema.

---

## Escalabilidade

Todos os microsserviços possuem **Horizontal Pod Autoscaler (HPA)** configurado, baseado na utilização de CPU.

Os deployments definem explicitamente **requests** e **limits** de recursos, permitindo escalabilidade horizontal automática conforme a carga.

> Observação:  
> Em ambiente local (Docker Desktop), a coleta de métricas de CPU apresenta limitações inerentes ao Metrics Server.  
> Em ambientes de cloud gerenciada (EKS, AKS, GKE), o autoscaling funciona de forma nativa.

---

## Observabilidade

A observabilidade do sistema é garantida através do uso de **Prometheus** e **Grafana**, ambos executando no cluster Kubernetes.

- O **Prometheus** coleta métricas de todos os microsserviços por meio do endpoint `/metrics`.
- O **Grafana** consome essas métricas para visualização e monitoramento do sistema.

Essa abordagem permite acompanhar a saúde e o comportamento dos serviços em tempo real.

---

## Infraestrutura

A infraestrutura do projeto inclui:

- **Kubernetes** como orquestrador de containers
- **PostgreSQL** como banco de dados relacional (StatefulSet)
- **RabbitMQ** para mensageria assíncrona
- **Prometheus** para coleta de métricas
- **Grafana** para visualização

Todos os componentes são definidos através de manifests YAML versionados.

---

## Como Executar o Projeto

1. Clonar o repositório
2. Habilitar o Kubernetes no Docker Desktop
3. Aplicar os manifests:
   ```bash
   kubectl apply -f k8s/
