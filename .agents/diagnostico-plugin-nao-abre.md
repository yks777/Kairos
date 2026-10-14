# Diagnóstico: por que o Kairos não abre

Data: 2026-10-14 (UTC). Testes executados na máquina do usuário, com o shell Omarchy rodando.

## Resumo (TL;DR)

O plugin **não abre visualmente por causa de um único import quebrado**:

- Arquivo: `components/plan/BoardColumn.qml`, linha 6
- Linha atual (errada): `import "logic/Model.js" as Model`
- Linha correta: `import "../../logic/Model.js" as Model`

Esse caminho relativo resolve para `components/plan/logic/Model.js`, que **não existe**
(o `Model.js` real mora em `logic/` na raiz do plugin). O QML falha em cascata:

`BoardColumn` indisponível → `PlanView` indisponível → `Panel.qml` inteiro não carrega
→ o painel nunca renderiza, mesmo o IPC respondendo `ok` / `isOpen=true`.

O bug existe **tanto na origem** (`/home/yks/Projects/Omarchy/Plugins/io.github.yks777.kairos`)
**quanto na cópia instalada** (`~/.config/omarchy/plugins/io.github.yks777.kairos`),
então corrigir só um lado não basta: corrija na origem e sincronize (cópia como arquivos regulares, sem symlinks).

Nenhum código foi alterado neste diagnóstico — só testes e leitura.

## Evidência 1 — log do shell (prova direta)

`journalctl --user` no boot do shell (2026-10-13 23:29:15) mostra:

```
WARN scene: file:///.../kairos/Panel.qml[173:9]: Type PlanView unavailable
WARN scene: file:///.../kairos/views/PlanView.qml[48:9]: Type BoardColumn unavailable
WARN scene: file:///.../kairos/components/plan/BoardColumn.qml[6:1]: Script file:///.../kairos/components/plan/logic/Model.js unavailable
WARN scene: file:///.../kairos/components/plan/logic/Model.js[-1:-1]: No such file or directory
WARN scene: @shell.qml[1357:-1]: ReferenceError: errorString is not defined
```

As 4 primeiras linhas são a cadeia do bug. A 5ª (`errorString is not defined`)
é um bug secundário do próprio `shell.qml` ao tentar exibir o erro de carregamento —
vale reportar ao Omarchy, mas não é a causa.

## Evidência 2 — varredura de imports (é o único quebrado)

Todos os imports `.js` do plugin foram verificados; só um está errado:

| Arquivo | Import | Resolve? |
|---|---|---|
| `components/plan/BoardColumn.qml:6` | `logic/Model.js` | **NÃO** — `components/plan/logic/` não existe |
| `components/plan/TaskCard.qml:5` | `../../logic/Model.js` | sim (padrão correto) |
| `components/board/BoardColumn.qml:7` | `../../logic/Model.js` | sim |
| demais `components/*`, `services/*`, `views/*`, `Service.qml`, `BarWidget.qml` | caminhos `../../logic/`, `../logic/`, `logic/` | sim |

Ou seja: foi quase certamente um erro de digitação ao criar o `BoardColumn` do `plan`
(o irmão `components/board/BoardColumn.qml` está certo).

## Evidência 3 — por que o painel inteiro morre (e não só a aba Plan)

`Panel.qml` instancia **todas** as views como filhas (`DayView`, `FocusView`, `PlanView`
na linha 173, `StatsView`, `MarketsView`, `SocialView`, `SettingsView`). O QML resolve
os tipos eagerly: um tipo indisponível (`PlanView`, via `BoardColumn`) invalida o
componente `Panel` por completo. Por isso **nenhuma aba abre**, nem mesmo a Day —
e o `grim` capturou só o VS Code, sem nenhum painel visível, embora o IPC dissesse
`isOpen=true`.

## Testes executados em todas as funções (resultado)

### Lógica pura — tudo passa, o bug é só runtime QML

