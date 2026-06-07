# Aircrafts Admin
Cliente administrador do sistema de gerenciamento de frotas de aviação comercial.

**Disciplina:** QXD0043 - Sistemas Distribuídos  
**Professor:** Rafael Braga  
**Dupla:** [Anaildo Nascimento] · [Rewelli Oliveira]

---

## Sobre

Interface desktop desenvolvida em Flutter/Dart para o perfil administrador do sistema. Permite gerenciar companhias aéreas e suas frotas via consumo da API REST.

Este cliente faz parte de uma arquitetura distribuída composta por:
- [`aircrafts-api`](#) — servidor Python/FastAPI
- [`aircrafts-admin`](#) — este repositório, cliente administrador (Flutter/Dart)
- [`aircrafts-client`](#) — cliente usuário (React/TypeScript)

---

## Funcionalidades

- Listar companhias aéreas
- Criar e remover companhia
- Listar frota de uma companhia
- Adicionar e remover aeronave
- Notificações em tempo real quando a frota é alterada

---

## Tecnologias

- [Flutter](https://flutter.dev) — framework de UI multiplataforma
- [Dart](https://dart.dev) — linguagem de programação
- [http](https://pub.dev/packages/http) — chamadas REST para a API
- [redis](https://pub.dev/packages/redis) — subscriber do broker (TB4)

---

## Pré-requisitos

- Flutter SDK 3.x instalado
- API `aircrafts-api` rodando em `http://localhost:8000`
- Redis rodando em `localhost:6379` (sobe junto com a API via Docker Compose)

---

## Instalação e execução

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/aircrafts-admin
cd aircrafts-admin

# Instalar dependências
flutter pub get

# Rodar como app desktop Windows
flutter run -d windows
```

---

## Estrutura do projeto

```
lib/
├── main.dart
├── models/
│   ├── companhia.dart
│   └── aeronave.dart
├── services/
│   ├── api_service.dart
│   └── broker_service.dart
└── screens/
    ├── home_screen.dart
    ├── frota_screen.dart
    └── formularios/
        ├── form_companhia.dart
        └── form_aeronave.dart
```

---

## Variáveis de ambiente

Crie um arquivo `.env` na raiz ou edite `lib/services/api_service.dart` com o endereço da API:

```
API_URL=http://localhost:8000
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

## Relacionamento com os outros trabalhos

| Trabalho | O que este cliente cobre |
|---|---|
| TB3 | Consumo da API REST em Dart — linguagem diferente de Python |
| TB4 | Subscriber Redis recebendo eventos do broker em tempo real |