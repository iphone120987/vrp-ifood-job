# vrp_ifood_job

Emprego profissional de entregador **iFood** para **vRP** e **vRPex**, com estrutura pronta para configuração, rota de coleta, entrega ao cliente, spawn de veículo, reputação, pagamento configurável e mensagens de debug.

## Recursos

- Compatível com **vRP** e **vRPex**
- Ponto para **iniciar** e **encerrar** expediente
- **Spawn configurável** do veículo de trabalho
- **Ponto(s) de coleta** configuráveis
- **Pontos de entrega** configuráveis
- **Pagamento aleatório** com bônus por reputação
- **Sistema de reputação** com SQL
- **Permissão configurável**
- **Mensagens de debug**
- Estrutura limpa para publicar no **GitHub**

## Estrutura

```bash
vrp_ifood_job/
├─ client/
│  └─ client.lua
├─ server/
│  └─ server.lua
├─ fxmanifest.lua
├─ config.lua
├─ vrp_ifood_job.sql
└─ README.md
```

## Dependências

- vRP ou vRPex
- oxmysql
- Sistema de notify compatível com:

```lua
TriggerClientEvent('Notify', source, tipo, mensagem, tempo)
```

Se sua base usa outro notify, basta editar as funções `notify` e `notifyError` no client/server.

## Instalação

1. Coloque a pasta `vrp_ifood_job` dentro de `resources/[jobs]` ou da pasta que preferir.
2. Importe o arquivo `vrp_ifood_job.sql` no banco de dados.
3. Adicione no `server.cfg`:

```cfg
ensure oxmysql
ensure vrp_ifood_job
```

4. Ajuste os pontos no `config.lua`.
5. Ajuste a permissão em `Config.Permission` caso queira restringir o emprego.

## Configuração principal

### Framework

```lua
Config.Framework = 'auto'
```

Opções:
- `auto`
- `vrp`
- `vrpex`

### Permissão

```lua
Config.Permission = ''
```

- Vazio = qualquer jogador pode trabalhar
- Exemplo com permissão:

```lua
Config.Permission = 'ifood.permissao'
```

### Veículo

```lua
Config.VehicleModel = 'faggio3'
```

### Pagamento

```lua
Config.Payment = {
    min = 450,
    max = 700,
    bonusPerLevel = 25,
    payType = 'money'
}
```

### Ponto inicial

```lua
Config.StartPoint = vec3(-1178.89, -891.52, 13.89)
```

### Spawn do veículo

```lua
Config.VehicleSpawn = {
    coords = vec4(-1183.62, -885.71, 13.76, 303.31)
}
```

### Coleta

```lua
Config.CollectionPoints = {
    vec3(-1193.44, -894.31, 13.99),
    vec3(-1198.97, -892.09, 13.99),
    vec3(-1190.67, -899.42, 13.99)
}
```

### Entregas

Edite livremente a lista `Config.DeliveryPoints`.

## Debug

Ative ou desative em:

```lua
Config.Debug = true
```

As mensagens saem no console com a assinatura:

```text
Sistema editado por Gaby.silva
```

## Banco de dados

A tabela salva:
- reputação do entregador
- quantidade de entregas

## Observações

- O script foi feito com foco em bases **vRP/vRPex**.
- Caso sua base tenha variações de notify, pagamento bancário ou permissões, a adaptação é simples.
- A estrutura já está preparada para expansão com XP, mochila térmica, NPC, animações e checkpoints extras.

## Créditos

**Feito por Gaby.silva**