- `node --test tests/`: **90/90 passam, 0 falhas**.
- `python3 -m unittest discover -s tests -p 'test_*.py'`: **14/14 passam**.
- `python3 -m py_compile` nos 7 helpers (`fetch-rates`, `fetch-crypto`, `email-fetch`,
  `obsidian-write`, `social-bridge`, `notification-sound`, `_secure_fetch.py`): todos OK.
- `omarchy plugin validate` na origem e na cópia instalada: exit 0 nos dois.
- `qmllint`: indisponível nesta máquina (sem esse binário no PATH) — pendente.
- Observação: `bash -n` nos scripts `fetch-*` falha porque eles são **Python**, não bash —
  falso-positivo do meu comando, não é bug.

### IPC contra o shell ao vivo (`omarchy-shell io.github.yks777.kairos …`) — o service está saudável

| Comando | Resultado |
|---|---|
| `shell ping` | `ok` |
| `ping` | `ok` |
| `status` | JSON válido (`stateLoaded:true`, timer idle, `khal:true events:0 syncing:true`, obsidian desabilitado, social sem bridge, email sem contas) |
| `isOpen` (antes) | `false` |
| `togglePanel` | `ok` → `isOpen` virou `true` (IPC abre; só não renderiza por causa do bug) |
| `day`, `focus`, `plan`, `stats`, `markets`, `social`, `settings`, `email` | todos `ok` |
| `start` → `pause` → `resume` → `interrupt` → `stop` | todos `ok`; `status` confirmou `flowtime/running` com `elapsedMs` crescendo |
| `startFlowtime`, `refreshSocial`, `refreshEmail` | todos `ok` |
| `finish focus` | `ok` (`finish` sem argumento exige 1 arg — comportamento esperado, não bug) |
| `sendEmail dummy '{}'` | `not-queued` (esperado: sem contas configuradas) |
| `calendar.status`, `obsidian.tasks`, `markets.refresh`, `social.unread`, `email.inbox`, … | `Function not found` — **esperado**: essas funções não existem no `IpcHandler` do `Service.qml`. A superfície real é: `ping, isOpen, togglePanel, day, focus, plan, stats, markets, social, email, settings, refreshSocial, refreshEmail, sendEmail, start, startFlowtime, pause, resume, stop, finish, interrupt, status`. (O `ANALYSIS_REPORT.md` documenta comandos `calendar.*`, `obsidian.*`, `markets.*` etc. que não existem — o relatório está desatualizado nesse ponto.) |

### Registro do plugin na barra — OK, com um alerta

- `omarchy plugin list`: `io.github.yks777.kairos` está **enabled** (`service,bar-widget,panel`).
- `~/.config/omarchy/shell.json`: o widget está no `layout.center` com formato próprio — deve aparecer.
- Alerta (não é a causa, mas vale revisar): `bar.centerAnchor` aponta para `omarchy.clock`,
  que está em `disabledPlugins`. Se após o fix o painel abrir deslocado/estranho, ajuste o anchor.

### Degradações esperadas (não são a causa)

- `social.bridgeAvailable:false` ("No compatible kairos-social-bridge executable…") — o
  `scripts/social-bridge` existe no plugin, mas nenhum daemon/adapter local está provido. Esperado.
- `email.accounts:0` — nenhuma conta configurada. Esperado.
- `obsidian.enabled:false` — vault não configurado. Esperado.
- `calendar.syncing:true` + aviso `vdirsyncer sync: binary could not be found` no journal —
  o binário `vdirsyncer` não está instalado; sync fica pendente. Não impede abrir.
- `Qt.atob` deprecated warnings no journal — cosmético, do shell.

## Como corrigir (1 linha + ritual)

1. Em `components/plan/BoardColumn.qml:6`, trocar para:
   `import "../../logic/Model.js" as Model`
2. Seguir o ritual de `.Agents.md`: `omarchy plugin validate`, testes
   (`node --test tests/`, `python3 -m unittest …`), sincronizar origem → instalado
   com cópia regular, `omarchy restart shell`, `omarchy-shell shell ping`,
   abrir cada view via IPC + screenshot `grim` em Day/Focus/Plan/Stats/Markets/Social/Settings.
3. Confirmar no journal que sumiram os 4 `WARN ... unavailable` do Kairos.
4. Opcional: corrigir/atualizar o `ANALYSIS_REPORT.md` (comandos IPC inexistentes) e
   revisar o `centerAnchor: omarchy.clock` com o clock desabilitado.

## Estado deixado

- Painel fechado via `togglePanel` (`isOpen=false` confirmado), timer em `idle/stopped`
  como estava antes. Nenhum arquivo de código, estado ou configuração foi modificado —
  só leitura, IPC de teste e este diretório `.agents/` com esta nota.

---

## Fix aplicado (2026-10-14, continuação do diagnóstico)

A pedido do usuário, os dois bugs foram corrigidos, o plugin foi reinstalado via
`./install.sh` e tudo foi retestado.

### Mudanças (só 2 linhas, origem + sincronizado no instalado)

1. `components/plan/BoardColumn.qml:6`:
   `import "logic/Model.js" as Model` → `import "../../logic/Model.js" as Model`
   (o fix principal — painel não carregava).
2. `views/PlanView.qml:49` (bug secundário achado no journal pós-fix):
   `panelId: model.id` → `panelId: modelData.id`. O model do `Repeater` é um array JS
   (`service.panelsForBoard(...)`), que expõe `modelData`, não `model.id` — todos os
   outros Repeaters do plugin já usavam `modelData`. Sem isso as colunas do Plan
   nasciam com `panelId` vazio + 4 `Unable to assign [undefined] to QString` no journal.

### Instalação via `./install.sh`

- Rodado da origem; exit 0. O rsync incremental levou só o `BoardColumn.qml`
  (resto já estava em sync); `omarchy plugin validate` passou; plugin re-habilitado;
  shell reiniciado e responsivo (`shell ping → ok`).
- `PlanView.qml` foi sincronizado depois com `cp` + `omarchy plugin validate` (o rsync
  já tinha rodado antes desse segundo fix).
- Pegadinhas do script, para referência futura:
  - a checagem final `omarchy plugin list --json | grep '"id": "<id>"'` dá WARN falso
    (o formato JSON não casa com o grep) — `omarchy plugin list` normal mostra o
    Kairos `enabled`;
  - `omarchy-shell shell rescanPlugins` não imprime nada (função inexistente no shell,
    mas com exit 0, então não quebra o `set -e`).

### Cache QML — etapa obrigatória

Após o rsync, o shell novo ainda logou o erro **antigo** (resolvendo o caminho
`components/plan/logic/Model.js` que já não existia no arquivo). Causa: cache de
bytecode em `~/.cache/quickshell/qmlcache` (8 MB). Foi preciso
`rm -rf ~/.cache/quickshell/qmlcache` + `omarchy restart shell`. Depois disso a
instância nova bootou com **zero** WARNs do Kairos no journal. Lição: todo deploy do
plugin deve limpar esse cache e reiniciar o shell (vale adicionar ao `install.sh`).

### Reteste pós-fix (tudo verde)

- Journal da instância nova: nenhum `unavailable`, `Unable to assign` ou `errorString`.
- IPC: `status` válido; `day/plan/focus/stats/markets/social/settings/email` → `ok`;
  `start` → `flowtime/running` confirmado no `status` → `stop` → `idle/stopped`.
- Visual (`grim`, inspecionado): Day renderiza calendário Outubro/2026 + evento
  "Kairos Test Meeting"; Plan renderiza as 4 colunas (In Progress, Backlog, Done,
  Todo) com "Empty" e "+ Add task". (Antes do fix o screenshot mostrava só o VS Code,
  sem painel algum.)
- `node --test tests/`: **90/90**; `python3 -m unittest`: **14/14**.
- Estado final devolvido: painel fechado (`isOpen=false`), timer `idle/stopped`.
