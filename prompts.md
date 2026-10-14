PARTE 1 — FUNDAÇÃO DO PLUGIN KAIROS
INSTRUÇÕES PARA A IA: Este é o primeiro de 6 prompts sequenciais. Você está construindo o plugin Kairos para a barra do Omarchy. Não escreva código ainda. Leia tudo, absorva as regras, e ao final apenas confirme que entendeu e que está pronto para a Parte 2. O código começa na Parte 2.

1. Missão
Kairos (καιρός): o momento oportuno. Não o tempo que passa (chronos), mas o tempo certo de agir.

Kairos é um plugin único para a barra do Omarchy (shell baseada em Quickshell/QML). É um hub de produtividade pessoal que responde, numa só superfície, às perguntas que definem o dia:

Pergunta	Onde é respondida
Que horas são?	Barra (relógio)
No que estou trabalhando?	Barra (timer condicional) + aba Focus
O que tenho hoje?	Aba Day
O que preciso priorizar?	Aba Plan
Como estou indo?	Aba Stats
O que está acontecendo lá fora? Quanto vale agora?	Aba Markets
Quem está falando comigo?	Aba Social (mensagens, chamadas e email)
Filosofia central: o Kairos não duplica fontes de verdade. Ele lê, escreve e apresenta. O estado mora onde já mora:

Domínio	Fonte da verdade
O diário do dia	Obsidian (arquivo .md no vault)
A agenda	khal (via khal list --json)
Mercado e taxas	Yahoo Finance, Binance spot, CoinGecko, open.er-api.com
Email	IMAP/SMTP (protocolos abertos, sem intermediário pago)
Mensagens e chamadas	Daemon local de cada rede (tdlib, wa-cli, signal-cli, etc.)
Sessões de foco	O próprio Kairos (persistido em state.json)
Tarefas da matriz	O próprio Kairos (Eisenhower)
Tarefas do dia	Obsidian (checkboxes - [ ] na nota diária)
2. Identidade do plugin
Plugin ID: io.github.yks777.kairos

Kinds: ["service", "bar-widget", "panel"]

Keep loaded: true

Durante o desenvolvimento: declarar omarchy.clonedFrom: omarchy.clock no manifest. Isso faz o Kairos herdar o slot do relógio stock na barra. Antes de publicar no marketplace, remover esse campo.

3. Regras absolutas — nunca quebrar
3.1. 100% em inglês
Toda string do plugin é em inglês: nomes de variáveis, funções, propriedades, arquivos, comentários, labels de UI, placeholders, tooltips, texto de notificação, headings, README.md, CHANGELOG.md, .Agents.md, manifest.json, mensagens de erro, toasts, estados vazios.

Zero português em qualquer lugar, exceto conteúdo gerado pelo usuário (títulos de tarefas, nomes de eventos, mensagens de chat, assuntos de email).

3.2. 100% gratuito
Nenhuma API paga. Fontes permitidas:

Yahoo Finance (quotes)

Binance spot API (preços de cripto)

CoinGecko public API (metadados de cripto)

open.er-api.com (taxas de câmbio fiat)

IMAP/SMTP (email, protocolos abertos)

Daemons locais (Telegram, WhatsApp, Signal, Matrix)

Sem cadastro, sem chave obrigatória, sem assinatura.

3.3. Apenas glyphs Nerd Font. Nenhum emoji. Nunca.
Todo ícone é um glyph Nerd Font (Private Use Area). Nada da faixa de emoji. Se um glyph parece colorido no editor, está errado.

Tabela de glyphs aprovados:

Uso	Glyph	Nome Nerd Font
Relógio (parado)	``	nf-md-clock-outline
Timer	``	nf-md-timer
Timer rodando	``	nf-md-timer-play
Timer pausado	``	nf-md-timer-pause
Timer parado	``	nf-md-timer-off
Break	``	nf-md-coffee
Telefone	``	nf-md-phone
Chamada perdida	``	nf-md-phone-missed
Chamada recebida	``	nf-md-phone-incoming
Chamada feita	``	nf-md-phone-outgoing
Email	``	nf-md-email
Email aberto	``	nf-md-email-open
Email com anexo	``	nf-md-email-paperclip
Reply	``	nf-md-reply
Reply all	``	nf-md-reply-all
Forward	``	nf-md-share
Archive	``	nf-md-archive
Lixeira	``	nf-md-trash-can
Marcar como lido	``	nf-md-email-check
Marcar como não lido	``	nf-md-email-alert
Inbox	``	nf-md-inbox
Enviados	``	nf-md-send
Rascunho	``	nf-md-file-document-edit
Aviso	``	nf-md-alert
Swap	``	nf-md-swap-horizontal
Clipe	``	nf-md-paperclip
Play	``	nf-md-play
Pause	``	nf-md-pause
Stop	``	nf-md-stop
Engrenagem	``	nf-md-cog
Fechar	×	U+00D7 (único não-emoji simples)
Calendário	``	nf-md-calendar
Chart	``	nf-md-chart-line
Stats	``	nf-md-chart-bar
Checkbox checado	``	nf-md-checkbox-marked-outline
Checkbox vazio	``	nf-md-checkbox-blank-outline
Plus	+	U+002B
Search	``	nf-md-magnify
Localização	``	nf-md-map-marker
Pessoa	``	nf-md-account
Grupo	``	nf-md-account-group
Bell	``	nf-md-bell
Refresh	``	nf-md-refresh
Lua (mercado fechado)	``	nf-md-weather-night
Link externo	``	nf-md-open-in-new
Drag handle	``	nf-md-drag
Chevron esquerda	``	nf-md-chevron-left
Chevron direita	``	nf-md-chevron-right
Seta cima	``	nf-md-arrow-up
Seta baixo	``	nf-md-arrow-down
Star	``	nf-md-star
Star outline	``	nf-md-star-outline
Pasta	``	nf-md-folder
Cadeado	``	nf-md-lock
Chave	``	nf-md-key
Servidor	``	nf-md-server
Se um glyph estiver faltando na versão instalada da Nerd Font, escolher outro do mesmo conjunto semântico. Nunca cair para emoji.

3.4. Um plugin. Três kinds. Um estado.
Sem submódulos como plugins separados. Sem estado duplicado. Service.qml é o dono único de todo estado mutável.

3.5. Sem symlinks
Nenhum arquivo ou pasta do plugin pode ser um symlink. O guia oficial proíbe.

3.6. Timers por wall-clock
Toda matemática de tempo deriva de timestamps de relógio real (deadlineMs - Date.now(), startedAtMs, accumulatedMs). O tick visual (tickVersion) apenas força recomputação de bindings — nunca é a fonte da verdade. É assim que o timer sobrevive a fechar o painel, reload da shell e suspend/resume.

4. Referências oficiais obrigatórias
4.1. O guia que você DEVE ler primeiro
https://plugins.omarchy.org/develop.html

Antes de escrever qualquer linha, abra essa página. Ela define o contrato do plugin, o schema do manifest, os entry points, o comportamento em runtime, os comandos de validação e as regras de publicação. Tudo abaixo assume conformidade com ela.

Pontos críticos extraídos:

Localização: ~/.config/omarchy/plugins/<id>/ com manifest.json na raiz.

Campos do manifest: schemaVersion, id, name, version, kinds, entryPoints.

IDs de terceiros não podem usar o namespace reservado omarchy.*.

Pastas de plugin não podem conter symlinks.

Entry points precisam existir e ser caminhos relativos seguros.

Contrato de runtime do bar widget: open(), close(), toggle(), opened, popoutSwitchClosing, closeForPopoutSwitch(), injectPanel().

Comandos de validação (ambos devem sair com exit 0):

bash
PLUGIN_DIR="$HOME/.config/omarchy/plugins/io.github.yks777.kairos"
omarchy plugin validate "$PLUGIN_DIR"
qmllint -I "$OMARCHY_PATH/shell" \
  "$PLUGIN_DIR/BarWidget.qml" \
  "$PLUGIN_DIR/Panel.qml" \
  "$PLUGIN_DIR/Service.qml"
Teste:

bash
omarchy-shell shell summon io.github.yks777.kairos '{}'   # deve abrir
omarchy-shell shell hide io.github.yks777.kairos          # deve fechar
4.2. Projetos de referência (ler antes de codar)
Projeto	O que reaproveitar
Flowdeck (io.github.yks777.flowdeck)	Service.qml como dono único do estado; Panel.qml standalone carregado pela shell; BarWidget.qml enxuto; primitivos de components/; padrões de logic/; ritual de teste em .Agents.md.
Calendar Clock (derekross.calendar)	Parsing de khal printformats; lookup de ICS; detecção de meeting link; month grid; deduplicação de notificações.
Markets (mn.markets)	Fetch de Yahoo/Binance/CoinGecko; watchlist; chart; detecção de sessão de mercado; staleness.
Converter (roozeec.omarchy-converter)	Pivot USD; tabelas de unidades; PairEditor; tratamento de numpad; scripts shell hardened.
A arquitetura de painel é a do Flowdeck, não a do nested-panel pattern. BarWidget.qml não deve conter um Loader para Panel.qml. Isso cria um painel fantasma sem service — um bug explicitamente documentado no .Agents.md do Flowdeck. O panel-loader da shell carrega Panel.qml de forma standalone.

5. Linguagem visual (design system)
Kairos não inventa tokens. Usa exclusivamente o que o tema do Omarchy expõe via qs.Commons.

5.1. Cores
Token	Uso
Color.popups.background	Fundo do painel
Color.popups.text	Texto principal
Color.popups.border	Bordas, divisores
Color.accent	Destaque, estado ativo, timer rodando
Color.muted	Texto secundário, captions, metadados
Color.urgent	Ações destrutivas, mercado em baixa, chamadas perdidas, email não lido
Verde do tema (de colors.toml)	Mercado em alta (override nas Settings)
Vermelho do tema (de colors.toml)	Mercado em baixa (override nas Settings)
Regra de ouro: nenhuma cor hardcoded. Toda cor é Color.* ou Util.alpha(Color.x, 0.n).

5.2. Tipografia
Token	Onde
Style.font.displayLarge	Contador do timer (18:24)
Style.font.title	KAIROS, SETTINGS
Style.font.body	Texto de corpo, tabs
Style.font.bodySmall	Listas, cards, mensagens
Style.font.caption	Metadados, labels uppercase, timestamps
Letter-spacing de 1–2 em labels uppercase: TODAY, NEXT UP, UNREAD, INBOX.

5.3. Espaçamento
Escala única: Style.space(n). Nada de pixels mágicos.

Uso	Valor
Padding do card	Style.space(12)
Espaço entre seções	Style.space(12)
Espaço entre itens	Style.space(6)
Padding de chip/botão	Style.space(6)–Style.space(10)
Cantos	Style.cornerRadius
5.4. Estados de interação
Hover: tinta accent a 10–18%.

Ativo/selecionado: tinta accent a 20–22%.

Foco de teclado: borda accent, 1px.

Cursor: Qt.PointingHandCursor em tudo clicável.

Drag: ghost pixmap via grabToImage(); alvo pisca em accent.

6. Arquitetura de arquivos
Estrutura completa do plugin:

text
kairos/
├── manifest.json
├── README.md
├── CHANGELOG.md
├── LICENSE
├── .Agents.md
├── BarWidget.qml
├── Service.qml
├── Panel.qml
├── services/
│   ├── CalendarService.qml
│   ├── MarketsService.qml
│   ├── ConverterService.qml
│   ├── SocialService.qml
│   ├── EmailService.qml
│   └── ObsidianService.qml
├── connectors/
│   ├── TelegramConnector.qml
│   ├── WhatsAppConnector.qml
│   ├── SignalConnector.qml
│   ├── DiscordConnector.qml
│   ├── MatrixConnector.qml
│   └── EmailConnector.qml
├── components/
│   ├── Chip.qml
│   ├── FlowButton.qml
│   ├── FlowIconButton.qml
│   ├── FlowInput.qml
│   ├── Header.qml
│   ├── NavigationTabs.qml
│   └── Section.qml
├── views/
│   ├── DayView.qml
│   ├── FocusView.qml
│   ├── PomodoroView.qml
│   ├── FlowtimeView.qml
│   ├── PlanView.qml
│   ├── StatsView.qml
│   ├── MarketsView.qml
│   ├── SocialView.qml
│   └── SettingsView.qml
├── components/day/
│   ├── MonthGrid.qml
│   ├── DayEvents.qml
│   ├── DayTasks.qml
│   └── EventCard.qml
├── components/plan/
│   ├── MatrixColumn.qml
│   ├── MatrixToolbar.qml
│   ├── TaskCard.qml
│   ├── TaskEditor.qml
│   └── CompletedPopup.qml
├── components/markets/
│   ├── Watchlist.qml
│   ├── Chart.qml
│   ├── RangeSelector.qml
│   ├── KeyStats.qml
│   ├── CurrencyChip.qml
│   ├── SymbolSearch.qml
│   ├── PairEditor.qml
│   └── UnitCategoryPicker.qml
├── components/social/
│   ├── AccountTabs.qml
│   ├── UnreadList.qml
│   ├── CallList.qml
│   ├── RingingBanner.qml
│   ├── Conversation.qml
│   └── EmailComposer.qml
├── logic/
│   ├── Model.js
│   ├── TimerEngine.js
│   ├── StatsEngine.js
│   ├── Storage.js
│   ├── ClockModel.js
│   ├── CalendarModel.js
│   ├── MarketsModel.js
│   ├── ConverterModel.js
│   ├── SocialModel.js
│   ├── EmailModel.js
│   ├── ObsidianModel.js
│   └── NumberFormat.js
├── scripts/
│   ├── fetch-rates
│   ├── fetch-crypto
│   ├── obsidian-write
│   └── email-fetch
└── tests/
    ├── model.test.js
    ├── timer-engine.test.js
    ├── stats-engine.test.js
    ├── calendar-model.test.js
    ├── markets-model.test.js
    ├── converter-model.test.js
    ├── social-model.test.js
    ├── email-model.test.js
    └── obsidian-model.test.js
6.1. Regras das camadas
Nada de lógica em .qml além de bindings triviais. Tudo o que dá para testar com node mora em logic/.

logic/*.js são puros. Sem imports de QML. .pragma library no topo. module.exports no final.

Service.qml é o dono único do estado. Views leem propriedades e chamam métodos. BarWidget.qml e Panel.qml nunca mutam estado diretamente.

Services orquestram. services/* fazem o trabalho e expõem dados. Service.qml agrega e despacha.

7. Manifest
json
{
  "schemaVersion": 1,
  "id": "io.github.yks777.kairos",
  "name": "Kairos",
  "version": "1.0.0",
  "author": "Yuri K. S.",
  "license": "MIT",
  "description": "Clock, focus timer, tasks, calendar, Obsidian daily notes, stats, markets, social and email for the Omarchy bar.",
  "kinds": ["service", "bar-widget", "panel"],
  "keepLoaded": true,
  "entryPoints": {
    "service": "Service.qml",
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml"
  },
  "omarchy": {
    "clonedFrom": "omarchy.clock"
  },
  "barWidget": {
    "displayName": "Kairos",
    "description": "Clock with focus timer, calendar and daily productivity",
    "category": "Productivity",
    "allowMultiple": false,
    "defaultSection": "center"
  }
}
Nota: omarchy.clonedFrom fica durante o desenvolvimento. Remover antes de publicar no marketplace.

8. Validação oficial
Ambos os comandos devem sair com exit 0:

bash
PLUGIN_DIR="$HOME/.config/omarchy/plugins/io.github.yks777.kairos"

omarchy plugin validate "$PLUGIN_DIR"

qmllint -I "$OMARCHY_PATH/shell" \
  "$PLUGIN_DIR/BarWidget.qml" \
  "$PLUGIN_DIR/Panel.qml" \
  "$PLUGIN_DIR/Service.qml"
O validador checa: manifest válido, kinds/entry points concordam, arquivos existem, caminhos seguros, sem symlinks, ID de terceiro não usa omarchy.*.

9. Ritual de teste (obrigatório após cada fase)
Toda edição em .qml/.js só está pronta após:

omarchy plugin validate "<dir>" — exit 0.

qmllint nos entry points — exit 0.

node --test tests/ — tudo passa.

Sincronizar para ~/.config/omarchy/plugins/io.github.yks777.kairos/.

omarchy restart shell; sleep 6; omarchy-shell shell ping — esperar ok.

Abrir a view afetada via IPC, tirar screenshot com grim.

Ler o screenshot e conferir visualmente.

Não deixar o ambiente alterado. Confirmar com kairos status.

Criar .Agents.md documentando esse ritual (baseado no do Flowdeck).

10. Regras de segurança
10.1. Scripts shell
Owner check: recusar rodar se o script não pertence ao usuário ou é group/other-writable.

Chain-of-custody do cache: cada componente abaixo de $HOME deve ser diretório real, do usuário ou root, não group/other-writable.

Acesso via FD retido (/proc/self/fd), para que swaps de parent não redirecionem o leaf.

Escrita via rename(2) (atômico; nunca segue symlink).

10.2. Links externos
Permitir apenas https://, http://, zoommtg://, zoomus://, msteams://. Bloquear file://, smb://, javascript: e qualquer outro handler de app.

10.3. Conteúdo de terceiros
Títulos, locais, descrições e nomes de convidados de eventos do khal são mostrados como texto simples. Descrições com links são rebuild de texto escapado. Corpos de notificação são escapados.

Conteúdo de email é sanitizado da mesma forma.

Nomes de anexos são sanitizados antes de serem mostrados.

10.4. Credenciais
Senhas de email são armazenadas em state.json como texto simples (documentado no README). Opcional: usar o keyring do sistema se disponível.

11. Persistência (visão geral)
11.1. Arquivo de estado
Caminho: $XDG_DATA_HOME/kairos/state.json (fallback ~/.local/share/kairos/state.json).

Estrutura:

json
{
  "schemaVersion": 2,
  "settings": {
    "focus": { ... },
    "flowtime": { ... },
    "calendar": { ... },
    "obsidian": { ... },
    "markets": { ... },
    "social": { ... },
    "email": { "accounts": [ ... ], "notifyNew": true, "showPreview": false },
    "bar": { ... },
    "shortcuts": { ... },
    "notifications": { ... }
  },
  "boards": [ ... ],
  "tasks": [ ... ],
  "sessions": [ ... ],
  "activeBoardId": "board-life",
  "activeTaskId": "...",
  "timer": { ... },
  "watchlist": { "symbols": [ ... ] },
  "notified": { "calendar": {}, "markets": {} }
}
11.2. Regras de persistência
Nunca editar state.json com a shell rodando + restart imediato. Se testar com dados falsos, parar a shell, editar, restartar, verificar via IPC.

Backup antes (cp state.json state.json.bak-<date>).

saveSoon() (debounce 800 ms) para a maioria das mutações. saveNow() apenas em eventos críticos (fim de fase, import).

bump() sozinho não persiste.

sanitizeState nunca joga exceção. Entrada corrompida → backup .corrupt-<ts> + blank seguro.

Model.migrate(raw) reconhece schemaVersion 1 (Flowdeck) e converte.

11.3. Caches
~/.cache/omarchy/kairos/markets/rates-USD.json — taxas fiat (6 h)

~/.cache/omarchy/kairos/markets/crypto.json — preços cripto (10 min)

~/.cache/omarchy/kairos/calendar/months.json — meses navegados

~/.cache/omarchy/kairos/email/<accountId>/ — cache de email

~/.local/state/omarchy/kairos/notified.json — eventos já notificados

12. IPC (visão geral)
12.1. Target principal: io.github.yks777.kairos
text
kairos togglePanel
kairos day | focus | plan | stats | markets | social
kairos start | pause | stop | resume
kairos finish focus|break
kairos interrupt
kairos status | today | isOpen | ping
kairos calendar.sync | calendar.refresh | calendar.status
kairos obsidian.open YYYY-MM-DD
kairos obsidian.create
kairos obsidian.tasks
kairos obsidian.toggle <index>
kairos obsidian.add "<text>"
kairos obsidian.status
kairos markets.refresh | markets.pause
kairos markets.currency USD
kairos markets.convert.rate USD EUR
kairos markets.convert.amount 100 USD EUR
kairos markets.convert.unit 100 length m ft
kairos social.telegram.send "<chatId>" "<msg>"
kairos social.whatsapp.send "<phone>" "<msg>"
kairos social.calls
kairos social.unread
kairos email.accounts
kairos email.inbox <accountId>
kairos email.send <accountId> "<to>" "<subject>" "<body>"
kairos email.reply <accountId> "<messageId>" "<body>"
12.2. Target herdado: omarchy.clock
text
omarchy-shell omarchy.clock refresh
omarchy-shell omarchy.clock toggle
omarchy-shell omarchy.clock cycleFormat
omarchy-shell omarchy.clock toggleWeekStart
Esses devem continuar funcionando para que scripts e keybinds que falam com o relógio stock não quebrem.

13. Atalhos globais
Registrados via hyprctl eval + hl.bind(...). Rebind em configreloaded.

Ação	Padrão
Toggle painel	Super+H
Start/pause timer	Super+Shift+H
Start Flowtime direto	Super+Alt+H
✅ CHECKPOINT DA PARTE 1
Você absorveu:

Missão do Kairos e sua filosofia de não duplicar fontes de verdade.

Identidade do plugin (io.github.yks777.kairos, três kinds).

Regras absolutas: 100% inglês, 100% gratuito, apenas Nerd Font glyphs, sem symlinks, wall-clock timers.

Referências oficiais: guia do Omarchy e projetos de referência (Flowdeck, Calendar Clock, Markets, Converter).

Design system: cores, tipografia, espaçamento, estados de interação — tudo vindo do tema via qs.Commons.

Arquitetura de arquivos completa.

Manifest com os três entry points.

Validação oficial e ritual de teste.

Segurança, persistência e IPC em alto nível.


# PARTE 2 — BAR WIDGET E ESTRUTURA DO PAINEL

> **INSTRUÇÕES PARA A IA:** Este é o segundo de 6 prompts sequenciais. Você já absorveu a fundação na Parte 1. Agora começa a **implementação real**. O foco desta parte é: `Service.qml` (esqueleto), `BarWidget.qml` (relógio + timer condicional), `Panel.qml` (estrutura do painel), e os componentes primitivos. **Não implemente nenhuma das 6 abas ainda** — apenas placeholders vazios. As abas vêm nas Partes 3–6.

---

## 1. Escopo da Parte 2

Ao final desta parte, você deve ter:

1. **`Service.qml`** — esqueleto com estado vazio, persistência funcionando, IPC básico (`ping`, `status`, `isOpen`, `togglePanel`, `day|focus|plan|stats|markets|social`), e registro de atalhos globais.
2. **`BarWidget.qml`** — relógio funcional (formatos, ciclo, timezone) + segmento de timer condicional.
3. **`Panel.qml`** — painel standalone com `KeyboardPanel`, header, tabs, e 6 placeholders vazios.
4. **Componentes primitivos** — `Chip`, `FlowButton`, `FlowIconButton`, `FlowInput`, `Header`, `NavigationTabs`, `Section`.
5. **`logic/Storage.js`** — paths XDG (se ainda não existir).
6. **`logic/ClockModel.js`** — formatação e ciclo de formato (se ainda não existir).
7. **`manifest.json`** — confirmar que está com os três kinds e entry points corretos.
8. **`.Agents.md`** — ritual de teste documentado.

**Não fazer:** abas, calendário, obsidian, khal, market data, social, email.

---

## 2. `Service.qml` — o dono único do estado

### 2.1. Responsabilidade

`Service.qml` é a **única** fonte de verdade mutável do plugin. `BarWidget.qml` e `Panel.qml` nunca mantêm cópias concorrentes — eles leem propriedades do Service e chamam seus métodos.

### 2.2. Propriedades injetadas pela shell

```qml
Item {
  id: root

  // Injetadas pela shell no carregamento.
  property var shell: null
  property var manifest: null
  property string omarchyPath: ""
}
```

### 2.3. Estado canônico

```qml
  // ---- Estado canônico (sempre substituído, nunca mutado in-place) ----
  property var settings: Model.defaultSettings()
  property var boards: Model.defaultBoards()
  property var tasks: []
  property var sessions: []
  property string activeBoardId: "board-life"
  property string activeTaskId: ""
  property var timer: Model.blankTimer()

  // ---- Sinais de mudança para forçar recomputação de bindings ----
  property int revision: 0        // qualquer mutação de dados
  property int tickVersion: 0     // tick de 1 Hz enquanto o timer roda

  // ---- Estado de carregamento ----
  property bool stateLoaded: false
  property string stateFilePath: ""
  property string stateDirPath: ""
```

### 2.4. Helpers de tempo

```qml
  function nowMs() { return Date.now(); }

  function timerRemainingMs() {
    return TimerEngine.pomodoroRemainingMs(root.timer, root.nowMs());
  }

  function flowElapsedMs() {
    return TimerEngine.flowElapsedMs(root.timer, root.nowMs());
  }

  function isTicking() {
    return root.timer.phase === "running" || root.timer.phase === "break";
  }

  function bump() { root.revision++; }
```

### 2.5. Persistência

```qml
  FileView {
    id: stateFile
    watchChanges: false
    atomicWrites: true
    onLoaded: root.applyLoadedText(text())
    onLoadFailed: function(error) {
      root.applyBlank();
      console.warn("Kairos: state load failed, starting fresh: " + error);
    }
  }

  Timer {
    id: saveDebounce
    interval: 800
    onTriggered: root.saveNow()
  }

  function saveSoon() {
    if (!root.stateLoaded) return;
    saveDebounce.restart();
  }

  function saveNow() {
    if (!root.stateLoaded || root.stateFilePath === "") return;
    try {
      stateFile.setText(root.serializeState());
    } catch (e) {
      console.warn("Kairos: save failed: " + e);
    }
  }

  function serializeState() {
    return JSON.stringify({
      schemaVersion: 2,
      settings: root.settings,
      boards: root.boards,
      tasks: root.tasks,
      sessions: root.sessions,
      activeBoardId: root.activeBoardId,
      activeTaskId: root.activeTaskId === "" ? null : root.activeTaskId,
      timer: root.timer
    }, null, 2) + "\n";
  }

  function applyBlank() {
    var clean = Model.blankState();
    root.applyState(clean);
    root.stateLoaded = true;
    root.saveNow();
  }

  function applyLoadedText(text) {
    var raw = null;
    try {
      raw = JSON.parse(text);
    } catch (e) {
      console.warn("Kairos: corrupt state, starting fresh");
      root.applyBlank();
      return;
    }
    var res = Model.sanitizeState(raw);
    root.applyState(res.state);
    root.stateLoaded = true;
    if (res.repaired) root.saveNow();
  }

  function applyState(s) {
    root.settings = s.settings;
    root.boards = s.boards;
    root.tasks = s.tasks;
    root.sessions = s.sessions;
    root.activeBoardId = s.activeBoardId;
    root.activeTaskId = s.activeTaskId || "";
    root.timer = s.timer;
    root.bump();
  }
```

### 2.6. Loops de tempo

```qml
  Timer {
    id: tick
    interval: 1000
    repeat: true
    running: root.isTicking()
    onTriggered: root.onTick()
  }

  function onTick() {
    root.tickVersion++;
    var t = root.timer;
    if (t.phase !== "running" && t.phase !== "break") return;
    if (t.mode === "flowtime" && t.phase === "running") return;
    if ((t.deadlineMs || 0) > root.nowMs()) return;
    // Fase 4 vai preencher este switch com completePomodoro/completeBreak.
  }
```

### 2.7. IPC

```qml
  IpcHandler {
    target: "io.github.yks777.kairos"

    function ping(): string { return "ok"; }
    function isOpen(): string {
      if (root.shell && typeof root.shell.isPluginOpen === "function")
        return root.shell.isPluginOpen("io.github.yks777.kairos") ? "true" : "false";
      return "unknown";
    }
    function togglePanel(): string {
      if (root.shell && typeof root.shell.toggle === "function")
        root.shell.toggle("io.github.yks777.kairos", "{}");
      return "ok";
    }
    function day(): string { root.openView("day"); return "ok"; }
    function focus(): string { root.openView("focus"); return "ok"; }
    function plan(): string { root.openView("plan"); return "ok"; }
    function stats(): string { root.openView("stats"); return "ok"; }
    function markets(): string { root.openView("markets"); return "ok"; }
    function social(): string { root.openView("social"); return "ok"; }
    function status(): string {
      return JSON.stringify({
        timer: { mode: root.timer.mode, phase: root.timer.phase },
        revision: root.revision,
        stateLoaded: root.stateLoaded
      });
    }
  }

  property string pendingView: ""

  function openView(view) {
    root.pendingView = String(view || "day");
    if (root.shell && typeof root.shell.summon === "function")
      root.shell.summon("io.github.yks777.kairos", JSON.stringify({ view: root.pendingView }));
  }

  function consumePendingView() {
    var v = root.pendingView;
    root.pendingView = "";
    return v;
  }
```

### 2.8. Atalhos globais (Hyprland)

```qml
  property var appliedShortcutChords: []

  function shortcutChordOf(id) {
    return String(id || "").split("+").map(function(k) { return k.trim().toUpperCase(); }).join(" + ");
  }

  function applyShortcuts() {
    var lines = [];
    var chords = [];
    for (var i = 0; i < root.appliedShortcutChords.length; i++)
      lines.push('pcall(function() hl.unbind("' + root.appliedShortcutChords[i] + '") end)');

    var binds = [
      { id: root.settings.shortcuts.toggleShortcut, cmd: "omarchy-shell io.github.yks777.kairos togglePanel" },
      { id: root.settings.shortcuts.focusShortcut, cmd: "omarchy-shell io.github.yks777.kairos start" }
    ];
    for (var j = 0; j < binds.length; j++) {
      if (!binds[j].id) continue;
      var chord = root.shortcutChordOf(binds[j].id);
      chords.push(chord);
      lines.push('pcall(function() hl.unbind("' + chord + '") end)');
      lines.push('hl.bind("' + chord + '", hl.dsp.exec_cmd("' + binds[j].cmd + '"), { description = "Kairos" })');
    }
    root.appliedShortcutChords = chords;
    if (lines.length > 0) Quickshell.execDetached(["hyprctl", "eval", lines.join("; ")]);
  }
```

### 2.9. `Component.onCompleted`

```qml
  Component.onCompleted: {
    var dir = Storage.dataDir(Quickshell.env);
    var path = Storage.statePath(Quickshell.env);
    root.stateDirPath = dir;
    root.stateFilePath = path;

    mkdirProc.command = ["mkdir", "-p", dir];
    mkdirProc.running = true;

    stateFile.path = path;
    root.applyShortcuts();
  }

  Process { id: mkdirProc }
```

---

## 3. `BarWidget.qml` — o relógio e o timer

### 3.1. Regra: no máximo dois segmentos

A barra mostra **apenas o relógio** por padrão. Um **segundo segmento** aparece à direita do relógio quando um timer de foco está ativo.

### 3.2. Estado parado (padrão)

```
┌──────────────────────┐
│      Wed 15:42       │
└──────────────────────┘
```

Comportamento idêntico ao `omarchy.clock`:

- Texto: `Qt.formatDateTime(new Date(), activeFormat)`.
- Presets de formato: `format` (padrão `dddd HH:mm`) e `formatAlt` (padrão `d MMMM 'W'ww yyyy`).
- Vertical: `verticalFormat` (padrão `HH\n—\nmm`).
- Token ISO week `ww` substituído por `ClockModel.isoWeekLiteral()` antes da formatação.

| Clique | Ação |
|---|---|
| Esquerdo | Abre o painel na aba **Day** |
| Direito | Cicla formato; persiste em `shell.json` via `shell.updateEntryInline` |
| Meio | Executa `omarchy-menu-timezone` |

### 3.3. Estado com timer ativo

```
┌──────────────┬───────────┐
│  Wed 15:42   │  ⏱ 18:24  │
└──────────────┴───────────┘
```

O segmento de timer aparece **à direita** do relógio, gap `Style.space(6)`. Desaparece quando o timer está `stopped` ou `idle`.

| Estado | Glyph | Cor |
|---|---|---|
| Pomodoro rodando | `<timer-icon> MM:SS` | `Color.accent` |
| Flowtime rodando | `<timer-icon> MM:SS` | `Color.accent` |
| Pausado | `<timer-pause-icon> MM:SS` | `Color.muted` |
| Break | `<coffee-icon> MM:SS` | `Color.accent` |

Formato adaptativo via `Model.formatClock(seconds)`:
- `SS` abaixo de um minuto
- `MM:SS` abaixo de uma hora
- `HH:MM:SS` em uma hora ou mais

| Clique | Ação |
|---|---|
| Esquerdo | Abre o painel na aba **Focus** |
| Direito | Stop (confirma se rodando) |
| Meio | Pause / Resume |

### 3.4. Barra vertical

O relógio usa `verticalFormat` (multi-linha). O timer aparece **abaixo**, em duas linhas (`MM\nSS`). Some quando parado.

```
┌──────┐
│ Wed  │
│  —   │
│ 15   │
│ 42   │
├──────┤
│ 18   │
│ 24   │
└──────┘
```

### 3.5. Implementação

```qml
BarWidget {
  id: root
  moduleName: "io.github.yks777.kairos"

  readonly property var kairosService: {
    try {
      if (root.bar && root.bar.shell && typeof root.bar.shell.serviceFor === "function")
        return root.bar.shell.serviceFor(root.moduleName);
    } catch (e) {}
    return null;
  }

  // Relógio local: força bindings de texto/tooltip a cada segundo.
  property int nowTick: 0
  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.nowTick++
  }

  // ---- Texto do relógio (formatos herdados do omarchy.clock) ----
  readonly property string clockText: {
    var date = new Date();
    void root.nowTick;
    var fmt = root.vertical
      ? setting("verticalFormat", "HH\n—\nmm")
      : setting("format", "dddd HH:mm");
    return Qt.formatDateTime(date, ClockModel.substituteIsoWeek(fmt, date));
  }

  // ---- Timer: só aparece quando ativo ----
  readonly property bool timerActive: {
    var svc = root.kairosService;
    if (!svc || !svc.timer) return false;
    return svc.timer.phase === "running"
        || svc.timer.phase === "break"
        || svc.timer.phase === "paused";
  }

  readonly property string timerText: {
    if (!root.timerActive) return "";
    var svc = root.kairosService;
    void root.nowTick;
    try { void svc.tickVersion; } catch (e) {}
    var t = svc.timer;
    var ms = 0;
    if (t.phase === "running" || t.phase === "break") {
      if (t.mode === "flowtime" && t.phase === "running") ms = svc.flowElapsedMs();
      else ms = svc.timerRemainingMs();
    } else if (t.phase === "paused") {
      if (t.mode === "flowtime") ms = svc.flowElapsedMs();
      else ms = Math.max(0, t.pausedRemainingMs || 0);
    }
    return Model.formatClock(Math.floor(ms / 1000));
  }

  readonly property string timerGlyph: {
    if (!root.timerActive) return "";
    var t = root.kairosService.timer;
    if (t.phase === "paused") return "\uf4b6";        // nf-md-timer-pause
    if (t.phase === "break") return "\uf0177";        // nf-md-coffee
    return "\uf4b4";                                   // nf-md-timer
  }

  readonly property color timerColor: {
    if (!root.timerActive) return Color.accent;
    return root.kairosService.timer.phase === "paused" ? Color.muted : Color.accent;
  }

  // ---- Contrato de runtime do bar widget ----
  readonly property bool opened: panelOpen
  property bool panelOpen: false

  function open() { root.panelOpen = true; }
  function close() { root.panelOpen = false; }
  function togglePanel() { root.panelOpen = !root.panelOpen; }

  function openPanelOn(view) {
    if (root.bar && root.bar.shell && typeof root.bar.shell.summon === "function")
      root.bar.shell.summon(root.moduleName, JSON.stringify({ view: view }));
  }

  function cycleFormat() {
    var current = setting(root.vertical ? "verticalFormat" : "format", "");
    var next = ClockModel.nextFormat(current);
    // Persiste em shell.json via updateEntryInline.
    // (implementação detalhada vem da referência do omarchy.clock)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Row {
    id: button
    spacing: Style.space(6)

    // Segmento 1: relógio
    WidgetButton {
      id: clockButton
      bar: root.bar
      text: root.vertical ? "" : root.clockText
      labelVisible: !root.vertical
      onPressed: function(b) {
        if (b === Qt.RightButton) root.cycleFormat();
        else if (b === Qt.MiddleButton) { if (root.bar) root.bar.run("omarchy-menu-timezone"); }
        else root.openPanelOn("day");
      }
    }

    // Segmento 2: timer (só se ativo)
    WidgetButton {
      id: timerButton
      visible: root.timerActive && !root.vertical
      bar: root.bar
      text: root.timerGlyph + " " + root.timerText
      foreground: root.timerColor
      onPressed: function(b) {
        var svc = root.kairosService;
        if (!svc) return;
        if (b === Qt.RightButton) svc.stopTimer();
        else if (b === Qt.MiddleButton) {
          if (svc.timer.phase === "paused") svc.resumeTimer();
          else svc.pauseTimer();
        } else root.openPanelOn("focus");
      }
    }
  }
}
```

---

## 4. `Panel.qml` — a estrutura do painel

### 4.1. Visão geral

```
┌─────────────────────────────────────────────────────────────────────┐
│  KAIROS   Stay Hard                                    ⚙    ×       │
├─────────────────────────────────────────────────────────────────────┤
│  [Day] [Focus] [Plan] [Stats] [Markets] [Social]                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  CONTENT (varia por aba)                                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

Implementação: `KeyboardPanel` centrado na tela. Usa `centerOnBar: true`, `anchorItem` interno, um `barShim` (para o caso em que o loader não injeta um `bar` real), `gap` reativo e `contentHeight` manual.

### 4.2. Propriedades injetadas pela shell

```qml
Panel {
  id: root
  moduleName: "io.github.yks777.kairos"
  manageIpc: false

  // Injetadas pela shell no onLoaded do panel-loader.
  property var shell: null
  property var manifest: null
  property var service: null
  property string omarchyPath: ""

  property var anchorItem: null
  property var hostWidget: null

  readonly property var barIdentity: hostWidget || root
}
```

### 4.3. `barShim` — o substituto quando o loader não injeta `bar`

```qml
  readonly property QtObject barShim: QtObject {
    property string position: "bottom"
    property int barSize: 0
    property var activePopout: null
    function requestPopout(owner) {}
    function releasePopout(owner) {}
  }
```

### 4.4. Estado interno do painel

```qml
  property string currentView: "day"
  property string returnView: "day"

  function pluginId() {
    if (root.manifest && root.manifest.id) return String(root.manifest.id);
    return "io.github.yks777.kairos";
  }

  function open(payloadJson) {
    var payload = {};
    try { payload = JSON.parse(payloadJson || "{}") || {}; } catch (e) {}
    var view = String(payload.view || "");
    if (root.service) {
      var pending = "";
      try { pending = String(root.service.consumePendingView() || ""); } catch (e2) {}
      if (view === "") view = pending;
    }
    if (["day", "focus", "plan", "stats", "markets", "social", "settings"].indexOf(view) !== -1)
      root.currentView = view;
    root.controller.show();
    Qt.callLater(function() { if (root.opened) keyCatcher.forceActiveFocus(); });
  }

  function close() { root.controller.hide(); }
  function toggle() { if (root.opened) root.close(); else root.open(); }
  function dismiss() { root.close(); }
  function goSettings() { root.currentView = "settings"; }
```

### 4.5. Dimensões por aba

```qml
  readonly property int cardWidth: {
    if (root.currentView === "plan") return Style.space(880);
    if (root.currentView === "markets") return Style.space(640);
    if (root.currentView === "social") return Style.space(620);
    if (root.currentView === "day") return Style.space(560);
    if (root.currentView === "stats") return Style.space(480);
    if (root.currentView === "settings") return Style.space(460);
    return Style.space(400); // focus
  }

  readonly property int contentHeight: {
    if (root.currentView === "plan") return Style.space(500);
    if (root.currentView === "markets") return Style.space(520);
    if (root.currentView === "social") return Style.space(620);
    if (root.currentView === "day") return Style.space(620);
    if (root.currentView === "stats") return Style.space(540);
    if (root.currentView === "settings") return Style.space(560);
    return Style.space(460); // focus
  }
```

### 4.6. Estrutura QML

```qml
  KeyboardPanel {
    id: panel
    anchorItem: centerAnchor
    owner: root.barIdentity
    bar: root.barShim
    open: root.opened
    centerOnBar: true
    gap: panel.screenH / 2 - panel.barH
       - (cardContent.implicitHeight + panel.verticalContentInset) / 2
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.cardWidth)
    contentHeight: Math.min(
      cardContent.implicitHeight + panel.verticalContentInset,
      Math.max(120, panel.screenH - (Style.bar.sizeHorizontal + Style.gapsOut * 2))
    )

    Item { id: centerAnchor; anchors.fill: parent }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.dismiss()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ColumnLayout {
        id: cardContent
        width: parent.width
        spacing: Style.space(8)

        Header {
          boardTitle: root.service ? root.service.boards[0].title : ""
          onOpenSettings: root.goSettings()
          onClosePanel: root.dismiss()
        }

        NavigationTabs {
          currentView: root.currentView === "settings" ? root.returnView : root.currentView
          visible: root.currentView !== "settings"
          onSelectView: function(view) { root.currentView = view; }
        }

        // ---- Placeholders das abas (serão preenchidos nas Partes 3–6) ----

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "day"
          // DayView virá na Parte 3
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "focus"
          // FocusView virá na Parte 4
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "plan"
          // PlanView virá na Parte 4
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "stats"
          // StatsView virá na Parte 5
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "markets"
          // MarketsView virá na Parte 5
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "social"
          // SocialView virá na Parte 6
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "settings"
          // SettingsView virá na Parte 6
        }
      }
    }
  }
```

---

## 5. Componentes primitivos

### 5.1. `components/Chip.qml`

Chip toggle usado em tabs e filtros.

```qml
import QtQuick
import qs.Commons

Item {
  id: root
  property string label: ""
  property bool active: false
  signal clicked()

  implicitWidth: Math.max(72, chipLabel.implicitWidth + Style.space(16))
  implicitHeight: Style.space(26)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Color.accent
    opacity: root.active ? 0.22 : 0.0
    border.color: root.active ? Color.accent : Color.popups.border
    border.width: Math.max(1, Style.space(1))
  }
  Text {
    id: chipLabel
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.label
    color: root.active ? Color.accent : Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
```

### 5.2. `components/FlowButton.qml`

Botão primário/secundário.

```qml
import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string text: ""
  property bool primary: false
  property bool enabledButton: true
  signal clicked()

  implicitWidth: Math.max(64, label.implicitWidth + Style.space(24))
  implicitHeight: Style.space(32)
  radius: Style.cornerRadius
  opacity: root.enabledButton ? 1.0 : 0.45

  color: "transparent"
  border.color: root.primary ? Color.accent : Color.popups.border
  border.width: Math.max(1, Style.space(1))

  Rectangle {
    anchors.fill: parent
    anchors.margins: parent.border.width
    radius: Math.max(0, parent.radius - parent.border.width)
    color: Color.accent
    opacity: root.primary ? 0.22 : 0.0
    visible: root.primary
  }

  Text {
    id: label
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.text
    color: root.primary ? Color.accent : Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabledButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
```

### 5.3. `components/FlowIconButton.qml`

Botão ícone quadrado.

```qml
import QtQuick
import qs.Commons

Item {
  id: root
  property string glyph: ""
  property int boxSize: 32
  property bool highlighted: false
  property string tip: ""
  signal clicked()

  implicitWidth: boxSize
  implicitHeight: boxSize

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Color.accent
    opacity: (hover.containsMouse || root.highlighted) ? 0.18 : 0.0
  }

  Text {
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.glyph
    color: root.highlighted ? Color.accent : Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.title
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
```

### 5.4. `components/FlowInput.qml`

Campo de texto single-line.

```qml
import QtQuick
import qs.Commons

Rectangle {
  id: root
  property alias text: input.text
  property string placeholder: ""
  property bool numbersOnly: false
  signal accepted()
  signal cancelled()

  implicitWidth: 160
  implicitHeight: Style.space(32)
  radius: Style.cornerRadius
  color: "transparent"
  border.color: input.activeFocus ? Color.accent : Color.popups.border
  border.width: Math.max(1, Style.space(1))

  Text {
    anchors.fill: parent
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    text: root.placeholder
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    visible: input.text === "" && !input.activeFocus
    elide: Text.ElideRight
  }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    verticalAlignment: TextInput.AlignVCenter
    color: Color.popups.text
    selectionColor: Color.accent
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    inputMethodHints: root.numbersOnly ? Qt.ImhDigitsOnly : Qt.ImhNone
    validator: root.numbersOnly ? intValidator : null
    onAccepted: { input.focus = false; root.accepted(); }
    Keys.onEscapePressed: { input.focus = false; root.cancelled(); }
  }

  IntValidator { id: intValidator; bottom: 0; top: 1000000; }

  function focusInput() {
    input.forceActiveFocus();
    input.selectAll();
  }
}
```

### 5.5. `components/Header.qml`

Cabeçalho do painel.

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property string boardTitle: ""
  signal openSettings()
  signal closePanel()

  spacing: Style.space(8)
  Layout.fillWidth: true

  Text {
    textFormat: Text.PlainText
    text: "KAIROS"
    color: Color.accent
    font.family: Style.font.family
    font.pixelSize: Style.font.title
    font.letterSpacing: 2
  }

  Text {
    textFormat: Text.PlainText
    text: root.boardTitle
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
    Layout.fillWidth: true
  }

  FlowIconButton {
    glyph: "\uf0493"     // nf-md-cog
    tip: "Settings"
    onClicked: root.openSettings()
  }

  FlowIconButton {
    glyph: "×"
    tip: "Close"
    onClicked: root.closePanel()
  }
}
```

### 5.6. `components/NavigationTabs.qml`

Tabs de topo.

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property string currentView: "day"
  signal selectView(string view)

  spacing: Style.space(4)
  Layout.fillWidth: true

  Repeater {
    model: [
      { id: "day", label: "Day" },
      { id: "focus", label: "Focus" },
      { id: "plan", label: "Plan" },
      { id: "stats", label: "Stats" },
      { id: "markets", label: "Markets" },
      { id: "social", label: "Social" }
    ]
    delegate: Item {
      id: tab
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: Style.space(32)

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Color.accent
        opacity: root.currentView === tab.modelData.id ? 0.20 : 0.0
      }
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(1, Style.space(2))
        color: Color.accent
        visible: root.currentView === tab.modelData.id
      }
      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: tab.modelData.label
        color: root.currentView === tab.modelData.id ? Color.accent : Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectView(tab.modelData.id)
      }
    }
  }
}
```

### 5.7. `components/Section.qml`

Seção com título e divisor (será usada em Settings e outras views).

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: sec
  property string title: ""
  spacing: Style.space(8)
  Layout.fillWidth: true
  Layout.leftMargin: Style.space(4)
  Layout.rightMargin: Style.space(4)

  Text {
    textFormat: Text.PlainText
    text: sec.title.toUpperCase()
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
  }
  Rectangle {
    height: Math.max(1, Style.space(1))
    color: Color.popups.border
    opacity: 0.5
    Layout.fillWidth: true
  }
}
```

---

## 6. `logic/Storage.js` e `logic/ClockModel.js`

### 6.1. `logic/Storage.js`

```js
.pragma library

function dataDir(env) {
  var xdg = env("XDG_DATA_HOME") || "";
  if (xdg !== "") return xdg.replace(/\/$/, "") + "/kairos";
  var home = env("HOME") || "";
  return home + "/.local/share/kairos";
}

function statePath(env) {
  return dataDir(env) + "/state.json";
}
```

### 6.2. `logic/ClockModel.js`

```js
.pragma library

var FORMATS = [
  "dddd HH:mm",
  "dddd h:mm AP",
  "HH:mm",
  "h:mm AP",
  "ddd d MMM HH:mm",
  "ddd d MMM h:mm AP",
  "d MMMM 'W'ww yyyy",
  "yyyy-MM-dd HH:mm"
];

var VERTICAL_FORMATS = [
  "HH\n—\nmm",
  "h\n—\nmm\nAP",
  "dd\nMMM\n'W'ww\n''yy",
  "HH\nmm"
];

function formats(vertical) {
  return vertical ? VERTICAL_FORMATS.slice() : FORMATS.slice();
}

function nextFormat(current) {
  var ring = FORMATS.concat(VERTICAL_FORMATS);
  var idx = ring.indexOf(String(current || ""));
  if (idx === -1) return ring[0];
  return ring[(idx + 1) % ring.length];
}

function pad2(n) { return (n < 10 ? "0" : "") + n; }

function isoWeek(year, month, day) {
  var d = new Date(Date.UTC(year, month, day));
  var wd = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - wd);
  var ys = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d - ys) / 86400000) + 1) / 7);
}

function substituteIsoWeek(fmt, date) {
  var w = pad2(isoWeek(date.getFullYear(), date.getMonth(), date.getDate()));
  return String(fmt).replace(/ww/g, w);
}

if (typeof module !== "undefined") {
  module.exports = {
    formats: formats,
    nextFormat: nextFormat,
    isoWeek: isoWeek,
    substituteIsoWeek: substituteIsoWeek
  };
}
```

---

## 7. `manifest.json` e `.Agents.md`

### 7.1. `manifest.json`

Confirmar que está exatamente assim (já especificado na Parte 1, seção 7).

### 7.2. `.Agents.md`

Criar com:

- **Fonte oficial:** `/caminho/do/repo/kairos/` (git).
- **Instalado:** `~/.config/omarchy/plugins/io.github.yks777.kairos/`.
- **Invariantes:** Service dono único do estado; wall-clock timers; sanitizeState nunca joga exceção; `saveSoon` vs `saveNow`; `bump()` sozinho não persiste.
- **Ritual de teste** (da Parte 1, seção 9).
- **Regras de segurança do `state.json`** (nunca editar com a shell rodando).

---

## ✅ CHECKPOINT DA PARTE 2

Ao final desta parte, verificar:

- [ ] `Service.qml` existe e carrega `state.json` sem erro.
- [ ] `BarWidget.qml` mostra o relógio corretamente.
- [ ] Ciclo de formato (clique direito) funciona e persiste.
- [ ] Middle click abre `omarchy-menu-timezone`.
- [ ] Left click abre o painel na aba Day (que estará vazia).
- [ ] `Panel.qml` renderiza com header, tabs e placeholders vazios.
- [ ] `omarchy-shell io.github.yks777.kairos ping` retorna `ok`.
- [ ] `omarchy-shell io.github.yks777.kairos status` retorna JSON.
- [ ] `omarchy-shell io.github.yks777.kairos togglePanel` abre/fecha o painel.
- [ ] `omarchy plugin validate` sai com exit 0.
- [ ] `qmllint` sai com exit 0 nos entry points.
- [ ] Sem erros no console após 5 min.
- [ ] Atalhos `Super+H`, `Super+Shift+H`, `Super+Alt+H` registrados.

# PARTE 3 — ABA DAY + OBSIDIAN + KHAL

> **INSTRUÇÕES PARA A IA:** Este é o terceiro de 6 prompts sequenciais. Você já tem a fundação (Parte 1) e a estrutura de barra + painel (Parte 2). Agora implementa a **aba Day completa**, com calendário do mês, eventos do khal, tarefas do Obsidian, e o comportamento crítico de clique no dia. Ao final, a aba Day estará 100% funcional.

---

## 1. Escopo da Parte 3

Ao final desta parte, você deve ter:

1. **`views/DayView.qml`** — a aba completa com calendário + eventos + tarefas.
2. **`components/day/MonthGrid.qml`** — grade de 6 semanas fixas com dots coloridos.
3. **`components/day/DayEvents.qml`** — lista de eventos do dia com expand/collapse.
4. **`components/day/DayTasks.qml`** — lista de tarefas do Obsidian com checkboxes.
5. **`components/day/EventCard.qml`** — card expansível de evento (Join, Directions, descrição, organizer, RSVP).
6. **`logic/CalendarModel.js`** — parse de khal, ICS, meeting links, notificações.
7. **`logic/ObsidianModel.js`** — paths, template, parse de tasks, toggle, add (se ainda não existir completo).
8. **`services/CalendarService.qml`** — fetch do khal, sync, notificações de evento.
9. **`services/ObsidianService.qml`** — ler/escrever/criar notas, watch de mudanças.
10. **Integração no `Service.qml`** — propriedades e métodos agregados que a DayView consome.
11. **Integração no `Panel.qml`** — substituir o placeholder da aba Day pela `DayView` real.

**Não fazer ainda:** abas Focus, Plan, Stats, Markets, Social, Settings.

---

## 2. Layout da aba Day

### 2.1. Vista completa

```
┌───────────────────────────────────────────────────────────────────────┐
│ KAIROS   Stay Hard                                        ⚙    ×      │
├───────────────────────────────────────────────────────────────────────┤
│ [Day] [Focus] [Plan] [Stats] [Markets] [Social]                       │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ‹   October 2026   ›                          [ Today ]  [ W ]       │
│                                                                       │
│   Mo   Tu   We   Th   Fr   Sa   Su                                    │
│             1    2    3    4                                          │
│    5    6    7    8    9   10   11                                    │
│   12   13   14   15   16   17   18                                    │
│   19   20   21   22   23   24   25                                    │
│   26   27   28   29   30   31                                         │
│                                                                       │
│  ─────────────────────────────────────────────────────────────────    │
│                                                                       │
│  Saturday, Oct 11                                                     │
│                                                                       │
│  EVENTS                                                               │
│  ● 09:30–09:45   Standup                              Google Meet     │
│  ● 14:00–15:00   1:1 with Ana                         Zoom            │
│                                                                       │
│  TASKS                                                  [ + Add ]     │
│  ☐  Refactor auth flow                                                │
│  ☑  Fix deploy script                                                 │
│  ☐  Review PR #142                                                    │
│  ☐  Write weekly summary                                              │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

### 2.2. Estrutura vertical

1. **Month grid** — 6 semanas fixas (altura constante).
2. **Day header** — `Saturday, Oct 11`.
3. **EVENTS** — lista de eventos do dia selecionado.
4. **TASKS** — lista de tarefas da nota Obsidian do dia selecionado.

---

## 3. `views/DayView.qml` — a view

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components/day"

Item {
  id: root
  property var service: null

  property var selectedDate: new Date()          // dia selecionado
  property int displayedYear: selectedDate.getFullYear()
  property int displayedMonth: selectedDate.getMonth()
  property int weekStart: 1                      // 0 = Sunday, 1 = Monday

  Layout.fillWidth: true
  Layout.fillHeight: true

  // ---- Dados agregados do Service (bindings reativos) ----
  readonly property var dayEvents: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.eventsForDate(root.selectedDate);
  }
  readonly property var dayTasks: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.tasksForDate(root.selectedDate);
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(10)

    MonthGrid {
      id: monthGrid
      year: root.displayedYear
      month: root.displayedMonth
      weekStart: root.weekStart
      selectedDate: root.selectedDate
      eventsByDay: root.service ? root.service.eventsByDay : ({})
      onDayClicked: function(date) { root.selectDay(date); }
      onPrevMonth: root.shiftMonth(-1)
      onNextMonth: root.shiftMonth(1)
      onPrevYear: root.shiftYear(-1)
      onNextYear: root.shiftYear(1)
      onToday: root.goToToday()
      onToggleWeekStart: root.weekStart = (root.weekStart === 1 ? 0 : 1)
      Layout.fillWidth: true
    }

    Rectangle {
      height: Math.max(1, Style.space(1))
      color: Color.popups.border
      opacity: 0.5
      Layout.fillWidth: true
    }

    // ---- Day header ----
    Text {
      textFormat: Text.PlainText
      text: Qt.formatDateTime(root.selectedDate, "dddd, MMM d")
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      Layout.fillWidth: true
    }

    // ---- EVENTS ----
    Text {
      textFormat: Text.PlainText
      text: "EVENTS"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
      Layout.fillWidth: true
    }

    DayEvents {
      events: root.dayEvents
      service: root.service
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(200, implicitHeight)
    }

    // ---- TASKS ----
    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true

      Text {
        textFormat: Text.PlainText
        text: "TASKS"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
      }

      FlowButton {
        text: "+ Add"
        onClicked: root.promptAddTask()
      }
    }

    DayTasks {
      tasks: root.dayTasks
      service: root.service
      Layout.fillWidth: true
      Layout.fillHeight: true
    }
  }

  // ============================ Ações ============================

  function shiftMonth(delta) {
    var d = new Date(root.displayedYear, root.displayedMonth + delta, 1);
    root.displayedYear = d.getFullYear();
    root.displayedMonth = d.getMonth();
  }

  function shiftYear(delta) {
    root.displayedYear += delta;
  }

  function goToToday() {
    var now = new Date();
    root.displayedYear = now.getFullYear();
    root.displayedMonth = now.getMonth();
    root.selectDay(now);
  }

  // ============================ CLIQUE NO DIA (crítico) ============================
  // Seleciona o dia E abre a nota no Obsidian. Se a nota não existe, cria
  // com o template exato, depois abre. O clique é a única porta para o Obsidian.

  function selectDay(date) {
    root.selectedDate = date;
    root.displayedYear = date.getFullYear();
    root.displayedMonth = date.getMonth();

    if (root.service && root.service.obsidianEnabled) {
      root.service.obsidianOpenOrCreate(date);
    }

    // Feedback visual: o mês/day pisca.
    monthGrid.flashSelected();
  }

  function promptAddTask() {
    if (root.service) root.service.obsidianAddTaskPrompt(root.selectedDate);
  }
}
```

---

## 4. `components/day/MonthGrid.qml` — a grade

### 4.1. Especificação

- **6 semanas fixas.** A altura da grade é constante — navegar entre meses nunca faz o painel pular.
- **Header:** `‹ Month YYYY ›` à esquerda, `[ Today ]` e `[ W ]` à direita.
- **Dias da semana:** `Mo Tu We Th Fr Sa Su` (ou começando no domingo se `weekStart === 0`).
- **Célula do dia:**
  - Número centralizado.
  - `today` em `Color.accent`.
  - Dia selecionado: borda accent + tinta accent a 20%.
  - Fora do mês: `Color.muted` com opacidade 0.4.
  - Até 3 dots coloridos abaixo do número (uma por calendário com eventos naquele dia).
- **Teclas:** `[` `]` mês, `{` `}` ano, `t` hoje, `w` alterna week start.

### 4.2. Implementação

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/ClockModel.js" as ClockModel

ColumnLayout {
  id: root

  property int year: new Date().getFullYear()
  property int month: new Date().getMonth()
  property int weekStart: 1
  property var selectedDate: new Date()
  property var eventsByDay: ({})   // { "YYYY-MM-DD": [color1, color2, ...] }

  signal dayClicked(var date)
  signal prevMonth()
  signal nextMonth()
  signal prevYear()
  signal nextYear()
  signal today()
  signal toggleWeekStart()

  spacing: Style.space(6)
  Layout.fillWidth: true

  readonly property var weeks: ClockModel.monthGrid(root.year, root.month, root.weekStart)

  function flashSelected() { /* animação de flash */ }

  // ---- Header ----
  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    FlowIconButton {
      glyph: "\uf0141"        // nf-md-chevron-left
      onClicked: root.prevMonth()
    }

    Text {
      textFormat: Text.PlainText
      text: Qt.formatDateTime(new Date(root.year, root.month, 1), "MMMM yyyy")
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      Layout.fillWidth: true
    }

    FlowIconButton {
      glyph: "\uf0142"        // nf-md-chevron-right
      onClicked: root.nextMonth()
    }

    FlowButton {
      text: "Today"
      onClicked: root.today()
    }

    FlowButton {
      text: "W"
      onClicked: root.toggleWeekStart()
    }
  }

  // ---- Weekday header ----
  RowLayout {
    spacing: 0
    Layout.fillWidth: true

    Repeater {
      model: ClockModel.weekdayLabels(root.weekStart)
      delegate: Text {
        required property string modelData
        text: modelData
        textFormat: Text.PlainText
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }
    }
  }

  // ---- Grid (6 weeks) ----
  ColumnLayout {
    spacing: Style.space(2)
    Layout.fillWidth: true

    Repeater {
      model: root.weeks
      delegate: RowLayout {
        required property var modelData
        spacing: 0
        Layout.fillWidth: true

        Repeater {
          model: modelData.days
          delegate: Item {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Style.space(40)

            Rectangle {
              anchors.fill: parent
              anchors.margins: Style.space(1)
              radius: Style.cornerRadius
              color: Color.accent
              opacity: {
                var sel = root.selectedDate
                if (!sel) return 0;
                return (sel.getFullYear() === modelData.year
                     && sel.getMonth() === modelData.month
                     && sel.getDate() === modelData.day) ? 0.20 : 0.0;
              }
              border.color: Color.accent
              border.width: Math.max(1, Style.space(1))
              visible: opacity > 0
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(4)
              textFormat: Text.PlainText
              text: String(modelData.day)
              color: modelData.today ? Color.accent
                   : (modelData.inMonth ? Color.popups.text : Qt.rgba(0,0,0,0))
              opacity: modelData.inMonth ? 1.0 : 0.4
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(3)
              spacing: Style.space(2)

              Repeater {
                model: {
                  var key = modelData.year + "-"
                          + String(modelData.month + 1).padStart(2, "0") + "-"
                          + String(modelData.day).padStart(2, "0");
                  return root.eventsByDay[key] || [];
                }
                delegate: Rectangle {
                  required property string modelData
                  width: Style.space(4)
                  height: width
                  radius: width / 2
                  color: modelData || Color.muted
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var d = new Date(modelData.year, modelData.month, modelData.day);
                root.dayClicked(d);
              }
            }
          }
        }
      }
    }
  }
}
```

**Nota:** `ClockModel.monthGrid(year, month, weekStart)` precisa retornar `[{ days: [{year, month, day, today, inMonth, weekday}, ...] }, ...]` — 6 semanas × 7 dias.

---

## 5. `components/day/DayEvents.qml` — a lista de eventos

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "EventCard.qml"

ColumnLayout {
  id: root
  property var events: []
  property var service: null

  spacing: Style.space(4)
  Layout.fillWidth: true

  Repeater {
    model: root.events
    delegate: EventCard {
      required property var modelData
      event: modelData
      service: root.service
      Layout.fillWidth: true
    }
  }

  Text {
    visible: root.events.length === 0
    textFormat: Text.PlainText
    text: "Nothing scheduled."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.italic: true
    Layout.fillWidth: true
  }
}
```

---

## 6. `components/day/EventCard.qml` — o card expansível

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root
  property var event: null
  property var service: null
  property bool expanded: false

  implicitHeight: content.implicitHeight + Style.space(10)
  radius: Style.cornerRadius
  color: "transparent"
  border.color: hover.containsMouse ? Color.popups.border : "transparent"
  border.width: Math.max(1, Style.space(1))

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: Style.space(6)
    spacing: Style.space(4)

    RowLayout {
      spacing: Style.space(6)
      Layout.fillWidth: true

      // Dot na cor do calendário
      Rectangle {
        width: Style.space(8)
        height: width
        radius: width / 2
        color: root.event && root.event.color ? root.event.color : Color.muted
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        textFormat: Text.PlainText
        text: root.event ? root.event.timeRange : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Layout.preferredWidth: Style.space(90)
      }

      Text {
        textFormat: Text.PlainText
        text: root.event ? root.event.title : ""
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        visible: root.event && root.event.serviceName !== ""
        textFormat: Text.PlainText
        text: root.event ? root.event.serviceName : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    // Detalhes expandidos
    ColumnLayout {
      visible: root.expanded
      spacing: Style.space(6)
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(14)

      FlowButton {
        visible: root.event && root.event.meetingUrl !== ""
        text: "Join"
        primary: true
        onClicked: if (root.service) root.service.openUrl(root.event.meetingUrl)
      }

      Text {
        visible: root.event && root.event.location !== ""
        textFormat: Text.PlainText
        text: root.event ? ("Location: " + root.event.location) : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }

      Text {
        visible: root.event && root.event.description !== ""
        textFormat: Text.PlainText
        text: root.event ? root.event.description : ""
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.expanded = !root.expanded
  }
}
```

---

## 7. `components/day/DayTasks.qml` — as tarefas do Obsidian

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var tasks: []
  property var service: null

  spacing: Style.space(4)
  Layout.fillWidth: true

  Repeater {
    model: root.tasks
    delegate: RowLayout {
      required property var modelData
      spacing: Style.space(6)
      Layout.fillWidth: true

      // Checkbox Nerd Font
      Text {
        text: modelData.checked ? "\uf04b7" : "\uf04b6"    // nf-md-checkbox-marked-outline / blank-outline
        color: modelData.checked ? Color.muted : Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.service) root.service.obsidianToggleTask(modelData.lineIndex);
        }
      }

      Text {
        textFormat: Text.PlainText
        text: modelData.text
        color: modelData.checked ? Color.muted : Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
  }

  Text {
    visible: root.tasks.length === 0
    textFormat: Text.PlainText
    text: root.service && root.service.obsidianEnabled
      ? "No tasks in today's note."
      : "Obsidian is disabled."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.italic: true
    Layout.fillWidth: true
  }
}
```

---

## 8. `logic/CalendarModel.js` — parse de khal

### 8.1. Funções necessárias

```js
.pragma library

// ---- Parse de khal printformats ----
// Retorna { date: {regex, fields}, time: {regex, fields}, longdate, use24h, error }

function parseFormats(text) { /* ... */ }

// ---- Parse de khal list --json ----
// Cada linha é um array JSON de eventos de um dia.
// Retorna lista normalizada, deduplicada por UID + start, ordenada.

function parseEvents(text, formats) { /* ... */ }

// ---- Parse de um .ics por UID ----
// Retorna { conference, url, description, organizer, attendees } ou null.

function parseIcsDetails(text, uid) { /* ... */ }

// ---- Detecção de serviço de reunião ----
// Retorna "Google Meet" | "Zoom" | "Microsoft Teams" | "Jitsi" | "Webex"
// | "Whereby" | "Signal" | "Discord" | ""

function meetingService(url) { /* ... */ }

// ---- Notificações devidas ----
// Retorna lista de eventos que devem notificar agora (não all-day,
// não cancelados, dentro da janela de leadMinutes, não já notificados).

function dueNotifications(events, now, leadMinutes, notified) { /* ... */ }

// ---- Prune de notificados (mais de 24h) ----
function pruneNotified(notified, now) { /* ... */ }

// ---- Agenda rows (eventos agrupados por dia, dia já acabado é omitido) ----
function agendaRows(events, now) { /* ... */ }

// ---- ICS lookup script ----
// Script bash que encontra o .ics pelo UID e imprime o conteúdo.

var ICS_LOOKUP_SCRIPT = "...";

if (typeof module !== "undefined") {
  module.exports = {
    parseFormats: parseFormats,
    parseEvents: parseEvents,
    parseIcsDetails: parseIcsDetails,
    meetingService: meetingService,
    dueNotifications: dueNotifications,
    pruneNotified: pruneNotified,
    agendaRows: agendaRows,
    ICS_LOOKUP_SCRIPT: ICS_LOOKUP_SCRIPT
  };
}
```

### 8.2. `parseFormats(text)`

Lê a saída de `khal printformats` e constrói dois parsers regex: um para datas (formatos como `2013-12-21`, `21.12.2013`, `12/21/2013`, `Saturday, December 21, 2013`) e um para horas (`21:45`, `9:45 PM`, `21:45:00`).

Cada parser tem:
- `regex`: padrão que casa uma data/hora renderizada no formato do usuário.
- `fields`: array de campos na ordem em que aparecem (`Y`, `y`, `m`, `B`, `d` para datas; `H`, `I`, `M`, `S`, `p` para horas).

**Regra crítica:** o parser deve conseguir ler a **amostra que o próprio khal imprimiu** (que representa Saturday 2013-12-21 21:45) e retornar exatamente `{year: 2013, month: 12, day: 21}` e `{hour: 21, minute: 45}`. Se não conseguir, define `error` com uma mensagem orientando o usuário a configurar `longdateformat = %Y-%m-%d` e `timeformat = %H:%M` no `[locale]`.

Referência: `derekross.calendar/logic/Model.js` — `parseFormats`, `compileSample`, `SAMPLE_DATE_TOKENS`, `SAMPLE_TIME_TOKENS`.

### 8.3. `parseEvents(text, formats)`

Cada linha de `khal list --json` é um array JSON de eventos de um dia. Eventos multi-dia aparecem repetidos em cada dia que tocam — deduplica por `uid + start`.

Retorna uma lista normalizada:

```js
{
  key: "calendar|uid|start",
  uid: "abc@google.com",
  title: "Standup",
  calendar: "work",
  color: "#039be5",
  location: "",
  description: "",
  url: "",
  organizer: { name: "", email: "" },
  status: "",
  allDay: false,
  start: 1760000000000,
  end: 1760000900000,
  timeRange: "09:30–09:45",
  serviceName: "Google Meet",
  meetingUrl: "https://meet.google.com/..."
}
```

---

## 9. `logic/ObsidianModel.js` — paths, template, tasks

### 9.1. Funções necessárias

```js
.pragma library

// ---- Resolução de path ----
// Dado diaryPath (caminho absoluto da pasta de diarios) e uma data, retorna o path absoluto
// <diaryPath>/<YYYY>/<MM>/<YYYY-MM-DD>.md

function resolveDailyNotePath(diaryPath, date) { /* ... */ }

// ---- Template ----
// Retorna o conteúdo exato da nota a ser criada, com data/hora preenchida.

function renderTemplate(dateTimeString) {
  return "---\n"
       + "data e hora: " + dateTimeString + "\n"
       + "tags:\n"
       + "  - Diario\n"
       + "---\n"
       + "-\n";
}

// ---- Parse de tasks ----
// Regex: ^(\s*)- \[([ xX])\] (.+)$
// Ignora blocos de código (``` ... ```).
// Retorna [{ lineIndex, indent, checked, text }, ...]

function parseTasks(text) { /* ... */ }

// ---- Toggle de uma task pelo lineIndex ----
// Retorna o novo texto do arquivo.

function toggleTask(text, lineIndex) { /* ... */ }

// ---- Adicionar uma task ----
// Adiciona "- [ ] New task" após a última task da primeira seção com tasks.
// Se não houver nenhuma, adiciona ao final.

function addTask(text, taskText) { /* ... */ }

// ---- Data/hora local formatada ----
function formatDateTime(date) {
  var d = date || new Date();
  function p(n) { return (n < 10 ? "0" : "") + n; }
  return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate())
       + " " + p(d.getHours()) + ":" + p(d.getMinutes());
}

// ---- Obsidian URI ----
function obsidianUri(vaultName, relativePath) {
  return "obsidian://open?vault=" + encodeURIComponent(vaultName)
       + "&file=" + encodeURIComponent(relativePath);
}

if (typeof module !== "undefined") {
  module.exports = {
    resolveDailyNotePath: resolveDailyNotePath,
    renderTemplate: renderTemplate,
    parseTasks: parseTasks,
    toggleTask: toggleTask,
    addTask: addTask,
    formatDateTime: formatDateTime,
    obsidianUri: obsidianUri
  };
}
```

### 9.2. Template exato

```markdown
---
data e hora: 2026-10-11 15:42
tags:
  - Diario
---
-
```

**Regras:**
- `data e hora:` é **sempre** substituído por `YYYY-MM-DD HH:mm` no momento da criação.
- `tags:` com `- Diario` vem do template, não é injetado.
- O `-` no fim é o marcador inicial.
- Se `templatePath` estiver configurado e for um arquivo estático (sem sintaxe `<% %>` do Templater), lê-lo e substituir `data e hora:`.
- Se vazio, usa o bloco acima.
- **Nunca** invoca o Templater.

---

## 10. `services/CalendarService.qml` — khal

### 10.1. Responsabilidade

- No startup: `khal printformats` → parse → guarda `formats`.
- A cada minuto alinhado: `khal list --json <fields> --day-format "" today <N>d` (N = `agendaDays`).
- Ao navegar meses: `khal list <start> 48d` (cacheado por `YYYY-MM`).
- Sync: a cada `syncIntervalMinutes` (padrão 15), comando `syncCommand` (padrão `vdirsyncer sync`). Watchdog de 5 min.
- Notificações: a cada minuto, `dueNotifications(events, now, leadMinutes, notified)`. Só não all-day, sem repetir. `notified.json` persiste.
- ICS lookup: ao expandir um evento, busca o `.ics` pelo UID.

### 10.2. Processos

```qml
Item {
  id: root
  property var service: null    // referência ao Service principal
  property var formats: null
  property var events: []
  property bool khalAvailable: true
  property string lastError: ""
  property double lastRefresh: 0
  property double lastSync: 0
  property var notified: ({})
  property var monthEvents: ({})

  // ---- Startup ----
  Process {
    id: formatsProc
    command: ["sh", "-c", "command -v khal >/dev/null 2>&1 || exit 127; exec khal printformats"]
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: formatsProc.output = text
    }
    onExited: function(code) {
      if (code === 127) { root.khalAvailable = false; return; }
      if (code !== 0) { root.lastError = "khal printformats failed"; return; }
      var parsed = CalendarModel.parseFormats(formatsProc.output);
      if (parsed.error) { root.lastError = parsed.error; return; }
      root.formats = parsed;
      root.refresh();
    }
  }

  // ---- Periodic fetch ----
  Process {
    id: listProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: listProc.output = text
    }
    onExited: function(code) {
      if (code !== 0) return;
      root.events = CalendarModel.parseEvents(listProc.output, root.formats);
      root.lastRefresh = Date.now();
      root.checkNotifications();
    }
  }

  function refresh() {
    if (!root.formats) { formatsProc.running = true; return; }
    if (listProc.running) return;
    listProc.command = CalendarModel.khalListArgs(30);
    listProc.running = true;
  }

  // ---- Sync ----
  Process {
    id: syncProc
    onExited: function(code) {
      if (code === 0) {
        root.lastSync = Date.now();
        root.formats = null;
        formatsProc.running = true;
      }
    }
  }

  function sync() {
    if (syncProc.running) return;
    syncProc.command = ["sh", "-c", String(root.service.settings.calendar.syncCommand || "vdirsyncer sync")];
    syncProc.running = true;
  }

  Timer {
    id: minuteTimer
    interval: 60000 - (Date.now() % 60000) + 1000
    running: true
    repeat: true
    onTriggered: {
      interval = 60000 - (Date.now() % 60000) + 1000;
      root.refresh();
    }
  }

  // ---- Notificações ----
  function checkNotifications() {
    var due = CalendarModel.dueNotifications(root.events, Date.now(),
      root.service.settings.calendar.leadMinutes, root.notified);
    if (due.length === 0) return;
    for (var i = 0; i < due.length; i++) {
      root.service.notify("calendar", due[i].title,
        "Starts at " + due[i].timeRange);
      root.notified[due[i].key] = due[i].start;
    }
    // Persistir notified.json (implementação de FileView)
  }

  Component.onCompleted: formatsProc.running = true
}
```

---

## 11. `services/ObsidianService.qml` — leitura/escrita do vault

### 11.1. Responsabilidade

- Resolver paths de notas diárias.
- Ler o conteúdo de uma nota.
- Criar uma nota com o template exato (se não existir).
- Escrever de volta após toggle/add (atomicamente).
- Abrir no Obsidian via URI.
- Watch de mudanças no arquivo do dia.

### 11.2. Implementação

```qml
Item {
  id: root
  property var service: null
  property string currentPath: ""
  property string currentContent: ""
  property var currentTasks: []
  property string lastError: ""

  // ---- FileView do dia atual ----
  FileView {
    id: noteFile
    watchChanges: true
    atomicWrites: true
    onLoaded: root.applyContent(text())
    onLoadFailed: function(error) {
      // Arquivo não existe: currentContent vazio, currentTasks vazios.
      root.currentContent = "";
      root.currentTasks = [];
    }
    onTextChanged: root.applyContent(text())
  }

  // ---- FileView para escrever ----
  FileView {
    id: writeFile
    atomicWrites: true
  }

  function applyContent(text) {
    root.currentContent = String(text || "");
    root.currentTasks = ObsidianModel.parseTasks(root.currentContent);
    if (root.service) root.service.bump();
  }

  // ============================ Ler a nota do dia ============================

  function loadNote(date) {
    var s = root.service.settings.obsidian;
    if (!s.enabled) return;
    var path = ObsidianModel.resolveDailyNotePath(s.diaryPath, date);
    root.currentPath = path;
    noteFile.path = path;
  }

  // ============================ Criar nota com template exato ============================

  function createNote(date, callback) {
    var s = root.service.settings.obsidian;
    var path = ObsidianModel.resolveDailyNotePath(s.diaryPath, date);
    var mkdirCmd = "mkdir -p \"$(dirname \"" + path + "\")\"";
    var content = ObsidianModel.renderTemplate(ObsidianModel.formatDateTime(date));

    // 1. Cria as pastas.
    // 2. Escreve o arquivo atomicamente (.tmp + mv).
    mkdirProc.command = ["bash", "-c", mkdirCmd];
    mkdirProc.running = true;
    writeProc.path = path;
    writeProc.content = content;
    writeProc.date = date;
    writeProc.callback = callback;
  }

  Process {
    id: mkdirProc
    onExited: function(code) {
      if (code !== 0) {
        root.lastError = "mkdir failed";
        return;
      }
      writeFile.setText(writeProc.content);
      root.currentPath = writeProc.path;
      root.service.notify("obsidian", "Note created",
        Qt.formatDateTime(writeProc.date, "yyyy-MM-dd"));
      if (writeProc.callback) writeProc.callback();
    }
  }

  // ============================ Abrir/criar e abrir ============================

  function openOrCreate(date) {
    var s = root.service.settings.obsidian;
    if (!s.enabled) return;
    var path = ObsidianModel.resolveDailyNotePath(s.diaryPath, date);

    // Verifica existência; se existir, abre. Se não, cria e abre.
    checkProc.path = path;
    checkProc.date = date;
    checkProc.running = true;
  }

  Process {
    id: checkProc
    property string path: ""
    property var date: null
    command: ["test", "-f", path]
    onExited: function(code) {
      if (code === 0) {
        root.openInObsidian(checkProc.date);
      } else {
        root.createNote(checkProc.date, function() {
          root.openInObsidian(checkProc.date);
        });
      }
    }
  }

  function openInObsidian(date) {
    var s = root.service.settings.obsidian;
    var diaryPath = s.diaryPath;
    var vaultRoot = root.vaultRoot;
    var d = date || new Date();
    function p(n) { return (n < 10 ? "0" : "") + n; }
    var y = d.getFullYear();
    var m = p(d.getMonth() + 1);
    var rel = diaryPath.slice(vaultRoot.length + 1) + "/" + y + "/" + m + "/" + y + "-" + m + "-" + p(d.getDate()) + ".md";
    var vault = s.vaultName || vaultRoot.slice(vaultRoot.lastIndexOf("/") + 1);
    var uri = ObsidianModel.obsidianUri(vault, rel);
    Quickshell.execDetached(["xdg-open", uri]);
  }

  // ============================ Toggle de task ============================

  function toggleTask(lineIndex) {
    if (root.currentContent === "") return;
    var updated = ObsidianModel.toggleTask(root.currentContent, lineIndex);
    writeFile.path = root.currentPath;
    writeFile.setText(updated);
    root.currentContent = updated;
    root.currentTasks = ObsidianModel.parseTasks(updated);
    root.service.bump();
  }

  // ============================ Add task ============================

  function addTask(text) {
    if (root.currentContent === "") return;
    var updated = ObsidianModel.addTask(root.currentContent, String(text).trim());
    writeFile.path = root.currentPath;
    writeFile.setText(updated);
    root.currentContent = updated;
    root.currentTasks = ObsidianModel.parseTasks(updated);
    root.service.bump();
  }
}
```

---

## 12. Integração no `Service.qml`

Adicionar ao `Service.qml`:

```qml
  // ---- Referências aos serviços ----
  CalendarService {
    id: calendarService
    service: root
  }

  ObsidianService {
    id: obsidianService
    service: root
  }

  // ---- Propriedades agregadas que a DayView consome ----
  readonly property bool obsidianEnabled: root.settings.obsidian.enabled
  readonly property var eventsByDay: {
    void root.revision;
    // Agrupa calendarService.events por dia, retornando cores por dia.
    return CalendarModel.eventsByDay(calendarService.events);
  }

  function eventsForDate(date) {
    var dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
    var dayEnd = dayStart + 86400000;
    var out = [];
    for (var i = 0; i < calendarService.events.length; i++) {
      var ev = calendarService.events[i];
      if (ev.start < dayEnd && ev.end > dayStart) {
        out.push(CalendarModel.enrichEvent(ev));
      }
    }
    return out;
  }

  function tasksForDate(date) {
    // Se a data é hoje, retorna as tasks do obsidianService.
    // Senão, carrega a nota daquele dia (leitura one-shot).
    var today = new Date();
    var isToday = date.getFullYear() === today.getFullYear()
               && date.getMonth() === today.getMonth()
               && date.getDate() === today.getDate();
    if (isToday) return obsidianService.currentTasks;
    return []; // Implementação futura: leitura on-demand de notas passadas.
  }

  function obsidianOpenOrCreate(date) {
    obsidianService.openOrCreate(date);
  }

  function obsidianToggleTask(lineIndex) {
    obsidianService.toggleTask(lineIndex);
  }

  function obsidianAddTaskPrompt(date) {
    // Abre um diálogo simples (FlowInput) ou adiciona direto "New task".
    obsidianService.addTask("New task");
  }

  function openUrl(url) {
    if (/^https?:\/\//.test(url) || /^obsidian:\/\//.test(url)) {
      Quickshell.execDetached(["xdg-open", url]);
    }
  }

  // ---- notificações ----
  function notify(category, title, body) {
    if (!root.settings.notifications.enabled) return;
    notifyProc.title = String(title);
    notifyProc.body = String(body);
    notifyProc.running = true;
  }

  Process {
    id: notifyProc
    property string title: ""
    property string body: ""
    command: ["omarchy-notification-send", "-g", "\uf017", title, body, "-t", "8000"]
  }
```

---

## 13. Integração no `Panel.qml`

Substituir o placeholder da aba Day:

```qml
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "day"

          DayView {
            anchors.fill: parent
            service: root.service
          }
        }
```

Adicionar `import "views"` no topo do `Panel.qml` se ainda não existir.

---

## 14. Estados vazios e erros

| Situação | Como aparece |
|---|---|
| khal não instalado | `EVENTS` mostra "khal is not installed." em muted itálico |
| khal com formato incompatível | `EVENTS` mostra o erro exato e orienta `longdateformat = %Y-%m-%d` |
| Sem eventos no dia | "Nothing scheduled." em muted itálico |
| Obsidian desabilitado | `TASKS` mostra "Obsidian is disabled." |
| Nota não existe | Ao clicar no dia, cria e abre |
| Nota existe | Ao clicar no dia, abre direto |
| Falha ao criar | Toast em `Color.urgent` com motivo |
| Sem tasks na nota | "No tasks in today's note." |

---

## 15. Testes automatizados

Criar `tests/calendar-model.test.js`:

- `parseFormats` lê amostras ISO, europeias, US e long-name.
- `parseFormats` rejeita formatos que não consegue ler (retorna `error`).
- `parseEvents` deduplica multi-day e ordena all-day primeiro.
- `parseIcsDetails` extrai conference, organizer, attendees.
- `meetingService` reconhece Google Meet, Zoom, Teams, Jitsi, Webex.
- `dueNotifications` notifica dentro da janela, nunca duas vezes, nunca all-day.

Criar `tests/obsidian-model.test.js`:

- `resolveDailyNotePath` monta `<vault>/<folder>/<YYYY>/<MM>/<YYYY-MM-DD>.md`.
- `renderTemplate` produz o template exato com data/hora correta.
- `parseTasks` extrai checkboxes, ignora code blocks.
- `toggleTask` faz flip `[ ]` ↔ `[x]` preservando o resto.
- `addTask` insere `- [ ] New task` após a última task da primeira seção.
- `obsidianUri` monta o URI correto com URL encoding.

---

## ✅ CHECKPOINT DA PARTE 3

Ao final desta parte, verificar:

- [ ] `DayView` renderiza o mês atual com 6 semanas.
- [ ] Dots coloridos aparecem nos dias com eventos.
- [ ] Hoje está destacado em accent.
- [ ] Clicar num dia seleciona e abre a nota no Obsidian.
- [ ] Se a nota não existe, é criada com o template exato.
- [ ] O template criado tem `data e hora:` preenchido e a tag `- Diario`.
- [ ] Tasks da nota aparecem com checkbox Nerd Font.
- [ ] Clicar no checkbox faz flip no `.md`.
- [ ] `+ Add` insere `- [ ] New task` na nota.
- [ ] Eventos do khal aparecem com horário, título e serviço de reunião.
- [ ] Clicar num evento expande detalhes (Join, location, description).
- [ ] Navegação de mês (`‹` `›`) funciona.
- [ ] `[ Today ]` volta para hoje.
- [ ] `[ W ]` alterna week start.
- [ ] `node --test tests/` passa para `calendar-model` e `obsidian-model`.
- [ ] `omarchy plugin validate` sai com exit 0.
- [ ] `qmllint` sai com exit 0 em `DayView.qml` e componentes novos.
- [ ] Sem erros no console após 5 min.

# PARTE 4 — ABAS FOCUS E PLAN

> **INSTRUÇÕES PARA A IA:** Este é o quarto de 6 prompts sequenciais. Você já tem fundação (Parte 1), barra + painel (Parte 2) e aba Day + Obsidian + khal (Parte 3). Agora implementa a **aba Focus** (timer Pomodoro/Flowtime) e a **aba Plan** (matriz de Eisenhower). Ao final, ambas estarão 100% funcionais.

---

## 1. Escopo da Parte 4

Ao final desta parte, você deve ter:

1. **`views/FocusView.qml`** — a aba Focus completa (técnica, contador, estado, task ativa, botões, sessões do dia).
2. **`views/PomodoroView.qml`** — variante Pomodoro do timer.
3. **`views/FlowtimeView.qml`** — variante Flowtime (count-up, interrupções, break sugerido).
4. **`views/PlanView.qml`** — a aba Plan com matriz de Eisenhower.
5. **`components/plan/MatrixToolbar.qml`** — header da matriz.
6. **`components/plan/MatrixColumn.qml`** — um quadrante.
7. **`components/plan/TaskCard.qml`** — card com hover menu e drag.
8. **`components/plan/TaskEditor.qml`** — composer inline.
9. **`components/plan/CompletedPopup.qml`** — popup com busca.
10. **Métodos de timer no `Service.qml`** — `startPomodoro`, `startFlowtime`, `pauseTimer`, `resumeTimer`, `stopTimer`, `skipBreak`, `addInterruption`, `finishFlowtime`, `completePomodoro`, `completeBreak`.
11. **Métodos de tasks no `Service.qml`** — `createTask`, `updateTask`, `moveTask`, `completeTask`, `reopenTask`, `deleteTask`, `setActiveTask`.
12. **Integração no `Panel.qml`** — substituir os placeholders de Focus e Plan.
13. **Notificações de timer** — fim de fase, fim de break.
14. **IPC do timer** — `start`, `pause`, `stop`, `resume`, `finish`, `interrupt`, `status`.

**Não fazer ainda:** abas Stats, Markets, Social, Settings.

---

# PARTE A — ABA FOCUS

## 2. Layout da aba Focus

### 2.1. Vista completa

```
┌─────────────────────────────────────────────────────────┐
│ KAIROS   Stay Hard                          ⚙    ×      │
├─────────────────────────────────────────────────────────┤
│ [Day] [Focus] [Plan] [Stats] [Markets] [Social]         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  TECHNIQUE                                              │
│  [ Pomodoro ]  [ Flowtime ]                             │
│                                                         │
│                                                         │
│                      18:24                              │
│                                                         │
│              FOCUS · Session 2 of 4                     │
│                                                         │
│  Working on: Refactor auth flow          [ Change ]     │
│                                                         │
│       [ Pause ]   [ Stop ]                              │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  TODAY'S SESSIONS                                       │
│  ● Pomodoro · 25m                            14:20      │
│  ● Flowtime · 42m                            13:10      │
│  ● Pomodoro · 25m                            11:00      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.2. Estrutura vertical

1. **TECHNIQUE** — heading `TECHNIQUE` em caption muted + dois chips `Pomodoro` / `Flowtime`.
2. **Contador** — displayLarge, centralizado. Cor varia por estado.
3. **Estado** — `FOCUS · Session 2 of 4` (Pomodoro) ou `FLOWTIME · 2 interruptions · Suggested break: 8m` (Flowtime). Caption muted.
4. **Working on** — `<task title>` + `[ Change ]`. Picker com duas seções.
5. **Botões** — variam por estado do timer.
6. **TODAY'S SESSIONS** — últimas 30 sessões do dia.

---

## 3. `views/FocusView.qml` — a view principal

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../logic/Model.js" as Model

ColumnLayout {
  id: root
  property var service: null

  spacing: Style.space(10)
  Layout.fillWidth: true

  // ---- Técnica: sempre vem de settings.focus.focusAction ----
  readonly property string technique: {
    if (!root.service) return "pomodoro";
    void root.service.revision;
    var t = root.service.timer;
    if (t && (t.phase === "running" || t.phase === "paused" || t.phase === "break")
        && (t.mode === "pomodoro" || t.mode === "flowtime")) return t.mode;
    return root.service.settings.focus.focusAction || "pomodoro";
  }

  // ============================ TECHNIQUE ============================
  Text {
    textFormat: Text.PlainText
    text: "TECHNIQUE"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(6)
    Layout.alignment: Qt.AlignHCenter

    Chip {
      label: "Pomodoro"
      active: root.technique === "pomodoro"
      onClicked: if (root.service) root.service.updateFocusAction("pomodoro")
    }
    Chip {
      label: "Flowtime"
      active: root.technique === "flowtime"
      onClicked: if (root.service) root.service.updateFocusAction("flowtime")
    }
  }

  // ============================ TIMER (varia por técnica) ============================
  PomodoroView {
    service: root.service
    visible: root.technique === "pomodoro"
    Layout.fillWidth: true
  }

  FlowtimeView {
    service: root.service
    visible: root.technique === "flowtime"
    Layout.fillWidth: true
  }

  // ============================ WORKING ON ============================
  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true
    Layout.topMargin: Style.space(4)

    Text {
      textFormat: Text.PlainText
      text: "Working on: " + root.activeTaskTitle()
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    FlowButton {
      text: "Change"
      onClicked: root.pickerOpen = true
    }
  }

  // ============================ ACTION BUTTONS (por estado) ============================
  // Os botões concretos vivem dentro de PomodoroView / FlowtimeView.
  // Esta view é apenas o container.

  // ============================ TODAY'S SESSIONS ============================
  Rectangle {
    height: Math.max(1, Style.space(1))
    color: Color.popups.border
    opacity: 0.5
    Layout.fillWidth: true
    Layout.topMargin: Style.space(6)
  }

  Text {
    textFormat: Text.PlainText
    text: "TODAY'S SESSIONS"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
  }

  ColumnLayout {
    spacing: Style.space(3)
    Layout.fillWidth: true
    Layout.fillHeight: true

    Repeater {
      model: root.todaySessions()
      delegate: RowLayout {
        required property var modelData
        spacing: Style.space(8)
        Layout.fillWidth: true

        Rectangle {
          width: Style.space(8)
          height: width
          radius: width / 2
          color: modelData.kind === "pomo" ? Color.accent : Color.muted
          Layout.alignment: Qt.AlignVCenter
        }
        Text {
          textFormat: Text.PlainText
          text: (modelData.kind === "pomo" ? "Pomodoro" : "Flowtime")
              + " · " + Model.formatDur(modelData.durationSec)
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
        Text {
          textFormat: Text.PlainText
          text: Qt.formatDateTime(new Date(modelData.startedAt), "HH:mm")
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    Text {
      visible: root.todaySessions().length === 0
      textFormat: Text.PlainText
      text: "No sessions yet today."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.italic: true
      Layout.fillWidth: true
    }
  }

  // ============================ Helpers ============================
  property bool pickerOpen: false

  function activeTaskTitle() {
    if (!root.service) return "No active task";
    void root.service.revision;
    var t = root.service.activeTask();
    return t ? t.title : "No active task";
  }

  function todaySessions() {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.history("today", "both").slice(0, 30);
  }

  // Task picker (duas seções: Obsidian + Matrix)
  // Implementação: um overlay simples com listas filtradas.
  Loader {
    active: root.pickerOpen
    sourceComponent: Component {
      Item {
        anchors.fill: parent
        // ... overlay com duas seções: "From today's note" e "From matrix"
        // ... cada item chama service.setActiveTask(id) ou service.setActiveTaskFromObsidian(text)
      }
    }
  }
}
```

---

## 4. `views/PomodoroView.qml` — variante Pomodoro

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../logic/Model.js" as Model

ColumnLayout {
  id: root
  property var service: null

  spacing: Style.space(10)
  Layout.fillWidth: true

  readonly property string phase: service ? String(service.timer.phase) : "stopped"
  readonly property bool isBreak: root.phase === "break"

  function timeText() {
    if (!root.service) return Model.formatClock(25 * 60);
    void root.service.tickVersion;
    if (root.phase === "running" || root.phase === "paused" || root.phase === "break") {
      var rem = Math.floor(root.service.timerRemainingMs() / 1000);
      return Model.formatClock(rem);
    }
    return Model.formatClock(root.service.settings.focus.focusSec);
  }

  function stateLabel() {
    if (!root.service) return "IDLE";
    if (root.phase === "break") {
      return root.service.timer.breakKind === "long" ? "LONG BREAK" : "SHORT BREAK";
    }
    if (root.phase === "running") return "FOCUS";
    if (root.phase === "paused") return "PAUSED";
    return "READY";
  }

  function cycleLabel() {
    if (!root.service) return "";
    var every = Math.max(1, root.service.settings.focus.longBreakInterval);
    var done = root.service.timer.pomodorosDone % every;
    return "Session " + (done + 1) + " of " + every;
  }

  // ---- Contador ----
  Text {
    textFormat: Text.PlainText
    text: root.timeText()
    color: root.isBreak ? Color.accent
         : (root.phase === "paused" ? Color.muted : Color.popups.text)
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    Layout.topMargin: Style.space(6)
  }

  // ---- Estado ----
  Text {
    textFormat: Text.PlainText
    text: root.stateLabel() + " · " + root.cycleLabel()
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
  }

  // ---- Botões: stopped ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "stopped"

    FlowButton {
      text: "Start"
      primary: true
      onClicked: if (root.service) root.service.startPomodoro()
    }
  }

  // ---- Botões: running ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "running" && !root.isBreak

    FlowButton {
      text: "Pause"
      onClicked: if (root.service) root.service.pauseTimer()
    }
    FlowButton {
      text: "Stop"
      onClicked: if (root.service) root.service.stopTimer()
    }
  }

  // ---- Botões: paused ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "paused"

    FlowButton {
      text: "Resume"
      primary: true
      onClicked: if (root.service) root.service.resumeTimer()
    }
    FlowButton {
      text: "Stop"
      onClicked: if (root.service) root.service.stopTimer()
    }
  }

  // ---- Botões: break ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.isBreak

    FlowButton {
      text: "Skip break"
      primary: true
      onClicked: if (root.service) root.service.skipBreak()
    }
  }
}
```

---

## 5. `views/FlowtimeView.qml` — variante Flowtime

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../logic/Model.js" as Model
import "../logic/TimerEngine.js" as TimerEngine

ColumnLayout {
  id: root
  property var service: null

  spacing: Style.space(10)
  Layout.fillWidth: true

  readonly property string phase: service ? String(service.timer.phase) : "stopped"
  readonly property bool live: root.phase === "running" || root.phase === "paused"

  function elapsedText() {
    if (!root.service) return Model.formatClock(0);
    void root.service.tickVersion;
    if (root.live) return Model.formatClock(Math.floor(root.service.flowElapsedMs() / 1000));
    return Model.formatClock(0);
  }

  function breakHint() {
    if (!root.service || !root.live) return "";
    var el = Math.floor(root.service.flowElapsedMs() / 1000);
    var sug = TimerEngine.suggestedBreakSec(el, root.service.settings.flowtime);
    return "Suggested break: " + Model.formatDur(sug);
  }

  function interruptionsText() {
    if (!root.service) return "";
    var n = root.service.timer.interruptions || 0;
    return n === 1 ? "1 interruption" : n + " interruptions";
  }

  // ---- Contador ----
  Text {
    textFormat: Text.PlainText
    text: root.elapsedText()
    color: root.phase === "paused" ? Color.muted : Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    Layout.topMargin: Style.space(6)
  }

  // ---- Estado ----
  Text {
    textFormat: Text.PlainText
    text: root.live
      ? (root.interruptionsText() + " · " + root.breakHint())
      : "Count up. Finish when focus ends."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
  }

  // ---- Botões: stopped ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: !root.live

    FlowButton {
      text: "Start"
      primary: true
      onClicked: if (root.service) root.service.startFlowtime()
    }
  }

  // ---- Botões: running ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "running"

    FlowButton {
      text: "Pause"
      onClicked: if (root.service) root.service.pauseTimer()
    }
    FlowButton {
      text: "+ Interruption"
      onClicked: if (root.service) root.service.addInterruption()
    }
    FlowButton {
      text: "Stop"
      onClicked: if (root.service) root.service.stopTimer()
    }
  }

  // ---- Botões: paused ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "paused"

    FlowButton {
      text: "Resume"
      primary: true
      onClicked: if (root.service) root.service.resumeTimer()
    }
    FlowButton {
      text: "Stop"
      onClicked: if (root.service) root.service.stopTimer()
    }
  }

  // ---- Finish buttons (só quando live) ----
  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.live

    FlowButton {
      text: "Finish focus"
      primary: true
      onClicked: if (root.service) root.service.finishFlowtime("focus")
    }
    FlowButton {
      text: "Finish + break"
      onClicked: if (root.service) root.service.finishFlowtime("break")
    }
  }
}
```

---

## 6. Métodos de timer no `Service.qml`

Adicionar ao `Service.qml`:

```qml
  // ============================ Timer actions ============================

  function startPomodoro(taskId) {
    var now = root.nowMs();
    var t = Model.blankTimer();
    t.mode = "pomodoro";
    t.phase = "running";
    t.technique = "pomodoro";
    t.taskId = taskId !== undefined && taskId !== null ? String(taskId) : root.activeTaskId;
    t.startedAtMs = now;
    t.deadlineMs = now + root.settings.focus.focusSec * 1000;
    root.timer = t;
    root.bump();
    root.saveSoon();
  }

  function startFlowtime(taskId) {
    var now = root.nowMs();
    var t = Model.blankTimer();
    t.mode = "flowtime";
    t.phase = "running";
    t.technique = "flowtime";
    t.taskId = taskId !== undefined && taskId !== null ? String(taskId) : root.activeTaskId;
    t.startedAtMs = now;
    t.accumulatedMs = 0;
    t.interruptions = 0;
    root.timer = t;
    root.bump();
    root.saveSoon();
  }

  function pauseTimer() {
    var t = root.timer;
    if (t.phase !== "running") return;
    var c = cloneTimer(t);
    if (c.mode === "pomodoro") {
      c.pausedRemainingMs = Math.max(0, c.deadlineMs - root.nowMs());
    } else if (c.mode === "flowtime") {
      c.accumulatedMs = TimerEngine.flowElapsedMs(c, root.nowMs());
    }
    c.phase = "paused";
    root.timer = c;
    root.bump();
    root.saveSoon();
  }

  function resumeTimer() {
    var t = root.timer;
    if (t.phase !== "paused") return;
    var c = cloneTimer(t);
    if (c.mode === "pomodoro") {
      c.deadlineMs = root.nowMs() + Math.max(0, c.pausedRemainingMs);
      c.pausedRemainingMs = 0;
    } else if (c.mode === "flowtime") {
      c.startedAtMs = root.nowMs();
    }
    c.phase = "running";
    root.timer = c;
    root.bump();
    root.saveSoon();
  }

  function stopTimer() {
    var blank = Model.blankTimer();
    blank.technique = root.settings.focus.focusAction;
    root.timer = blank;
    root.bump();
    root.saveSoon();
  }

  function skipBreak() {
    if (root.timer.phase !== "break") return;
    var c = cloneTimer(root.timer);
    c.phase = "stopped";
    c.breakKind = "";
    c.breakTotalMs = 0;
    root.timer = c;
    root.bump();
    root.saveSoon();
  }

  function addInterruption() {
    var t = root.timer;
    if (t.mode !== "flowtime" || (t.phase !== "running" && t.phase !== "paused")) return;
    var c = cloneTimer(t);
    c.interruptions = (c.interruptions || 0) + 1;
    root.timer = c;
    root.bump();
    root.saveSoon();
  }

  function finishFlowtime(finishKind) {
    var t = root.timer;
    if (t.mode !== "flowtime" || (t.phase !== "running" && t.phase !== "paused")) return;
    var elapsedSec = Math.floor(TimerEngine.flowElapsedMs(t, root.nowMs()) / 1000);
    var taskId = t.taskId;
    var interruptions = t.interruptions || 0;
    var c = Model.blankTimer();
    c.technique = "flowtime";
    if (elapsedSec >= 10) {
      root.recordSession("flow", taskId, elapsedSec, interruptions, t.startedAtMs);
    }
    if (finishKind === "break" && elapsedSec >= 10) {
      var suggested = TimerEngine.suggestedBreakSec(elapsedSec, root.settings.flowtime);
      c.mode = "flowtime";
      c.phase = "break";
      c.taskId = taskId;
      c.breakKind = "flow";
      c.breakTotalMs = suggested * 1000;
      c.startedAtMs = root.nowMs();
      c.deadlineMs = root.nowMs() + suggested * 1000;
    }
    root.timer = c;
    root.bump();
    root.saveNow();
  }

  function completePomodoro() {
    var t = root.timer;
    var focusSec = root.settings.focus.focusSec;
    var taskId = t.taskId;
    root.recordSession("pomo", taskId, focusSec, 0, t.startedAtMs);
    var done = (t.pomodorosDone || 0) + 1;
    var longEvery = Math.max(1, root.settings.focus.longBreakInterval);
    var isLong = (done % longEvery) === 0;
    var breakSec = isLong ? root.settings.focus.longBreakSec : root.settings.focus.shortBreakSec;
    var c = Model.blankTimer();
    c.technique = "pomodoro";
    c.pomodorosDone = done;
    c.taskId = taskId;
    if (breakSec > 0) {
      c.mode = "pomodoro";
      c.phase = "break";
      c.breakKind = isLong ? "long" : "short";
      c.breakTotalMs = breakSec * 1000;
      c.startedAtMs = root.nowMs();
      c.deadlineMs = root.nowMs() + breakSec * 1000;
      root.notify("timer", "Pomodoro complete",
        isLong ? "Long break started — step away." : "Short break started — breathe.");
    } else {
      root.notify("timer", "Pomodoro complete", "Well done. Ready for the next one.");
    }
    root.timer = c;
    root.bump();
    root.saveNow();
  }

  function completeBreak() {
    var c = cloneTimer(root.timer);
    c.phase = "stopped";
    c.breakKind = "";
    c.breakTotalMs = 0;
    root.timer = c;
    root.notify("timer", "Break complete", "Time to get back into focus.");
    root.bump();
    root.saveNow();
  }

  function cloneTimer(t) {
    return {
      mode: t.mode, phase: t.phase, taskId: t.taskId,
      startedAtMs: t.startedAtMs, deadlineMs: t.deadlineMs,
      pausedRemainingMs: t.pausedRemainingMs, accumulatedMs: t.accumulatedMs,
      interruptions: t.interruptions, pomodorosDone: t.pomodorosDone,
      breakKind: t.breakKind, breakTotalMs: t.breakTotalMs, technique: t.technique
    };
  }

  function recordSession(kind, taskId, durationSec, interruptions, startedAt) {
    if (!(durationSec > 0)) return;
    var now = root.nowMs();
    var sess = {
      id: Model.uid("sess"), kind: kind,
      taskId: taskId ? String(taskId) : null,
      boardId: root.activeBoardId,
      startedAt: startedAt || (now - durationSec * 1000),
      endedAt: now,
      durationSec: Math.floor(durationSec),
      interruptions: interruptions || 0
    };
    var next = root.sessions.concat([sess]);
    if (next.length > 2000) next = next.slice(next.length - 2000);
    root.sessions = next;
    if (taskId) {
      var tasks = root.tasks.map(function(task) {
        if (task.id !== taskId) return task;
        var c = {};
        for (var k in task) c[k] = task[k];
        c.totalFocusSeconds = (c.totalFocusSeconds || 0) + Math.floor(durationSec);
        if (kind === "pomo") c.pomodoroSessions = (c.pomodoroSessions || 0) + 1;
        else c.flowtimeSessions = (c.flowtimeSessions || 0) + 1;
        c.interruptions = (c.interruptions || 0) + (interruptions || 0);
        c.updatedAt = now;
        return c;
      });
      root.tasks = tasks;
    }
  }

  // Reconcile on tick
  function onTick() {
    root.tickVersion++;
    var t = root.timer;
    if (t.phase !== "running" && t.phase !== "break") return;
    if (t.mode === "flowtime" && t.phase === "running") return;
    if ((t.deadlineMs || 0) > root.nowMs()) return;
    if (t.mode === "pomodoro" && t.phase === "running") root.completePomodoro();
    else if (t.phase === "break") root.completeBreak();
  }

  // Atualização de técnica
  function updateFocusAction(action) {
    var next = {};
    for (var k in root.settings.focus) next[k] = root.settings.focus[k];
    next.focusAction = (action === "flowtime") ? "flowtime" : "pomodoro";
    root.settings.focus = next;
    if (root.timer && root.timer.phase === "stopped") {
      var c = cloneTimer(root.timer);
      c.technique = next.focusAction;
      root.timer = c;
    }
    root.bump();
    root.saveSoon();
  }
```

---

## 7. IPC de timer no `Service.qml`

```qml
  IpcHandler {
    target: "io.github.yks777.kairos"

    // ... IPC existente ...

    function start(): string {
      if (root.timer.phase === "paused") root.resumeTimer();
      else if (root.timer.phase === "stopped") {
        if (root.settings.focus.focusAction === "flowtime") root.startFlowtime();
        else root.startPomodoro();
      }
      return "ok";
    }
    function pause(): string { root.pauseTimer(); return "ok"; }
    function stop(): string { root.stopTimer(); return "ok"; }
    function resume(): string { root.resumeTimer(); return "ok"; }
    function finish(kind: string): string {
      var t = root.timer;
      if (t.mode === "pomodoro" && t.phase === "running") root.completePomodoro();
      else root.finishFlowtime(kind === "break" ? "break" : "focus");
      return "ok";
    }
    function interrupt(): string { root.addInterruption(); return "ok"; }
  }
```

---

# PARTE B — ABA PLAN

## 8. Layout da aba Plan

### 8.1. Vista completa

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ KAIROS   Stay Hard                                                    ⚙    ×        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ [Day] [Focus] [Plan] [Stats] [Markets] [Social]                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ MATRIX                                              [ Completed (3) ]                │
│                                                                                     │
│ ┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐            │
│ │ Q1 · DO      (2)│ Q2 · SCHEDULE(1)│ Q3 · DELEGATE(0)│ Q4 · DELETE  (1)│            │
│ │ Urgent+Important│ Important,not urg│ Urgent,not imp │ Neither         │            │
│ ├─────────────────┼─────────────────┼─────────────────┼─────────────────┤            │
│ │ ┌─────────────┐ │ ┌─────────────┐ │                 │ ┌─────────────┐ │            │
│ │ │● Refactor   │ │ │● Write blog │ │      Empty      │ │● Clean desk │ │            │
│ │ │  auth flow  │ │ │  post       │ │                 │ │             │ │            │
│ │ │       25m   │ │ │             │ │                 │ │             │ │            │
│ │ └─────────────┘ │ └─────────────┘ │                 │ └─────────────┘ │            │
│ │ [ + Add task ]  │ [ + Add task ]  │ [ + Add task ]  │ [ + Add task ]  │            │
│ └─────────────────┴─────────────────┴─────────────────┴─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 8.2. Estrutura

1. **Toolbar** — `MATRIX` + `[ Completed (n) ]`.
2. **Quatro quadrantes** iguais.
3. Cada quadrante: header + divisor + `ListView` de `TaskCard` + `+ Add task`.
4. **TaskCard**: dot de prioridade, título, duração, menu hover.
5. **Completed popup**: overlay + card com busca.

---

## 9. `views/PlanView.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components/plan"

Item {
  id: root
  property var service: null

  property string menuTaskId: ""
  property bool completedOpen: false
  property string completedQuery: ""

  Layout.fillWidth: true
  Layout.fillHeight: true

  function toggleCardMenu(id) {
    root.menuTaskId = (root.menuTaskId === id ? "" : id);
  }

  readonly property var doneList: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.completedTasks(root.completedQuery);
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    MatrixToolbar {
      service: root.service
      onOpenCompleted: {
        root.completedQuery = "";
        root.completedOpen = true;
      }
    }

    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true
      Layout.fillHeight: true

      MatrixColumn {
        service: root.service
        columnId: "q1"
        title: "Q1 · DO"
        subtitle: "Urgent + Important"
        menuTaskId: root.menuTaskId
        onCardMenu: function(id) { root.toggleCardMenu(id); }
      }
      MatrixColumn {
        service: root.service
        columnId: "q2"
        title: "Q2 · SCHEDULE"
        subtitle: "Important, not urgent"
        menuTaskId: root.menuTaskId
        onCardMenu: function(id) { root.toggleCardMenu(id); }
      }
      MatrixColumn {
        service: root.service
        columnId: "q3"
        title: "Q3 · DELEGATE"
        subtitle: "Urgent, not important"
        menuTaskId: root.menuTaskId
        onCardMenu: function(id) { root.toggleCardMenu(id); }
      }
      MatrixColumn {
        service: root.service
        columnId: "q4"
        title: "Q4 · DELETE"
        subtitle: "Neither"
        menuTaskId: root.menuTaskId
        onCardMenu: function(id) { root.toggleCardMenu(id); }
      }
    }
  }

  // Completed popup
  CompletedPopup {
    visible: root.completedOpen
    query: root.completedQuery
    items: root.doneList
    service: root.service
    onQueryChanged: function(q) { root.completedQuery = q; }
    onClose: { root.completedOpen = false; }
  }
}
```

---

## 10. `components/plan/MatrixToolbar.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property var service: null
  signal openCompleted()

  spacing: Style.space(8)
  Layout.fillWidth: true

  readonly property int doneCount: {
    if (!root.service) return 0;
    void root.service.revision;
    return root.service.completedCount();
  }

  Text {
    textFormat: Text.PlainText
    text: "MATRIX"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
  }

  Item { Layout.fillWidth: true }

  FlowButton {
    text: "Completed (" + root.doneCount + ")"
    onClicked: root.openCompleted()
  }
}
```

---

## 11. `components/plan/MatrixColumn.qml`

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons

ColumnLayout {
  id: root

  property var service: null
  property string columnId: "q1"
  property string title: "Q1 · DO"
  property string subtitle: ""
  property bool editorOpen: false
  property string menuTaskId: ""
  property bool dropHighlight: false
  property bool listFrozen: false

  signal cardMenu(string taskId)

  spacing: Style.space(6)
  Layout.fillWidth: true
  Layout.fillHeight: true

  readonly property var columnTasks: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.tasksForColumn(root.columnId);
  }

  // ---- Header ----
  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    RowLayout {
      spacing: Style.space(6)
      Layout.alignment: Qt.AlignHCenter

      Text {
        textFormat: Text.PlainText
        text: root.title
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }
      Text {
        textFormat: Text.PlainText
        text: String(root.columnTasks.length)
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      textFormat: Text.PlainText
      text: root.subtitle
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      visible: root.subtitle !== ""
      horizontalAlignment: Text.AlignHCenter
      Layout.fillWidth: true
    }
  }

  // ---- Divider ----
  Rectangle {
    height: Math.max(1, Style.space(1))
    color: root.dropHighlight ? Color.accent : Color.popups.border
    opacity: root.dropHighlight ? 1.0 : 0.5
    Layout.fillWidth: true
  }

  // ---- ListView of tasks ----
  ListView {
    id: list
    model: root.columnTasks
    spacing: Style.space(6)
    clip: true
    interactive: !root.listFrozen
    Layout.fillWidth: true
    Layout.fillHeight: true

    ScrollBar.vertical: ScrollBar {
      policy: ScrollBar.AsNeeded
      visible: list.contentHeight > list.height + 1
      background: Item { implicitWidth: Style.space(6) }
      contentItem: Rectangle {
        implicitWidth: Style.space(6)
        radius: width / 2
        color: Color.muted
      }
    }

    // Drop target
    DropArea {
      anchors.fill: parent
      onEntered: root.dropHighlight = true
      onExited: root.dropHighlight = false
      onDropped: function(drop) {
        root.dropHighlight = false;
        if (!root.service || !drop || !drop.source || !drop.source.task) return;
        var taskId = String(drop.source.task.id);
        var fromCol = String(drop.source.task.columnId || "");
        if (fromCol === root.columnId) return;
        root.service.moveTask(taskId, root.columnId);
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: Color.accent
      opacity: root.dropHighlight ? 0.10 : 0.0
    }

    delegate: TaskCard {
      required property var modelData
      required property int index
      task: modelData
      width: list.width
      isActive: root.service ? root.service.activeTaskId === modelData.id : false
      menuOpen: root.menuTaskId === modelData.id
      timerLive: root.service ? (root.service.timer.phase === "running"
        || root.service.timer.phase === "paused"
        || root.service.timer.phase === "break") : false
      focusAction: root.service ? String(root.service.settings.focus.focusAction || "pomodoro") : "pomodoro"
      onToggleMenu: root.cardMenu(modelData.id)
      onStartFocus: {
        if (!root.service) return;
        root.service.setActiveTask(modelData.id);
        if (String(root.service.settings.focus.focusAction || "pomodoro") === "flowtime")
          root.service.startFlowtime(modelData.id);
        else root.service.startPomodoro(modelData.id);
      }
      onDone: { if (root.service) root.service.completeTask(modelData.id); }
      onEditSave: function(title) { if (root.service) root.service.updateTask(modelData.id, { title: title }); }
      onRemove: { if (root.service) root.service.deleteTask(modelData.id); }
      onDragStarted: root.listFrozen = true
      onDragFinished: root.listFrozen = false
    }

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: "Empty"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      visible: root.columnTasks.length === 0 && !root.editorOpen
    }
  }

  // ---- Editor ----
  TaskEditor {
    id: editor
    visible: root.editorOpen
    Layout.fillWidth: true
    onSaved: function(title) {
      if (root.service) root.service.createTask(title, root.columnId);
      root.editorOpen = false;
    }
    onCancelled: root.editorOpen = false
  }

  onEditorOpenChanged: {
    if (root.editorOpen) Qt.callLater(function() { editor.focusInput(); });
  }

  FlowButton {
    text: "+ Add task"
    visible: !root.editorOpen
    Layout.fillWidth: true
    onClicked: {
      root.editorOpen = true;
      Qt.callLater(function() { editor.focusInput(); });
    }
  }
}
```

---

## 12. `components/plan/TaskCard.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/Model.js" as Model

Rectangle {
  id: root
  property var task: null
  property bool isActive: false
  property bool menuOpen: false
  property bool timerLive: false
  property string focusAction: "pomodoro"

  signal toggleMenu()
  signal startFocus()
  signal done()
  signal editSave(string title)
  signal remove()
  signal dragStarted()
  signal dragFinished()

  property bool confirmingDelete: false
  property bool confirmingSwitch: false
  property bool editing: false
  property bool dragging: false
  property string dragImage: ""

  implicitWidth: 200
  implicitHeight: main.implicitHeight + Style.space(16)
  radius: Style.cornerRadius
  color: "transparent"
  border.color: root.dragging ? Color.accent
              : (root.menuOpen ? Color.accent
              : (hover.containsMouse ? Color.popups.border : "transparent"))
  border.width: Math.max(1, Style.space(1))
  opacity: root.dragging ? 0.7 : 1.0

  Drag.active: root.dragging
  Drag.source: root
  Drag.imageSource: root.dragImage
  Drag.hotSpot.x: width / 2
  Drag.hotSpot.y: Style.space(16)

  function endDrag() {
    if (root.dragging) {
      root.dragging = false;
      root.dragImage = "";
      root.dragFinished();
    }
  }

  function beginDrag() {
    if (root.editing || root.dragging) return;
    if (root.menuOpen) root.toggleMenu();
    try {
      root.grabToImage(function(result) {
        if (result && result.url) root.dragImage = String(result.url);
        root.dragging = true;
        root.dragStarted();
      });
    } catch (e) {
      root.dragging = true;
      root.dragStarted();
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: Color.accent
    opacity: root.isActive ? 0.10 : 0.0
  }

  MouseArea {
    id: clickCatcher
    anchors.fill: parent
    pressAndHoldInterval: 350
    preventStealing: true
    cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    onClicked: {
      if (root.editing || root.dragging) return;
      root.confirmingSwitch = false;
      root.toggleMenu();
    }
    onPressAndHold: root.beginDrag()
    onReleased: root.endDrag()
    onCanceled: root.endDrag()
  }

  ColumnLayout {
    id: main
    anchors.fill: parent
    anchors.margins: Style.space(8)
    spacing: Style.space(6)

    RowLayout {
      spacing: Style.space(6)
      Layout.fillWidth: true

      Rectangle {
        width: Style.space(8)
        height: width
        radius: width / 2
        color: !root.task ? Color.muted
          : root.task.priority === "high" ? Color.urgent
          : root.task.priority === "low" ? Color.muted : Color.accent
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        textFormat: Text.PlainText
        text: root.task ? root.task.title : ""
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        maximumLineCount: 2
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        visible: !root.editing
      }

      FlowInput {
        id: titleEditor
        text: root.task ? root.task.title : ""
        placeholder: "Task title..."
        visible: root.editing
        Layout.fillWidth: true
        onAccepted: { root.editing = false; root.editSave(titleEditor.text); }
        onCancelled: { root.editing = false; }
      }

      Text {
        textFormat: Text.PlainText
        text: root.task ? Model.formatDur(root.task.totalFocusSeconds) : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        visible: root.task && root.task.totalFocusSeconds > 0 && !root.editing
      }

      Text {
        textFormat: Text.PlainText
        text: "●"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        visible: root.isActive
      }
    }

    ColumnLayout {
      spacing: Style.space(4)
      Layout.fillWidth: true
      visible: (hover.containsMouse || root.menuOpen) && !root.editing

      RowLayout {
        spacing: Style.space(4)
        Layout.alignment: Qt.AlignHCenter

        MiniAction {
          label: root.confirmingSwitch ? "Switch?" : "Focus"
          accent: true
          onClicked: {
            if (root.timerLive && !root.confirmingSwitch) {
              root.confirmingSwitch = true;
            } else {
              root.confirmingSwitch = false;
              root.startFocus();
            }
          }
        }
        MiniAction {
          label: "Done"
          onClicked: { root.confirmingSwitch = false; root.done(); }
        }
      }

      RowLayout {
        spacing: Style.space(4)
        Layout.alignment: Qt.AlignHCenter

        MiniAction {
          label: "Edit"
          onClicked: {
            root.confirmingSwitch = false;
            root.editing = true;
            Qt.callLater(function() { titleEditor.focusInput(); });
          }
        }
        MiniAction {
          label: root.confirmingDelete ? "Confirm delete" : "Delete"
          danger: true
          onClicked: {
            root.confirmingSwitch = false;
            if (root.confirmingDelete) { root.confirmingDelete = false; root.remove(); }
            else root.confirmingDelete = true;
          }
        }
      }
    }
  }

  component MiniAction: Item {
    id: mini
    property string label: ""
    property bool accent: false
    property bool danger: false
    signal clicked()
    implicitWidth: Math.max(56, miniLabel.implicitWidth + Style.space(16))
    implicitHeight: Style.space(28)

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: mini.danger ? Color.urgent : Color.accent
      opacity: hoverMini.containsMouse ? 0.25 : 0.10
    }
    Text {
      id: miniLabel
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: mini.label
      color: mini.danger ? Color.urgent : (mini.accent ? Color.accent : Color.popups.text)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    MouseArea {
      id: hoverMini
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: mini.clicked()
    }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
```

---

## 13. `components/plan/TaskEditor.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  signal saved(string title)
  signal cancelled()

  spacing: Style.space(6)
  Layout.fillWidth: true

  FlowInput {
    id: input
    placeholder: "Task title..."
    Layout.fillWidth: true
    onAccepted: if (input.text.trim() !== "") root.saved(input.text)
    onCancelled: root.cancelled()
  }

  FlowButton {
    text: "Add"
    primary: true
    onClicked: if (input.text.trim() !== "") root.saved(input.text)
  }

  FlowIconButton {
    glyph: "×"
    boxSize: 32
    onClicked: root.cancelled()
  }

  function focusInput() { input.focusInput(); }
}
```

---

## 14. `components/plan/CompletedPopup.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

Item {
  id: root
  property string query: ""
  property var items: []
  property var service: null

  signal queryChanged(string q)
  signal close()

  anchors.fill: parent

  // Overlay
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)
    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }
  }

  // Card
  Rectangle {
    anchors.centerIn: parent
    width: Math.min(parent.width, Style.space(420))
    height: Math.min(parent.height, Style.space(380))
    radius: Style.cornerRadius
    color: Color.popups.background
    border.color: Color.popups.border
    border.width: Math.max(1, Style.space(1))

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(8)

      RowLayout {
        spacing: Style.space(8)
        Layout.fillWidth: true

        Text {
          textFormat: Text.PlainText
          text: "COMPLETED (" + root.items.length + ")"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          Layout.fillWidth: true
        }
        FlowIconButton {
          glyph: "×"
          onClicked: root.close()
        }
      }

      FlowInput {
        id: search
        placeholder: "Search completed..."
        text: root.query
        Layout.fillWidth: true
        onTextChanged: root.queryChanged(text)
      }

      ListView {
        id: list
        model: root.items
        spacing: Style.space(6)
        clip: true
        Layout.fillWidth: true
        Layout.fillHeight: true

        delegate: Rectangle {
          required property var modelData
          width: list.width
          implicitHeight: row.implicitHeight + Style.space(12)
          radius: Style.cornerRadius
          color: "transparent"
          border.color: Color.popups.border
          border.width: Math.max(1, Style.space(1))

          RowLayout {
            id: row
            anchors.fill: parent
            anchors.margins: Style.space(8)
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: modelData.title
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            FlowButton {
              text: "Restore"
              onClicked: if (root.service) root.service.reopenTask(modelData.id)
            }
            FlowIconButton {
              glyph: "×"
              onClicked: if (root.service) root.service.deleteTask(modelData.id)
            }
          }
        }

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.query !== "" ? "No matches" : "Nothing completed yet"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          visible: root.items.length === 0
        }
      }
    }
  }
}
```

---

## 15. Métodos de tasks no `Service.qml`

```qml
  // ============================ Boards / Tasks ============================

  function tasksForColumn(columnId) {
    var out = [];
    for (var i = 0; i < root.tasks.length; i++) {
      var t = root.tasks[i];
      if (t.boardId !== root.activeBoardId || t.columnId !== columnId) continue;
      if (t.completedAt) continue;
      out.push(t);
    }
    out.sort(function(a, b) { return a.createdAt - b.createdAt; });
    return out;
  }

  function completedTasks(query) {
    var q = String(query || "").trim().toLowerCase();
    var out = [];
    for (var j = 0; j < root.tasks.length; j++) {
      var c = root.tasks[j];
      if (c.boardId !== root.activeBoardId || !c.completedAt) continue;
      if (q !== "" && c.title.toLowerCase().indexOf(q) === -1) continue;
      out.push(c);
    }
    out.sort(function(a, b) { return (b.completedAt || 0) - (a.completedAt || 0); });
    return out;
  }

  function completedCount() {
    var n = 0;
    for (var i = 0; i < root.tasks.length; i++) {
      if (root.tasks[i].boardId === root.activeBoardId && root.tasks[i].completedAt) n++;
    }
    return n;
  }

  function activeTask() {
    if (!root.activeTaskId) return null;
    for (var i = 0; i < root.tasks.length; i++) {
      if (root.tasks[i].id === root.activeTaskId) return root.tasks[i];
    }
    return null;
  }

  function setActiveTask(taskId) {
    root.activeTaskId = taskId ? String(taskId) : "";
    root.bump();
    root.saveSoon();
  }

  function createTask(title, columnId) {
    var name = String(title || "").trim().slice(0, 200);
    if (name === "") return "";
    var col = columnId || "q1";
    if (["q1", "q2", "q3", "q4"].indexOf(col) === -1) col = "q1";
    var now = root.nowMs();
    var t = {
      id: Model.uid("task"),
      boardId: root.activeBoardId,
      columnId: col,
      title: name,
      description: "",
      priority: "normal",
      createdAt: now, updatedAt: now, completedAt: null,
      totalFocusSeconds: 0, pomodoroSessions: 0, flowtimeSessions: 0, interruptions: 0
    };
    root.tasks = root.tasks.concat([t]);
    root.bump();
    root.saveNow();
    return t.id;
  }

  function updateTask(taskId, fields) {
    var now = root.nowMs();
    var ok = false;
    root.tasks = root.tasks.map(function(t) {
      if (t.id !== taskId) return t;
      ok = true;
      var c = {};
      for (var k in t) c[k] = t[k];
      if (fields.title !== undefined) {
        var name = String(fields.title).trim().slice(0, 200);
        if (name !== "") c.title = name;
      }
      c.updatedAt = now;
      return c;
    });
    if (ok) { root.bump(); root.saveNow(); }
    return ok;
  }

  function moveTask(taskId, columnId) {
    if (["q1", "q2", "q3", "q4"].indexOf(columnId) === -1) return false;
    var now = root.nowMs();
    var ok = false;
    root.tasks = root.tasks.map(function(t) {
      if (t.id !== taskId) return t;
      ok = true;
      var c = {};
      for (var k in t) c[k] = t[k];
      c.columnId = columnId;
      c.completedAt = null;
      c.updatedAt = now;
      return c;
    });
    if (ok) { root.bump(); root.saveNow(); }
    return ok;
  }

  function completeTask(taskId) {
    var now = root.nowMs();
    var ok = false;
    root.tasks = root.tasks.map(function(t) {
      if (t.id !== taskId) return t;
      ok = true;
      var c = {};
      for (var k in t) c[k] = t[k];
      c.completedAt = now;
      c.updatedAt = now;
      return c;
    });
    if (ok) { root.bump(); root.saveNow(); }
    return ok;
  }

  function reopenTask(taskId) {
    var now = root.nowMs();
    var ok = false;
    root.tasks = root.tasks.map(function(t) {
      if (t.id !== taskId) return t;
      ok = true;
      var c = {};
      for (var k in t) c[k] = t[k];
      if (["q1", "q2", "q3", "q4"].indexOf(c.columnId) === -1) c.columnId = "q1";
      c.completedAt = null;
      c.updatedAt = now;
      return c;
    });
    if (ok) { root.bump(); root.saveNow(); }
    return ok;
  }

  function deleteTask(taskId) {
    var before = root.tasks.length;
    root.tasks = root.tasks.filter(function(t) { return t.id !== taskId; });
    if (root.tasks.length === before) return false;
    if (root.activeTaskId === taskId) root.activeTaskId = "";
    if (root.timer.taskId === taskId) {
      var c = cloneTimer(root.timer);
      c.taskId = null;
      root.timer = c;
    }
    root.bump();
    root.saveNow();
    return true;
  }

  function history(range, kind) {
    return StatsEngine.filterSessions(root.sessions, range || "today", kind || "both", root.nowMs());
  }
```

---

## 16. Integração no `Panel.qml`

Substituir os placeholders:

```qml
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "focus"

          FocusView {
            anchors.fill: parent
            service: root.service
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "plan"

          PlanView {
            anchors.fill: parent
            service: root.service
          }
        }
```

Adicionar `import "views"` no topo do `Panel.qml`.

---

## 17. Testes automatizados

Criar `tests/timer-engine.test.js`:

- `pomodoroRemainingMs` retorna 0 quando `stopped`.
- `pomodoroRemainingMs` respeita `pausedRemainingMs` quando pausado.
- `pomodoroRemainingMs` decrementa com o tempo real.
- `flowElapsedMs` soma `accumulatedMs + (now - startedAtMs)` quando rodando.
- `flowElapsedMs` retorna `accumulatedMs` quando pausado.
- `suggestedBreakSec` tradicional: <= 25min → 5min; <= 50min → 8min; <= 90min → 10min; > 90min → 15min.
- `suggestedBreakSec` proporcional: 20% clampado entre min e max.

Criar `tests/stats-engine.test.js`:

- `filterSessions("today")` retorna apenas as sessões de hoje.
- `summarize` conta pomodoro, flow, interrupções, focusSec.
- `streak` conta dias consecutivos com focusSec >= minSec.
- `lastWeek` retorna 7 dias, ordem cronológica.

---

## ✅ CHECKPOINT DA PARTE 4

Ao final desta parte, verificar:

- [ ] Aba **Focus** abre com o contador centralizado.
- [ ] Chips `Pomodoro` / `Flowtime` refletem `settings.focus.focusAction`.
- [ ] Clicar em `Pomodoro` inicia countdown em 25:00.
- [ ] Clicar em `Flowtime` inicia count-up em 00:00.
- [ ] Botão `Start` inicia o timer correto.
- [ ] Botão `Pause` pausa; `Resume` retoma; `Stop` para.
- [ ] Break do Pomodoro aparece após o foco terminar.
- [ ] `Skip break` pula o break.
- [ ] `+ Interruption` incrementa o contador de interrupções no Flowtime.
- [ ] `Finish focus` e `Finish + break` funcionam no Flowtime.
- [ ] Barra mostra `⏱ 18:24` à direita do relógio durante o timer.
- [ ] Notificações disparam no fim de cada fase.
- [ ] `TODAY'S SESSIONS` lista as sessões do dia.
- [ ] Working on mostra a task ativa com `[ Change ]`.
- [ ] Aba **Plan** abre com quatro quadrantes.
- [ ] Clicar num card abre o menu (Focus / Done / Edit / Delete).
- [ ] `Focus` seta a task ativa e inicia o timer.
- [ ] `Done` completa e some do quadrante.
- [ ] `Edit` renomeia inline.
- [ ] `Delete` pergunta antes.
- [ ] Drag-and-drop entre quadrantes funciona.
- [ ] `+ Add task` compõe inline.
- [ ] `Completed (n)` abre o popup com busca.
- [ ] `Restore` devolve o card ao quadrante original.
- [ ] `node --test tests/` passa para `timer-engine` e `stats-engine`.
- [ ] `omarchy plugin validate` sai com exit 0.
- [ ] `qmllint` sai com exit 0 nos arquivos novos.
- [ ] Sem erros no console após 5 min.

# PARTE 5 — ABAS STATS E MARKETS

> **INSTRUÇÕES PARA A IA:** Este é o quinto de 6 prompts sequenciais. Você já tem fundação (Parte 1), barra + painel (Parte 2), aba Day + Obsidian + khal (Parte 3) e abas Focus + Plan (Parte 4). Agora implementa a **aba Stats** (retrospecto) e a **aba Markets** (watchlist, chart e conversor). Ao final, ambas estarão 100% funcionais.

---

## 1. Escopo da Parte 5

Ao final desta parte, você deve ter:

1. **`views/StatsView.qml`** — a aba completa (today grid, week bars, heatmap, history).
2. **`views/MarketsView.qml`** — a aba com 4 sub-abas (Watchlist, Convert, Crypto, Units).
3. **`components/markets/Watchlist.qml`** — lista da watchlist com drag-reorder.
4. **`components/markets/Chart.qml`** — Canvas com linha e range selector.
5. **`components/markets/RangeSelector.qml`** — chips `1H 4H 1D 5D 1M 3M 6M YTD 1Y 5Y MAX`.
6. **`components/markets/KeyStats.qml`** — open/prev close/volume/52w; variante crypto.
7. **`components/markets/CurrencyChip.qml`** — chip `USD ⇄`.
8. **`components/markets/SymbolSearch.qml`** — busca Yahoo + CoinGecko.
9. **`components/markets/PairEditor.qml`** — editor bidirecional.
10. **`components/markets/UnitCategoryPicker.qml`** — seletor de categoria.
11. **`logic/MarketsModel.js`** — quotes, Binance, CoinGecko, watchlist, session, staleness.
12. **`logic/ConverterModel.js`** — unidades, pivot USD, parse/format.
13. **`logic/NumberFormat.js`** — parseAmount e formatResult compartilhados.
14. **`services/MarketsService.qml`** — fetch de quotes e watchlist.
15. **`services/ConverterService.qml`** — fetch de rates fiat e crypto.
16. **`scripts/fetch-rates`** — open.er-api.com com cache.
17. **`scripts/fetch-crypto`** — CoinGecko com cache.
18. **Métodos agregados no `Service.qml`** — `history`, `todaySummary`, `weekData`, `heatmapData`, `quotes`, `watchlist`, `convertCurrency`, `convertUnit`.
19. **Integração no `Panel.qml`** — substituir os placeholders.
20. **Testes** — `markets-model.test.js`, `converter-model.test.js`.

**Não fazer ainda:** aba Social, Email, Settings.

---

# PARTE A — ABA STATS

## 2. Layout da aba Stats

### 2.1. Vista completa

```
┌─────────────────────────────────────────────────────────────┐
│ KAIROS   Stay Hard                              ⚙    ×      │
├─────────────────────────────────────────────────────────────┤
│ [Day] [Focus] [Plan] [Stats] [Markets] [Social]             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  TODAY                                                      │
│  ┌──────────┬──────────┬──────────┐                         │
│  │  2h15m   │    3     │    1     │                         │
│  │  Focus   │ Pomodoro │ Flowtime │                         │
│  ├──────────┼──────────┼──────────┤                         │
│  │    5     │    2     │    4     │                         │
│  │ Tasks    │ Interrup │ Streak   │                         │
│  └──────────┴──────────┴──────────┘                         │
│                                                             │
│  THIS WEEK                                                  │
│  Mon ████████░░░░░░░░░░░░░░░░░░  1h 10m                     │
│  Tue ██████████████░░░░░░░░░░░░  2h 05m                     │
│  Wed ████████████████████░░░░░░  2h 45m                     │
│  Thu ██████░░░░░░░░░░░░░░░░░░░░  45m                        │
│  Fri ░░░░░░░░░░░░░░░░░░░░░░░░░░  0m                         │
│  Sat ░░░░░░░░░░░░░░░░░░░░░░░░░░  0m                         │
│  Sun ░░░░░░░░░░░░░░░░░░░░░░░░░░  0m                         │
│                                                             │
│  FOCUS HEATMAP                                              │
│  ░░▒▒▓▓▒░░░▒▓▓▓▒░░░▒▒▓░░░▒▓▓▓▓░                             │
│  ░▒▓▓▒░░░▒▓▒░░░▒▓▓▓▒░░░▒▓▓▒░░░                              │
│                                                             │
│  HISTORY                                                    │
│  [Today] [Yesterday] [All]   [Both] [Pomo] [Flow]           │
│  ● Pomodoro · 25m                                14:20      │
│  ● Flowtime · 42m                                13:10      │
│  ● Pomodoro · 25m                                11:00      │
└─────────────────────────────────────────────────────────────┘
```

### 2.2. Estrutura vertical

1. **TODAY** — grid 3×2 com `Focus`, `Pomodoro`, `Flowtime`, `Tasks done`, `Interruptions`, `Streak`.
2. **THIS WEEK** — 7 linhas com barras proporcionais.
3. **FOCUS HEATMAP** — grade GitHub-style.
4. **HISTORY** — filtros e lista de sessões.

---

## 3. `views/StatsView.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../logic/Model.js" as Model
import "../logic/StatsEngine.js" as StatsEngine

ColumnLayout {
  id: root
  property var service: null

  property string range: "today"    // today | yesterday | all
  property string kind: "both"      // both | pomo | flow

  spacing: Style.space(10)
  Layout.fillWidth: true

  readonly property var today: {
    if (!root.service) return null;
    void root.service.revision;
    void root.service.tickVersion;
    return root.service.todaySummary();
  }

  readonly property var week: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.weekData();
  }

  readonly property var heatmap: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.heatmapData(12);   // 12 semanas
  }

  readonly property var hist: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.history(root.range, root.kind);
  }

  readonly property int weekMax: {
    var m = 60;
    for (var i = 0; i < root.week.length; i++) m = Math.max(m, root.week[i].focusSec);
    return m;
  }

  // ============================ TODAY ============================
  Text {
    textFormat: Text.PlainText
    text: "TODAY"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
  }

  GridLayout {
    columns: 3
    rowSpacing: Style.space(6)
    columnSpacing: Style.space(6)
    Layout.fillWidth: true

    StatCard { value: root.today ? Model.formatDur(root.today.focusSec) : "—"; label: "Focus" }
    StatCard { value: root.today ? String(root.today.pomoCount) : "—"; label: "Pomodoro" }
    StatCard { value: root.today ? String(root.today.flowCount) : "—"; label: "Flowtime" }
    StatCard { value: root.today ? String(root.today.tasksDone) : "—"; label: "Tasks done" }
    StatCard { value: root.today ? String(root.today.interruptions) : "—"; label: "Interruptions" }
    StatCard { value: root.today ? String(root.today.streak) : "—"; label: "Streak" }
  }

  // ============================ THIS WEEK ============================
  Text {
    textFormat: Text.PlainText
    text: "THIS WEEK"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
    Layout.topMargin: Style.space(4)
  }

  ColumnLayout {
    spacing: Style.space(3)
    Layout.fillWidth: true

    Repeater {
      model: root.week
      delegate: RowLayout {
        required property var modelData
        spacing: Style.space(8)
        Layout.fillWidth: true

        Text {
          textFormat: Text.PlainText
          text: modelData.label
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.preferredWidth: Style.space(32)
        }

        Rectangle {
          height: Style.space(10)
          radius: height / 2
          color: Color.accent
          opacity: modelData.focusSec > 0 ? 0.15 : 0.05
          Layout.fillWidth: true

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0.04, Math.min(1, modelData.focusSec / root.weekMax))
            radius: parent.radius
            color: Color.accent
            opacity: 0.85
          }
        }

        Text {
          textFormat: Text.PlainText
          text: Model.formatDur(modelData.focusSec)
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.preferredWidth: Style.space(52)
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }

  // ============================ HEATMAP ============================
  Text {
    textFormat: Text.PlainText
    text: "FOCUS HEATMAP"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
    Layout.topMargin: Style.space(4)
  }

  ColumnLayout {
    spacing: Style.space(2)
    Layout.fillWidth: true

    Repeater {
      model: 7   // uma linha por dia da semana
      delegate: RowLayout {
        required property int index
        spacing: Style.space(2)
        Layout.fillWidth: true

        Repeater {
          model: root.heatmap[index] || []
          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Style.space(12)
            radius: 2
            color: {
              var level = modelData.level;   // 0..4
              if (level === 0) return Util.alpha(Color.muted, 0.10);
              if (level === 1) return Util.alpha(Color.accent, 0.30);
              if (level === 2) return Util.alpha(Color.accent, 0.55);
              if (level === 3) return Util.alpha(Color.accent, 0.80);
              return Color.accent;
            }
          }
        }
      }
    }
  }

  // ============================ HISTORY ============================
  Text {
    textFormat: Text.PlainText
    text: "HISTORY"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
    Layout.topMargin: Style.space(4)
  }

  ColumnLayout {
    spacing: Style.space(4)
    Layout.fillWidth: true

    RowLayout {
      spacing: Style.space(4)
      Layout.fillWidth: true
      Item { Layout.fillWidth: true }
      Repeater {
        model: [
          { id: "today", label: "Today" },
          { id: "yesterday", label: "Yesterday" },
          { id: "all", label: "All" }
        ]
        delegate: Chip {
          required property var modelData
          label: modelData.label
          active: root.range === modelData.id
          onClicked: root.range = modelData.id
        }
      }
      Item { Layout.fillWidth: true }
    }

    RowLayout {
      spacing: Style.space(4)
      Layout.fillWidth: true
      Item { Layout.fillWidth: true }
      Repeater {
        model: [
          { id: "both", label: "Both" },
          { id: "pomo", label: "Pomo" },
          { id: "flow", label: "Flow" }
        ]
        delegate: Chip {
          required property var modelData
          label: modelData.label
          active: root.kind === modelData.id
          onClicked: root.kind = modelData.id
        }
      }
      Item { Layout.fillWidth: true }
    }
  }

  ColumnLayout {
    spacing: Style.space(3)
    Layout.fillWidth: true
    Layout.fillHeight: true

    Repeater {
      model: root.hist.slice(0, 30)
      delegate: RowLayout {
        required property var modelData
        spacing: Style.space(8)
        Layout.fillWidth: true

        Rectangle {
          width: Style.space(8)
          height: width
          radius: width / 2
          color: modelData.kind === "pomo" ? Color.accent : Color.muted
          Layout.alignment: Qt.AlignVCenter
        }
        Text {
          textFormat: Text.PlainText
          text: (modelData.kind === "pomo" ? "Pomodoro" : "Flowtime")
              + " · " + Model.formatDur(modelData.durationSec)
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
        Text {
          textFormat: Text.PlainText
          text: Qt.formatDateTime(new Date(modelData.startedAt), "HH:mm")
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    Text {
      visible: root.hist.length === 0
      textFormat: Text.PlainText
      text: "No sessions yet — start a Pomodoro or Flowtime."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      Layout.alignment: Qt.AlignHCenter
    }
  }

  // ============================ StatCard (componente local) ============================
  component StatCard: Rectangle {
    id: card
    property string value: ""
    property string label: ""

    Layout.fillWidth: true
    implicitHeight: Style.space(64)
    radius: Style.cornerRadius
    color: "transparent"
    border.color: Color.popups.border
    border.width: Math.max(1, Style.space(1))

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(6)
      spacing: 0

      Text {
        textFormat: Text.PlainText
        text: card.value
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        Layout.alignment: Qt.AlignHCenter
      }
      Text {
        textFormat: Text.PlainText
        text: card.label
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
```

---

## 4. Métodos agregados no `Service.qml` (Stats)

```qml
  // ============================ Stats ============================

  function liveExtraSec() {
    var t = root.timer;
    if (t.phase === "running" && t.mode === "pomodoro")
      return Math.floor((root.nowMs() - t.startedAtMs) / 1000);
    if (t.phase === "running" && t.mode === "flowtime")
      return Math.floor(TimerEngine.flowElapsedMs(t, root.nowMs()) / 1000);
    return 0;
  }

  function todaySummary() {
    var list = StatsEngine.filterSessions(root.sessions, "today", "both", root.nowMs());
    var s = StatsEngine.summarize(list);
    s.focusSec += root.liveExtraSec();
    s.tasksDone = StatsEngine.tasksDoneOnDay(root.tasks, root.nowMs());
    s.streak = StatsEngine.streak(root.sessions, root.settings.stats.streakMinSec, root.nowMs());
    return s;
  }

  function weekData() {
    return StatsEngine.lastWeek(root.sessions, root.nowMs());
  }

  // 12 semanas (ou N), retornando [[7 células da semana N], [7 da N-1], ...]
  // Cada célula: { date, focusSec, level }
  function heatmapData(weeks) {
    return StatsEngine.heatmap(root.sessions, weeks || 12, root.nowMs());
  }
```

Adicionar ao `logic/StatsEngine.js`:

```js
function heatmap(sessions, weeks, now) {
  now = now || Date.now();
  var totalDays = weeks * 7;
  var today = startOfDay(now);
  // Alinha ao início da semana atual (Sunday)
  var todayDow = new Date(today).getDay();
  var startDay = today - (todayDow * 86400000) - ((weeks - 1) * 7 * 86400000);

  var byDay = {};
  for (var i = 0; i < sessions.length; i++) {
    var k = startOfDay(sessions[i].startedAt);
    byDay[k] = (byDay[k] || 0) + (sessions[i].durationSec || 0);
  }

  var max = 0;
  for (var day = 0; day < totalDays; day++) {
    var ts = startDay + day * 86400000;
    if ((byDay[ts] || 0) > max) max = byDay[ts];
  }

  // 7 rows × N columns, retorna índice [weekday][week]
  var grid = [[], [], [], [], [], [], []];
  for (var w = 0; w < weeks; w++) {
    for (var d = 0; d < 7; d++) {
      var ts = startDay + (w * 7 + d) * 86400000;
      var sec = byDay[ts] || 0;
      var level = max === 0 ? 0
                : sec === 0 ? 0
                : Math.min(4, Math.max(1, Math.ceil((sec / max) * 4)));
      grid[d].push({ date: ts, focusSec: sec, level: level });
    }
  }
  return grid;
}
```

Exportar `heatmap` no final do `StatsEngine.js`.

---

# PARTE B — ABA MARKETS

## 5. Layout da aba Markets

### 5.1. Vista completa (sub-aba Watchlist)

```
┌─────────────────────────────────────────────────────────────────────┐
│ KAIROS   Stay Hard                                      ⚙    ×      │
├─────────────────────────────────────────────────────────────────────┤
│ [Day] [Focus] [Plan] [Stats] [Markets] [Social]                     │
├─────────────────────────────────────────────────────────────────────┤
│ [ Watchlist ]  [ Convert ]  [ Crypto ]  [ Units ]                    │
├─────────────────────────────────────────────────────────────────────┤
│ WATCHLIST                                          Updated 12m ago │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ ⠿  AAPL    Apple Inc.        305.59   ▲ +1.28 (+0.42%)        │  │
│  │ ⠿  NVDA    NVIDIA Corp.      485.20   ▼ -1.50 (-0.31%)        │  │
│  │ ⠿  BTC     Bitcoin        104,250.00  ▲ +1,250 (+1.21%)       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  BTC  ·  Bitcoin                                      Binance      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ 1H  4H [1D] 5D  1M  3M  6M  YTD  1Y  5Y  MAX                  │  │
│  │         ╱╲                                                    │  │
│  │        ╱  ╲    ╱╲                                             │  │
│  │   ╱╲  ╱    ╲  ╱  ╲                                            │  │
│  │  ╱  ╲╱      ╲╱    ╲                                           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Open      103,000.00      24h High    104,800.00                   │
│  Prev close 103,000.00     24h Low     102,500.00                   │
│  Volume    1.2B            52w Range   45,000 – 108,000             │
│  Market cap $2.05T         Circulating 19.7M BTC                    │
│                                                                     │
│  [ USD ⇄ ]   [ Open on Binance ↗ ]   [ × Remove ]                   │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2. Estrutura

Quatro sub-abas dentro da aba Markets:

```
[ Watchlist ]  [ Convert ]  [ Crypto ]  [ Units ]
```

---

## 6. `views/MarketsView.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components/markets"

ColumnLayout {
  id: root
  property var service: null

  property string subTab: "watchlist"     // watchlist | convert | crypto | units
  property string selectedSymbol: ""

  spacing: Style.space(10)
  Layout.fillWidth: true

  // ---- Sub-tabs ----
  RowLayout {
    spacing: Style.space(4)
    Layout.fillWidth: true

    Repeater {
      model: [
        { id: "watchlist", label: "Watchlist" },
        { id: "convert", label: "Convert" },
        { id: "crypto", label: "Crypto" },
        { id: "units", label: "Units" }
      ]
      delegate: Chip {
        required property var modelData
        label: modelData.label
        active: root.subTab === modelData.id
        onClicked: root.subTab = modelData.id
      }
    }
  }

  // ---- Sub-aba: Watchlist ----
  Watchlist {
    visible: root.subTab === "watchlist"
    service: root.service
    selectedSymbol: root.selectedSymbol
    onSymbolSelected: function(sym) { root.selectedSymbol = sym; }
    Layout.fillWidth: true
    Layout.fillHeight: true
  }

  // ---- Sub-aba: Convert (fiat) ----
  PairEditor {
    visible: root.subTab === "convert"
    mode: "fiat"
    service: root.service
    Layout.fillWidth: true
  }

  // ---- Sub-aba: Crypto ----
  PairEditor {
    visible: root.subTab === "crypto"
    mode: "crypto"
    service: root.service
    Layout.fillWidth: true
  }

  // ---- Sub-aba: Units ----
  PairEditor {
    visible: root.subTab === "units"
    mode: "units"
    service: root.service
    Layout.fillWidth: true
  }
}
```

---

## 7. `components/markets/Watchlist.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var service: null
  property string selectedSymbol: ""

  signal symbolSelected(string sym)

  spacing: Style.space(8)
  Layout.fillWidth: true
  Layout.fillHeight: true

  readonly property var quotes: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.quotes || [];
  }

  readonly property var selected: {
    for (var i = 0; i < root.quotes.length; i++)
      if (root.quotes[i].symbol === root.selectedSymbol) return root.quotes[i];
    return root.quotes.length > 0 ? root.quotes[0] : null;
  }

  // ---- Header ----
  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: "WATCHLIST"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
    Item { Layout.fillWidth: true }
    Text {
      textFormat: Text.PlainText
      text: root.service ? ("Updated " + root.service.marketsAgeLabel()) : ""
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    FlowIconButton {
      glyph: "\uf0450"     // nf-md-refresh
      onClicked: if (root.service) root.service.marketsRefresh()
    }
    FlowIconButton {
      glyph: "\uf0415"     // nf-md-plus
      onClicked: root.searchOpen = true
    }
  }

  // ---- List ----
  ListView {
    id: list
    model: root.quotes
    spacing: Style.space(4)
    clip: true
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(Style.space(180), contentHeight)

    delegate: Rectangle {
      required property var modelData
      width: list.width
      implicitHeight: Style.space(28)
      radius: Style.cornerRadius
      color: modelData.symbol === root.selectedSymbol
        ? Util.alpha(Color.accent, 0.15)
        : (rowHover.containsMouse ? Util.alpha(Color.muted, 0.08) : "transparent")

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.space(8)
        anchors.rightMargin: Style.space(8)
        spacing: Style.space(8)

        Text {
          textFormat: Text.PlainText
          text: "\uf0e75"     // nf-md-drag
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          textFormat: Text.PlainText
          text: modelData.symbol
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.preferredWidth: Style.space(60)
        }
        Text {
          textFormat: Text.PlainText
          text: modelData.name || ""
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
        Text {
          textFormat: Text.PlainText
          text: modelData.priceText || ""
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.preferredWidth: Style.space(90)
          horizontalAlignment: Text.AlignRight
        }
        Text {
          textFormat: Text.PlainText
          text: modelData.changeText || ""
          color: modelData.change < 0 ? Color.urgent : Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.preferredWidth: Style.space(120)
          horizontalAlignment: Text.AlignRight
        }
      }

      MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.symbolSelected(modelData.symbol)
      }
    }
  }

  // ---- Chart + KeyStats do selecionado ----
  Rectangle {
    height: Math.max(1, Style.space(1))
    color: Color.popups.border
    opacity: 0.5
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: root.selected ? (root.selected.symbol + "  ·  " + root.selected.name) : ""
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      Layout.fillWidth: true
    }
    Text {
      textFormat: Text.PlainText
      text: root.selected ? (root.selected.source || "") : ""
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  Chart {
    service: root.service
    symbol: root.selected ? root.selected.symbol : ""
    Layout.fillWidth: true
    Layout.preferredHeight: Style.space(140)
  }

  KeyStats {
    quote: root.selected
    Layout.fillWidth: true
  }

  // ---- Footer ----
  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    CurrencyChip {
      service: root.service
    }
    Item { Layout.fillWidth: true }

    FlowButton {
      text: "Open on Binance"
      onClicked: {
        if (root.service && root.selected)
          root.service.openUrl(root.service.binanceTradeUrl(root.selected.symbol));
      }
    }
    FlowButton {
      text: "Remove"
      onClicked: {
        if (root.service && root.selected)
          root.service.watchlistRemove(root.selected.symbol);
      }
    }
  }

  // ---- Symbol search ----
  property bool searchOpen: false
  SymbolSearch {
    visible: root.searchOpen
    service: root.service
    onClose: root.searchOpen = false
    Layout.fillWidth: true
  }
}
```

---

## 8. `components/markets/Chart.qml`

```qml
import QtQuick
import qs.Commons

Item {
  id: root
  property var service: null
  property string symbol: ""
  property string range: "1d"

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(4)

    RangeSelector {
      currentRange: root.range
      onRangeSelected: function(r) {
        root.range = r;
        if (root.service) root.service.marketsFetchSeries(root.symbol, r);
      }
      Layout.fillWidth: true
    }

    Canvas {
      id: canvas
      Layout.fillWidth: true
      Layout.fillHeight: true
      onPaint: root.paint(canvas)

      Connections {
        target: root.service
        function onRevisionChanged() { canvas.requestPaint(); }
      }
    }
  }

  function paint(ctx) {
    var w = canvas.width, h = canvas.height;
    ctx.reset();
    ctx.clearRect(0, 0, w, h);

    if (!root.service || !root.symbol) return;
    var series = root.service.marketsSeries(root.symbol, root.range);
    if (!series || series.length < 2) return;

    // Bounds
    var min = series[0].c, max = series[0].c;
    for (var i = 1; i < series.length; i++) {
      if (series[i].c < min) min = series[i].c;
      if (series[i].c > max) max = series[i].c;
    }
    var span = max - min;
    if (span <= 0) span = 1;

    var pad = Style.space(6);
    var innerW = w - pad * 2;
    var innerH = h - pad * 2;

    // Cor da linha segue o gain/loss (não a inclinação)
    var q = root.service.quoteFor(root.symbol);
    ctx.strokeStyle = (q && q.change < 0) ? Color.urgent : Color.accent;
    ctx.lineWidth = 2;
    ctx.beginPath();

    var t0 = series[0].t, t1 = series[series.length - 1].t;
    var tSpan = t1 - t0 || 1;

    for (var j = 0; j < series.length; j++) {
      var x = pad + ((series[j].t - t0) / tSpan) * innerW;
      var y = pad + ((max - series[j].c) / span) * innerH;
      if (j === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }
}
```

---

## 9. `components/markets/RangeSelector.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property string currentRange: "1d"
  signal rangeSelected(string range)

  spacing: Style.space(2)
  Layout.fillWidth: true

  readonly property var ranges: [
    { id: "1h", label: "1H" },
    { id: "4h", label: "4H" },
    { id: "1d", label: "1D" },
    { id: "5d", label: "5D" },
    { id: "1mo", label: "1M" },
    { id: "3mo", label: "3M" },
    { id: "6mo", label: "6M" },
    { id: "ytd", label: "YTD" },
    { id: "1y", label: "1Y" },
    { id: "5y", label: "5Y" },
    { id: "max", label: "MAX" }
  ]

  Repeater {
    model: root.ranges
    delegate: Item {
      required property var modelData
      implicitWidth: rangeLabel.implicitWidth + Style.space(12)
      implicitHeight: Style.space(24)

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Color.accent
        opacity: root.currentRange === modelData.id ? 0.22 : 0.0
      }
      Text {
        id: rangeLabel
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: modelData.label
        color: root.currentRange === modelData.id ? Color.accent : Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.rangeSelected(modelData.id)
      }
    }
  }
}
```

---

## 10. `components/markets/KeyStats.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/MarketsModel.js" as MM

ColumnLayout {
  id: root
  property var quote: null

  spacing: Style.space(4)
  Layout.fillWidth: true

  readonly property bool isCrypto: root.quote && root.quote.assetType === "crypto"

  GridLayout {
    columns: 2
    columnSpacing: Style.space(16)
    rowSpacing: Style.space(3)
    Layout.fillWidth: true

    // ---- Stock / Index ----
    StatRow { label: "Open";        value: root.quote ? MM.formatPrice(root.quote.open) : "";     visible: !root.isCrypto }
    StatRow { label: "Prev close";  value: root.quote ? MM.formatPrice(root.quote.prevClose) : ""; visible: !root.isCrypto }
    StatRow { label: "Day high";    value: root.quote ? MM.formatPrice(root.quote.dayHigh) : ""; visible: !root.isCrypto }
    StatRow { label: "Day low";     value: root.quote ? MM.formatPrice(root.quote.dayLow) : ""; visible: !root.isCrypto }
    StatRow { label: "Volume";      value: root.quote ? MM.formatVolume(root.quote.volume) : ""; visible: !root.isCrypto }
    StatRow { label: "52w range";   value: root.quote ? (MM.formatPrice(root.quote.week52Low) + " – " + MM.formatPrice(root.quote.week52High)) : ""; visible: !root.isCrypto }

    // ---- Crypto ----
    StatRow { label: "24h high";    value: root.quote ? MM.formatPrice(root.quote.dayHigh) : ""; visible: root.isCrypto }
    StatRow { label: "24h low";     value: root.quote ? MM.formatPrice(root.quote.dayLow) : ""; visible: root.isCrypto }
    StatRow { label: "Volume";      value: root.quote ? MM.formatVolume(root.quote.volume) : ""; visible: root.isCrypto }
    StatRow { label: "Market cap";  value: root.quote ? MM.formatMarketCap(root.quote.marketCap) : ""; visible: root.isCrypto }
    StatRow { label: "Circulating"; value: root.quote ? MM.formatSupply(root.quote.circulatingSupply, root.quote.symbol) : ""; visible: root.isCrypto }
  }

  component StatRow: RowLayout {
    id: row
    property string label: ""
    property string value: ""

    spacing: Style.space(6)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: row.label
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      Layout.preferredWidth: Style.space(80)
    }
    Text {
      textFormat: Text.PlainText
      text: row.value
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      Layout.fillWidth: true
    }
  }
}
```

---

## 11. `components/markets/CurrencyChip.qml`

```qml
import QtQuick
import qs.Commons

Rectangle {
  id: root
  property var service: null

  implicitWidth: chipLabel.implicitWidth + Style.space(16)
  implicitHeight: Style.space(24)
  radius: Style.cornerRadius
  color: "transparent"
  border.color: Color.popups.border
  border.width: Math.max(1, Style.space(1))

  Text {
    id: chipLabel
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: (root.service ? (root.service.currency || "USD") : "USD") + " \uf0a0a"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (!root.service) return;
      root.service.cycleCurrency(mouse.button === Qt.RightButton ? -1 : 1);
    }
  }
}
```

---

## 12. `components/markets/PairEditor.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/NumberFormat.js" as Num
import "../../logic/ConverterModel.js" as CM

ColumnLayout {
  id: root
  property var service: null
  property string mode: "fiat"           // fiat | crypto | units
  property string fromValue: ""
  property string toValue: ""
  property string lastEdited: "top"

  spacing: Style.space(6)
  Layout.fillWidth: true

  // ... (detalhes de options, dropdown, swap, edges iguais ao Converter original;
  //      trocar o glyph ⇅ por \uf0a0a (nf-md-swap-horizontal))

  TextField { id: topField; /* ... */ }
  // Row com réguas + botão swap
  TextField { id: bottomField; /* ... */ }

  // Footer com status
  Text {
    textFormat: Text.PlainText
    text: root.mode === "units"
      ? "Units are computed locally · no network needed"
      : (root.service ? root.service.converterStatus(root.mode) : "")
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    Layout.fillWidth: true
  }
}
```

**Nota:** a implementação completa deste componente é análoga ao `PairEditor.qml` do omarchy-converter. Reaproveite a lógica (bidirecional, numpad, swap) e ajuste os glyphs.

---

## 13. `components/markets/UnitCategoryPicker.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/ConverterModel.js" as CM

RowLayout {
  id: root
  property string category: "length"
  signal categorySelected(string c)

  spacing: Style.space(4)
  Layout.fillWidth: true

  Repeater {
    model: Object.keys(CM.UNIT_CATEGORIES)
    delegate: Chip {
      required property string modelData
      label: CM.UNIT_CATEGORIES[modelData].label
      active: root.category === modelData
      onClicked: root.categorySelected(modelData)
    }
  }
}
```

---

## 14. `components/markets/SymbolSearch.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var service: null
  signal close()

  spacing: Style.space(6)
  Layout.fillWidth: true

  RowLayout {
    spacing: Style.space(6)
    Layout.fillWidth: true

    FlowInput {
      id: input
      placeholder: "Add symbol... (AAPL, BTC, ETH)"
      Layout.fillWidth: true
      onAccepted: root.performSearch(input.text)
    }
    FlowIconButton { glyph: "×"; onClicked: root.close() }
  }

  ListView {
    model: root.results
    spacing: Style.space(3)
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(Style.space(150), contentHeight)

    delegate: RowLayout {
      required property var modelData
      spacing: Style.space(8)
      Layout.fillWidth: true

      Text {
        textFormat: Text.PlainText
        text: modelData.symbol
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        Layout.preferredWidth: Style.space(70)
      }
      Text {
        textFormat: Text.PlainText
        text: modelData.name || ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
      Text {
        textFormat: Text.PlainText
        text: modelData.exchange || ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.service) root.service.watchlistAdd(modelData.symbol);
          root.close();
        }
      }
    }
  }

  property var results: []

  function performSearch(q) {
    // Chama service.searchSymbols(q) que faz fetch Yahoo + CoinGecko,
    // merge dedup, e popula root.results.
  }
}
```

---

## 15. `logic/MarketsModel.js` — o núcleo

Adapte o `Model.js` do omarchy-markets. Funções necessárias:

```js
.pragma library

// ---- Quote parsing ----
function parseChartResponse(line) { /* ... */ }
function parseQuoteLines(text, symbols) { /* ... */ }

// ---- Crypto detection ----
function isCryptoSymbol(symbol) { /* ... */ }
function displaySymbol(symbol) { /* ... */ }
function normalizeSymbol(input) { /* ... */ }

// ---- Market session ----
function marketStatus(quote, nowMs) { /* ... */ }
function marketStatusLabel(status) { /* ... */ }

// ---- Formatting ----
function formatPrice(price) { /* ... */ }
function formatPercent(pct) { /* ... */ }
function formatChange(quote) { /* ... */ }
function formatVolume(v) { /* ... */ }
function formatMarketCap(v) { /* ... */ }
function formatSupply(v, symbol) { /* ... */ }

// ---- Watchlist ----
function defaultWatchlist() { return { symbols: ["AAPL", "NVDA", "BTC"] }; }
function addSymbol(watchlist, symbol) { /* ... */ }
function removeSymbol(watchlist, symbol) { /* ... */ }
function moveSymbol(watchlist, fromIndex, toIndex) { /* ... */ }

// ---- Staleness ----
function ageMs(lastUpdatedMs, nowMs) { /* ... */ }
function ageLabel(lastUpdatedMs, nowMs) { /* ... */ }
function isStale(lastUpdatedMs, refreshMin, nowMs) { /* ... */ }

// ---- CoinGecko ----
function coingeckoMarketsUrl(ids) { /* ... */ }
function parseCoinMarkets(text) { /* ... */ }
function enrichQuotes(quotes, coinData) { /* ... */ }
function cryptoIdsFromQuotes(quotes) { /* ... */ }

// ---- Binance ----
function binancePairFor(symbol) { /* ... */ }
function binanceTickerUrl(pair) { /* ... */ }
function binanceTradeUrlFor(symbol) { /* ... */ }
function parseBinanceTicker(line) { /* ... */ }
function parseBinanceLines(text, pairs) { /* ... */ }
function enrichQuotesBinance(quotes, binanceData) { /* ... */ }

// ---- Yahoo search ----
function yahooSearchUrl(query) { /* ... */ }
function parseYahooSearch(text) { /* ... */ }

if (typeof module !== "undefined") {
  module.exports = { /* ... */ };
}
```

**Nota:** copie as funções essenciais do omarchy-markets/Model.js. Mantenha ES5, sem imports QML, com `module.exports` no final.

---

## 16. `logic/ConverterModel.js` — conversão

Adapte o `Model.js` do omarchy-converter. Funções necessárias:

```js
.pragma library

var UNIT_CATEGORIES = { /* length, mass, temperature, volume, area, speed, time, data */ };

var CRYPTO_LIST = [ /* 15 majors */ ];

var MAJOR_CURRENCIES = [ /* ... */ ];
var CURRENCY_NAMES = { /* ... */ };

function convertUnit(value, category, from, to) { /* ... */ }
function toUsd(value, key, rates, cryptoPrices) { /* ... */ }
function fromUsd(usd, key, rates, cryptoPrices) { /* ... */ }
function convertCross(value, from, to, rates, cryptoPrices) { /* ... */ }

if (typeof module !== "undefined") {
  module.exports = { /* ... */ };
}
```

---

## 17. `logic/NumberFormat.js` — parse e format

```js
.pragma library

function parseAmount(text) {
  var raw = String(text === undefined || text === null ? "" : text).trim();
  if (raw === "") return NaN;
  raw = raw.replace(/[\s_'’]/g, "");
  var hasDot = raw.indexOf(".") !== -1;
  var firstComma = raw.indexOf(",");
  if (firstComma !== -1 && !hasDot && raw.indexOf(",", firstComma + 1) === -1) {
    raw = raw.slice(0, firstComma) + "." + raw.slice(firstComma + 1);
  } else {
    raw = raw.split(",").join("");
  }
  var value = Number(raw);
  return isFinite(value) ? value : NaN;
}

function formatResult(value) {
  if (typeof value !== "number" || !isFinite(value)) return "—";
  var abs = Math.abs(value);
  if (abs !== 0 && (abs >= 1e12 || abs < 1e-6)) return value.toExponential(4);
  var digits = abs >= 1000 ? 2 : abs >= 1 ? 4 : 6;
  var s = value.toFixed(digits);
  if (s.indexOf(".") !== -1) s = s.replace(/0+$/, "").replace(/\.$/, "");
  return s;
}

if (typeof module !== "undefined") {
  module.exports = { parseAmount: parseAmount, formatResult: formatResult };
}
```

---

## 18. `services/MarketsService.qml`

```qml
Item {
  id: root
  property var service: null

  property var quotes: []
  property var series: ({})        // { "SYMBOL|range": [...] }
  property double lastFetch: 0
  property var watchlist: ({ symbols: ["AAPL", "NVDA", "BTC"] })

  // ---- Fetch de quotes ----
  Process {
    id: quoteProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: quoteProc.output = text
    }
    onExited: function(code) {
      if (code !== 0) return;
      var parsed = MarketsModel.parseQuoteLines(quoteProc.output, root.watchlist.symbols);
      // Enriquecer com Binance (crypto) e CoinGecko (metadata)
      root.quotes = parsed;
      root.lastFetch = Date.now();
      if (root.service) root.service.bump();
    }
  }

  function refresh() {
    if (root.watchlist.symbols.length === 0) return;
    quoteProc.command = MarketsModel.curlCommand(root.watchlist.symbols, "kairos/1.0", "1d");
    quoteProc.running = true;
  }

  // ---- Fetch de série para o chart ----
  Process {
    id: seriesProc
    property string output: ""
    property string key: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: seriesProc.output = text
    }
    onExited: function(code) {
      if (code !== 0) return;
      var parsed = MarketsModel.parseSeriesLines(seriesProc.output, [seriesProc.key.split("|")[0]], seriesProc.key.split("|")[1]);
      var next = {};
      for (var k in root.series) next[k] = root.series[k];
      for (var sym in parsed) next[sym + "|" + seriesProc.key.split("|")[1]] = parsed[sym];
      root.series = next;
      if (root.service) root.service.bump();
    }
  }

  function fetchSeries(symbol, range) {
    var key = symbol + "|" + range;
    if (root.series[key]) return;
    seriesProc.key = key;
    seriesProc.command = MarketsModel.curlCommand([symbol], "kairos/1.0", range);
    seriesProc.running = true;
  }

  // ---- Refresh periódico ----
  Timer {
    interval: 5 * 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
```

---

## 19. `services/ConverterService.qml`

```qml
Item {
  id: root
  property var service: null

  property var currencyRates: ({})
  property var cryptoPrices: ({})
  property double ratesFetchedAt: 0
  property double cryptoFetchedAt: 0

  readonly property string ratesScript: localPath(Qt.resolvedUrl("../scripts/fetch-rates"))
  readonly property string cryptoScript: localPath(Qt.resolvedUrl("../scripts/fetch-crypto"))

  function localPath(url) {
    var v = String(url || "");
    if (v.indexOf("file://") === 0) v = v.substring(7);
    try { return decodeURIComponent(v); } catch (e) { return v; }
  }

  Process {
    id: ratesProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyRates(text)
    }
  }

  Process {
    id: cryptoProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyCrypto(text)
    }
  }

  function refresh(force) {
    ratesProc.command = force ? [root.ratesScript, "USD", "--force"] : [root.ratesScript, "USD"];
    ratesProc.running = true;
    cryptoProc.command = force ? [root.cryptoScript, "bitcoin,ethereum,solana", "--force"]
                               : [root.cryptoScript, "bitcoin,ethereum,solana"];
    cryptoProc.running = true;
  }

  function applyRates(raw) {
    try {
      var data = JSON.parse(String(raw || ""));
      if (data && data.ok && data.rates) {
        root.currencyRates = data.rates;
        root.ratesFetchedAt = Number(data.fetched_at || 0);
        if (root.service) root.service.bump();
      }
    } catch (e) {}
  }

  function applyCrypto(raw) {
    try {
      var data = JSON.parse(String(raw || ""));
      if (data && data.ok && data.prices) {
        root.cryptoPrices = data.prices;
        root.cryptoFetchedAt = Number(data.fetched_at || 0);
        if (root.service) root.service.bump();
      }
    } catch (e) {}
  }

  Timer {
    interval: 5 * 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh(false)
  }
}
```

---

## 20. `scripts/fetch-rates` e `scripts/fetch-crypto`

Adapte os scripts do omarchy-converter:

- **`fetch-rates`**: fetch de `https://open.er-api.com/v6/latest/USD`, cache em `~/.cache/omarchy/kairos/markets/rates-USD.json` (TTL 6h).
- **`fetch-crypto`**: fetch de `https://api.coingecko.com/api/v3/simple/price`, cache em `~/.cache/omarchy/kairos/markets/crypto.json` (TTL 10min).

Ambos com **hardening**:
- Owner check.
- Chain-of-custody do cache.
- Acesso via `/proc/self/fd`.
- Escrita via `rename(2)`.
- Caps de schema (300 fiat, 50 crypto).
- Timeout 5-10s.

Marcar como executáveis (`chmod +x`).

---

## 21. Métodos agregados no `Service.qml` (Markets + Converter)

```qml
  // ============================ Markets ============================

  MarketsService { id: marketsService; service: root }
  ConverterService { id: converterService; service: root }

  readonly property var quotes: marketsService.quotes
  readonly property var watchlist: marketsService.watchlist

  function marketsRefresh() { marketsService.refresh(); }
  function marketsFetchSeries(symbol, range) { marketsService.fetchSeries(symbol, range); }
  function marketsSeries(symbol, range) {
    return marketsService.series[symbol + "|" + range] || [];
  }
  function marketsAgeLabel() {
    if (!marketsService.lastFetch) return "never";
    return MarketsModel.ageLabel(marketsService.lastFetch, Date.now());
  }
  function quoteFor(symbol) {
    for (var i = 0; i < marketsService.quotes.length; i++)
      if (marketsService.quotes[i].symbol === symbol) return marketsService.quotes[i];
    return null;
  }
  function binanceTradeUrl(symbol) { return MarketsModel.binanceTradeUrlFor(symbol); }
  function watchlistAdd(symbol) {
    var wl = MarketsModel.addSymbol(marketsService.watchlist, symbol);
    marketsService.watchlist = wl;
    marketsService.refresh();
    root.bump();
  }
  function watchlistRemove(symbol) {
    var wl = MarketsModel.removeSymbol(marketsService.watchlist, symbol);
    marketsService.watchlist = wl;
    marketsService.refresh();
    root.bump();
  }
  function cycleCurrency(step) {
    var ring = root.settings.markets.currencies || ["USD", "EUR", "BRL"];
    var cur = root.settings.markets.currency || "USD";
    var idx = ring.indexOf(cur);
    if (idx === -1) idx = 0;
    root.settings.markets.currency = ring[((idx + step) % ring.length + ring.length) % ring.length];
    root.bump();
    root.saveSoon();
  }

  // ============================ Converter ============================

  function converterStatus(mode) {
    if (mode === "units") return "Units are computed locally · no network needed";
    if (mode === "crypto") {
      var age = MarketsModel.ageLabel(converterService.cryptoFetchedAt, Date.now());
      return "Crypto " + age;
    }
    var age2 = MarketsModel.ageLabel(converterService.ratesFetchedAt, Date.now());
    return "Fiat rates " + age2;
  }

  function convertCurrency(amount, from, to) {
    return ConverterModel.convertCross(amount, from, to,
      converterService.currencyRates, converterService.cryptoPrices);
  }

  function convertUnit(amount, category, from, to) {
    return ConverterModel.convertUnit(amount, category, from, to);
  }
```

---

## 22. Integração no `Panel.qml`

Substituir os placeholders:

```qml
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "stats"

          Flickable {
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: statsView.implicitHeight
            interactive: contentHeight > height

            StatsView {
              id: statsView
              width: parent.width
              service: root.service
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "markets"

          MarketsView {
            anchors.fill: parent
            service: root.service
          }
        }
```

---

## 23. Testes automatizados

Criar `tests/markets-model.test.js`:

- `isCryptoSymbol("BTC")` retorna true; `isCryptoSymbol("AAPL")` retorna false.
- `displaySymbol("BTC-USD")` retorna `"BTC"`.
- `displaySymbol("BTC-EUR")` retorna `"BTC/EUR"`.
- `formatPrice(104250)` retorna `"104,250.00"`.
- `marketStatus` retorna `"open"` dentro do horário, `"closed"` fora.
- `addSymbol` deduplica símbolos normalizados.
- `binancePairFor("BTC-USD")` retorna `"BTCUSDT"`.
- `binanceTradeUrlFor("BTC-USD")` monta a URL correta.
- `ageLabel` retorna `"just now"` para timestamps recentes.
- `isStale` retorna true quando age > 2 × refresh.

Criar `tests/converter-model.test.js`:

- `convertUnit(100, "length", "m", "ft")` ≈ 328.084.
- `convertUnit(0, "temperature", "C", "F")` = 32.
- `convertCross(100, "USD", "EUR", rates, prices)` funciona.
- `parseAmount("1.234,56")` retorna 1234.56.
- `formatResult(1234.567)` retorna `"1,234.57"` (ou equivalente).

---

## ✅ CHECKPOINT DA PARTE 5

Ao final desta parte, verificar:

- [ ] Aba **Stats** mostra grid TODAY com 6 células.
- [ ] Barras da semana proporcionais ao `focusSec` de cada dia.
- [ ] Heatmap renderiza 7 × 12 células com 5 níveis de cor.
- [ ] Filtros de history funcionam (`Today/Yesterday/All`, `Both/Pomo/Flow`).
- [ ] Lista de history mostra dot colorido + tipo + duração + horário.
- [ ] Aba **Markets** abre com 4 sub-tabs.
- [ ] **Watchlist** mostra quotes com preço, variação, cor correta.
- [ ] Símbolos crypto mostram `nf-md-weather-night` quando mercado fechado.
- [ ] Clicar num símbolo seleciona; chart renderiza.
- [ ] Range selector troca a série.
- [ ] KeyStats mostra valores corretos (stock vs crypto).
- [ ] `Add symbol` busca Yahoo + CoinGecko, adiciona à watchlist.
- [ ] CurrencyChip cicla moedas.
- [ ] **Convert** (fiat) bidirecional funciona.
- [ ] **Crypto** bidirecional funciona.
- [ ] **Units** troca categoria e converte.
- [ ] `node --test tests/` passa para `markets-model` e `converter-model`.
- [ ] `omarchy plugin validate` sai com exit 0.
- [ ] `qmllint` sai com exit 0 nos arquivos novos.
- [ ] Sem erros no console após 5 min.

# PARTE 6 — ABA SOCIAL + EMAIL + SETTINGS + VALIDAÇÃO + ZIP

> **INSTRUÇÕES PARA A IA:** Este é o **sexto e último** prompt da série. Você já tem fundação (Parte 1), barra + painel (Parte 2), aba Day + Obsidian + khal (Parte 3), abas Focus + Plan (Parte 4) e abas Stats + Markets (Parte 5). Agora implementa a **aba Social** (redes sociais + email), a **aba Settings** completa, e faz a **validação final + entrega do ZIP**. Ao final, o plugin estará 100% pronto.

---

## 1. Escopo da Parte 6

Ao final desta parte, você deve ter:

1. **`views/SocialView.qml`** — aba Social completa (unread, calls, ringing, conversation, email).
2. **`components/social/AccountTabs.qml`** — chips por conta (redes + emails).
3. **`components/social/UnreadList.qml`** — caixa de entrada unificada.
4. **`components/social/CallList.qml`** — missed/incoming/outgoing.
5. **`components/social/RingingBanner.qml`** — "Now ringing" com Answer/Decline.
6. **`components/social/Conversation.qml`** — thread + composer.
7. **`components/social/EmailComposer.qml`** — reply/reply-all/forward.
8. **`services/SocialService.qml`** — orquestra conectores, D-Bus de chamadas.
9. **`services/EmailService.qml`** — IMAP IDLE + SMTP.
10. **`connectors/`** — Telegram, WhatsApp, Signal, Discord, Matrix, Email.
11. **`views/SettingsView.qml`** — todas as 12 seções.
12. **`logic/SocialModel.js`** — modelo unificado + merge.
13. **`logic/EmailModel.js`** — parse de mensagens, subject/body, attachments.
14. **`scripts/obsidian-write`** e **`scripts/email-fetch`** — helpers shell.
15. **`README.md`** — documentação completa em inglês.
16. **Validação oficial** — `omarchy plugin validate` + `qmllint`.
17. **`io.github.yks777.kairos.zip`** — pacote final com estrutura correta.

---

# PARTE A — ABA SOCIAL

## 2. Layout da aba Social

### 2.1. Vista geral

```
┌───────────────────────────────────────────────────────────────────────┐
│ KAIROS   Stay Hard                                        ⚙    ×      │
├───────────────────────────────────────────────────────────────────────┤
│ [Day] [Focus] [Plan] [Stats] [Markets] [Social]                       │
├───────────────────────────────────────────────────────────────────────┤
│ [ All ] [ Telegram ] [ WhatsApp ] [ Signal ] [ Gmail ] [ Work ]       │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  UNREAD (12)                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ ● Alice (Telegram)      Oi, tudo bem?                  2m       │  │
│  │ ● Ana Silva (Gmail)     Re: Quarterly report           8m       │  │
│  │ ● Família (WhatsApp)    [photo]                        15m      │  │
│  │ ● Dev Team (Signal)     deploy is green                1h       │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  RECENT CALLS                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ ⚠ Missed · João (WhatsApp)                        14:32          │  │
│  │ ⚠ Missed · Maria (Telegram)                       11:05          │  │
│  │ ↗ Outgoing · Pedro (Signal)                       09:18          │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  NOW RINGING                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ 📞 Alice (Telegram)                                             │  │
│  │                      [ Answer ]   [ Decline ]                   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

### 2.2. Estrutura vertical

1. **AccountTabs** — chips `[ All ]` + uma por conta configurada (redes + emails).
2. **UNREAD** — lista de conversas com mensagens/emails não lidos.
3. **RECENT CALLS** — chamadas das últimas 24h (missed, incoming, outgoing).
4. **NOW RINGING** — banner condicional quando há chamada ativa.
5. **Conversation** — thread quando um item é clicado (substitui as seções acima).

---

## 3. `views/SocialView.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components/social"

ColumnLayout {
  id: root
  property var service: null

  property string activeAccount: "all"
  property var openThread: null        // { accountId, chatId, platform, name }

  spacing: Style.space(10)
  Layout.fillWidth: true

  readonly property var accounts: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.socialAccounts();
  }

  readonly property var unreadItems: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.socialUnread(root.activeAccount);
  }

  readonly property var recentCalls: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.socialRecentCalls(root.activeAccount);
  }

  readonly property var ringing: {
    if (!root.service) return null;
    void root.service.tickVersion;
    return root.service.socialRinging();
  }

  // ---- Modo thread (substitui a lista) ----
  Conversation {
    visible: root.openThread !== null
    thread: root.openThread
    service: root.service
    onClose: root.openThread = null
    Layout.fillWidth: true
    Layout.fillHeight: true
  }

  // ---- Modo lista ----
  ColumnLayout {
    visible: root.openThread === null
    spacing: Style.space(10)
    Layout.fillWidth: true
    Layout.fillHeight: true

    AccountTabs {
      accounts: root.accounts
      activeId: root.activeAccount
      onAccountSelected: function(id) { root.activeAccount = id; }
      Layout.fillWidth: true
    }

    // ---- UNREAD ----
    Text {
      textFormat: Text.PlainText
      text: "UNREAD (" + root.unreadItems.length + ")"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
      Layout.fillWidth: true
    }

    UnreadList {
      items: root.unreadItems
      service: root.service
      onItemSelected: function(item) { root.openThread = item; }
      Layout.fillWidth: true
      Layout.fillHeight: true
    }

    // ---- RECENT CALLS ----
    Text {
      visible: root.recentCalls.length > 0
      textFormat: Text.PlainText
      text: "RECENT CALLS"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
      Layout.fillWidth: true
    }

    CallList {
      visible: root.recentCalls.length > 0
      calls: root.recentCalls
      Layout.fillWidth: true
    }

    // ---- NOW RINGING ----
    RingingBanner {
      visible: root.ringing !== null
      call: root.ringing
      service: root.service
      Layout.fillWidth: true
    }
  }
}
```

---

## 4. `components/social/AccountTabs.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property var accounts: []        // [{ id, name, glyph, platform }]
  property string activeId: "all"
  signal accountSelected(string id)

  spacing: Style.space(4)
  Layout.fillWidth: true

  // Chip "All" sempre primeiro
  Chip {
    label: "All"
    active: root.activeId === "all"
    onClicked: root.accountSelected("all")
  }

  Repeater {
    model: root.accounts
    delegate: Chip {
      required property var modelData
      label: modelData.glyph + " " + modelData.name
      active: root.activeId === modelData.id
      onClicked: root.accountSelected(modelData.id)
    }
  }
}
```

---

## 5. `components/social/UnreadList.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ListView {
  id: root
  property var items: []
  property var service: null
  signal itemSelected(var item)

  model: root.items
  spacing: Style.space(3)
  clip: true
  Layout.fillWidth: true

  delegate: Rectangle {
    required property var modelData
    width: root.width
    implicitHeight: row.implicitHeight + Style.space(12)
    radius: Style.cornerRadius
    color: hover.containsMouse ? Util.alpha(Color.muted, 0.08) : "transparent"

    RowLayout {
      id: row
      anchors.fill: parent
      anchors.margins: Style.space(6)
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(8)
        height: width
        radius: width / 2
        color: modelData.unread > 0 ? Color.accent : Color.muted
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        textFormat: Text.PlainText
        text: modelData.name + " (" + modelData.accountName + ")"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        Layout.preferredWidth: Style.space(180)
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        text: modelData.preview || ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        textFormat: Text.PlainText
        text: modelData.timeLabel || ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    MouseArea {
      id: hover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.itemSelected(modelData)
    }
  }

  Text {
    anchors.centerIn: parent
    visible: root.items.length === 0
    textFormat: Text.PlainText
    text: "No unread messages."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.italic: true
  }
}
```

---

## 6. `components/social/CallList.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var calls: []

  spacing: Style.space(3)
  Layout.fillWidth: true

  Repeater {
    model: root.calls
    delegate: RowLayout {
      required property var modelData
      spacing: Style.space(8)
      Layout.fillWidth: true

      Text {
        textFormat: Text.PlainText
        text: modelData.glyph
        color: modelData.kind === "missed" ? Color.urgent
             : (modelData.kind === "outgoing" ? Color.accent : Color.muted)
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        textFormat: Text.PlainText
        text: modelData.name + " (" + modelData.accountName + ")"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        text: modelData.timeLabel || ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }
}
```

---

## 7. `components/social/RingingBanner.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root
  property var call: null
  property var service: null

  implicitHeight: banner.implicitHeight + Style.space(16)
  radius: Style.cornerRadius
  color: Util.alpha(Color.accent, 0.15)
  border.color: Color.accent
  border.width: Math.max(1, Style.space(1))

  ColumnLayout {
    id: banner
    anchors.fill: parent
    anchors.margins: Style.space(8)
    spacing: Style.space(8)

    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true

      Text {
        textFormat: Text.PlainText
        text: "\uf0c39"     // nf-md-phone
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.title
      }

      Text {
        textFormat: Text.PlainText
        text: root.call ? (root.call.name + " (" + root.call.accountName + ")") : ""
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        Layout.fillWidth: true
      }
    }

    RowLayout {
      spacing: Style.space(8)
      Layout.alignment: Qt.AlignHCenter

      FlowButton {
        text: "Answer"
        primary: true
        onClicked: if (root.service) root.service.socialAnswerCall(root.call);
      }
      FlowButton {
        text: "Decline"
        onClicked: if (root.service) root.service.socialDeclineCall(root.call);
      }
    }
  }
}
```

**Nota:** Kairos não faz VoIP. `Answer` abre o app nativo da rede.

---

## 8. `components/social/Conversation.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var thread: null          // { accountId, chatId, platform, name }
  property var service: null
  signal close()

  spacing: Style.space(8)
  Layout.fillWidth: true
  Layout.fillHeight: true

  readonly property var messages: {
    if (!root.service || !root.thread) return [];
    void root.service.revision;
    return root.service.socialThread(root.thread.accountId, root.thread.chatId);
  }

  // ---- Header ----
  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: root.thread
        ? (root.thread.platform.toUpperCase() + " · " + root.thread.name)
        : ""
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
      Layout.fillWidth: true
    }

    FlowIconButton {
      glyph: "×"
      onClicked: root.close()
    }
  }

  Rectangle {
    height: Math.max(1, Style.space(1))
    color: Color.popups.border
    opacity: 0.5
    Layout.fillWidth: true
  }

  // ---- Messages ----
  ListView {
    id: list
    model: root.messages
    spacing: Style.space(6)
    clip: true
    Layout.fillWidth: true
    Layout.fillHeight: true

    delegate: ColumnLayout {
      required property var modelData
      spacing: Style.space(2)
      Layout.fillWidth: true

      Text {
        textFormat: Text.PlainText
        text: modelData.sender + ":"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        textFormat: Text.PlainText
        text: modelData.body
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
      Text {
        textFormat: Text.PlainText
        text: modelData.timeLabel
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  // ---- Composer ----
  RowLayout {
    spacing: Style.space(6)
    Layout.fillWidth: true

    FlowInput {
      id: composer
      placeholder: "Type a message..."
      Layout.fillWidth: true
      onAccepted: root.send()
    }

    FlowIconButton {
      glyph: "\uf0e2a"     // nf-md-paperclip
      onClicked: root.attachFile()
    }

    FlowButton {
      text: "Send"
      primary: true
      onClicked: root.send()
    }
  }

  function send() {
    if (!root.service || !root.thread || composer.text.trim() === "") return;
    root.service.socialSend(root.thread.accountId, root.thread.chatId, composer.text);
    composer.text = "";
  }

  function attachFile() {
    // Implementação futura: abre file picker e envia como anexo.
  }
}
```

---

## 9. `components/social/EmailComposer.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var service: null
  property var account: null         // { id, name, email }
  property string mode: "new"        // new | reply | replyAll | forward
  property string originalId: ""
  property string to: ""
  property string subject: ""
  property string body: ""

  signal close()

  spacing: Style.space(6)
  Layout.fillWidth: true

  Text {
    textFormat: Text.PlainText
    text: root.mode === "new" ? "NEW EMAIL"
        : root.mode === "reply" ? "REPLY"
        : root.mode === "replyAll" ? "REPLY ALL"
        : "FORWARD"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
  }

  FlowInput {
    text: root.to
    placeholder: "To..."
    Layout.fillWidth: true
    onTextChanged: root.to = text
  }

  FlowInput {
    text: root.subject
    placeholder: "Subject..."
    Layout.fillWidth: true
    onTextChanged: root.subject = text
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.space(120)
    radius: Style.cornerRadius
    color: "transparent"
    border.color: Color.popups.border
    border.width: Math.max(1, Style.space(1))

    TextEdit {
      id: bodyEdit
      anchors.fill: parent
      anchors.margins: Style.space(8)
      text: root.body
      color: Color.popups.text
      selectionColor: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: TextEdit.Wrap
      onTextChanged: root.body = text
    }
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignRight

    FlowButton {
      text: "Cancel"
      onClicked: root.close()
    }
    FlowButton {
      text: "Send"
      primary: true
      onClicked: root.send()
    }
  }

  function send() {
    if (!root.service || !root.account) return;
    root.service.emailSend(root.account.id, root.to, root.subject, root.body);
    root.close();
  }
}
```

---

## 10. `logic/SocialModel.js`

```js
.pragma library

// Modelo unificado para todas as redes + email.
// Todo evento vira:
// {
//   platform: "telegram" | "whatsapp" | "signal" | "discord" | "matrix" | "email",
//   kind: "message" | "call" | "missed_call",
//   accountId: "gmail-work",
//   chat: { id, name, unread },
//   sender: { id, name, email },
//   subject: "...",
//   body: "text",
//   timestamp: 1760000000000,
//   callState: "ringing" | "missed" | "ended",
//   hasAttachments: false,
//   canReply: true
// }

function mergeEvents(sources, now) {
  // sources: array de arrays de eventos
  // Retorna lista unificada, ordenada por timestamp desc, dedup por id.
  var out = [];
  var seen = {};
  for (var i = 0; i < sources.length; i++) {
    var list = sources[i] || [];
    for (var j = 0; j < list.length; j++) {
      var ev = list[j];
      if (!ev || !ev.id) continue;
      var key = ev.platform + "|" + ev.accountId + "|" + ev.id;
      if (seen[key]) continue;
      seen[key] = true;
      out.push(ev);
    }
  }
  out.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0); });
  return out;
}

function unreadCount(events) {
  var n = 0;
  for (var i = 0; i < events.length; i++)
    if (events[i].chat && events[i].chat.unread > 0) n += events[i].chat.unread;
  return n;
}

function recentCalls(events, now) {
  now = now || Date.now();
  var cutoff = now - 24 * 3600000;
  var out = [];
  for (var i = 0; i < events.length; i++) {
    var ev = events[i];
    if (ev.kind === "call" || ev.kind === "missed_call") {
      if ((ev.timestamp || 0) >= cutoff) out.push(ev);
    }
  }
  out.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0); });
  return out;
}

function ringingCall(events) {
  for (var i = 0; i < events.length; i++) {
    if (events[i].callState === "ringing") return events[i];
  }
  return null;
}

function timeLabel(ts, now) {
  now = now || Date.now();
  var diff = Math.max(0, now - ts);
  var min = Math.floor(diff / 60000);
  if (min < 1) return "now";
  if (min < 60) return min + "m";
  var h = Math.floor(min / 60);
  if (h < 24) return h + "h";
  return Math.floor(h / 24) + "d";
}

function accountGlyph(platform) {
  // Retorna glyph Nerd Font por plataforma.
  switch (platform) {
    case "telegram": return "\uf2c6";
    case "whatsapp": return "\uf40c";
    case "signal":   return "\uf441";
    case "discord":  return "\uf2c6";
    case "matrix":   return "\uf491";
    case "email":    return "\uf01f6";   // nf-md-email
    default:         return "\uf02d8";   // nf-md-account
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    mergeEvents: mergeEvents,
    unreadCount: unreadCount,
    recentCalls: recentCalls,
    ringingCall: ringingCall,
    timeLabel: timeLabel,
    accountGlyph: accountGlyph
  };
}
```

---

## 11. `logic/EmailModel.js`

```js
.pragma library

function formatAddress(addr) {
  if (!addr) return "";
  if (typeof addr === "string") return addr;
  return addr.name && addr.name !== addr.email
    ? addr.name + " <" + addr.email + ">"
    : addr.email;
}

function formatDate(ts) {
  var d = new Date(ts);
  return d.toLocaleString();
}

function parseImapMessage(raw) {
  // Parse básico de uma mensagem IMAP: headers + body.
  // Retorna { id, from, to, subject, body, timestamp, hasAttachments }
  var out = {
    id: "",
    from: "",
    to: "",
    subject: "",
    body: "",
    timestamp: 0,
    hasAttachments: false
  };
  // ... parse de headers (From, To, Subject, Date), body plain text
  return out;
}

function sanitizeBody(text) {
  // Remove HTML se presente, converte entidades, normaliza newlines.
  return String(text || "").replace(/\r\n?/g, "\n").trim();
}

if (typeof module !== "undefined") {
  module.exports = {
    formatAddress: formatAddress,
    formatDate: formatDate,
    parseImapMessage: parseImapMessage,
    sanitizeBody: sanitizeBody
  };
}
```

---

## 12. `services/SocialService.qml`

```qml
Item {
  id: root
  property var service: null

  property var events: []
  property var connectors: []

  function reload() {
    var all = [];
    for (var i = 0; i < root.connectors.length; i++) {
      var c = root.connectors[i];
      if (c && c.available && c.events) all.push(c.events);
    }
    root.events = SocialModel.mergeEvents(all, Date.now());
    if (root.service) root.service.bump();
  }

  // D-Bus listener para chamadas
  // Nota: implementação via Process escutando `dbus-monitor`.

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.reload()
  }
}
```

---

## 13. `services/EmailService.qml`

```qml
Item {
  id: root
  property var service: null

  property var accounts: []          // do settings.email.accounts
  property var messages: ({})        // { "<accountId>": [{...}, ...] }

  // Para cada conta configurada, abre uma conexão IMAP IDLE via script
  // `email-fetch` e alimenta `messages`.

  Process {
    id: fetchProc
    property string accountId: ""
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: fetchProc.output = text
    }
    onExited: function(code) {
      if (code !== 0) return;
      var parsed = EmailModel.parseMessages(fetchProc.output);
      var next = {};
      for (var k in root.messages) next[k] = root.messages[k];
      next[fetchProc.accountId] = parsed;
      root.messages = next;
      if (root.service) root.service.bump();
    }
  }

  function fetchAccount(accountId) {
    var acc = root.accountById(accountId);
    if (!acc) return;
    fetchProc.accountId = accountId;
    fetchProc.command = ["bash", "-c",
      "script_path=\"$(dirname \"$0\")/../scripts/email-fetch\"; " +
      "exec \"$script_path\" \"$1\" \"$2\" \"$3\" \"$4\"",
      "", acc.imapHost, String(acc.imapPort), acc.username, acc.password];
    fetchProc.running = true;
  }

  function accountById(id) {
    for (var i = 0; i < root.accounts.length; i++)
      if (root.accounts[i].id === id) return root.accounts[i];
    return null;
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      for (var i = 0; i < root.accounts.length; i++)
        root.fetchAccount(root.accounts[i].id);
    }
  }
}
```

---

## 14. `connectors/` — os 6 conectores

Cada conector é um `Item` que:

1. Detecta se o binário está instalado (`available`).
2. Faz fetch periódico (`events`).
3. Expõe interface unificada.

### 14.1. `connectors/TelegramConnector.qml`

```qml
Item {
  id: root
  property var service: null
  property bool available: false
  property var events: []

  Process {
    id: checkProc
    command: ["sh", "-c", "command -v tdlib-json-cli >/dev/null 2>&1"]
    onExited: function(code) { root.available = (code === 0); }
  }

  Timer {
    interval: 60000
    running: root.available
    repeat: true
    triggeredOnStart: true
    onTriggered: root.fetch()
  }

  function fetch() {
    // Executa tdlib-json-cli, parse JSON, normaliza para o modelo unificado.
  }

  Component.onCompleted: checkProc.running = true
}
```

### 14.2. `connectors/WhatsAppConnector.qml`, `SignalConnector.qml`, `DiscordConnector.qml`, `MatrixConnector.qml`

Mesma estrutura, com binário e lógica específicos.

### 14.3. `connectors/EmailConnector.qml`

Wrapper para `EmailService` — expõe os emails como eventos do modelo unificado.

---

## 15. Métodos agregados no `Service.qml` (Social + Email)

```qml
  // ============================ Social / Email ============================

  SocialService {
    id: socialService
    service: root
  }
  EmailService {
    id: emailService
    service: root
  }

  function socialAccounts() {
    var out = [{ id: "all", name: "All", glyph: "\uf02d8", platform: "all" }];
    // Redes sociais
    var networks = [
      { id: "telegram", name: "Telegram", platform: "telegram", enabled: root.settings.social.telegram },
      { id: "whatsapp", name: "WhatsApp", platform: "whatsapp", enabled: root.settings.social.whatsapp },
      { id: "signal",   name: "Signal",   platform: "signal",   enabled: root.settings.social.signal },
      { id: "discord",  name: "Discord",  platform: "discord",  enabled: root.settings.social.discord },
      { id: "matrix",   name: "Matrix",   platform: "matrix",   enabled: root.settings.social.matrix }
    ];
    for (var i = 0; i < networks.length; i++) {
      if (networks[i].enabled)
        out.push({ id: networks[i].id, name: networks[i].name,
                   glyph: SocialModel.accountGlyph(networks[i].platform),
                   platform: networks[i].platform });
    }
    // Contas de email
    var accounts = root.settings.email.accounts || [];
    for (var j = 0; j < accounts.length; j++) {
      out.push({ id: accounts[j].id, name: accounts[j].name,
                 glyph: SocialModel.accountGlyph("email"), platform: "email" });
    }
    return out;
  }

  function socialUnread(accountId) {
    var events = socialService.events;
    var out = [];
    for (var i = 0; i < events.length; i++) {
      var ev = events[i];
      if (accountId !== "all" && ev.accountId !== accountId) continue;
      if (ev.kind !== "message" && ev.kind !== "email") continue;
      if (!ev.chat || ev.chat.unread === 0) continue;
      out.push({
        accountId: ev.accountId, chatId: ev.chat.id, platform: ev.platform,
        name: ev.chat.name, accountName: ev.platform,
        preview: ev.subject || ev.body || "",
        timeLabel: SocialModel.timeLabel(ev.timestamp),
        unread: ev.chat.unread
      });
    }
    return out;
  }

  function socialRecentCalls(accountId) {
    var calls = SocialModel.recentCalls(socialService.events);
    var out = [];
    for (var i = 0; i < calls.length; i++) {
      var c = calls[i];
      if (accountId !== "all" && c.accountId !== accountId) continue;
      out.push({
        kind: c.callState === "missed" ? "missed"
            : (c.callState === "ringing" ? "incoming" : "outgoing"),
        glyph: c.callState === "missed" ? "\uf0c3b"
             : (c.callState === "ringing" ? "\uf0c3b" : "\uf0c3c"),
        name: c.sender.name,
        accountName: c.platform,
        timeLabel: Qt.formatDateTime(new Date(c.timestamp), "HH:mm")
      });
    }
    return out;
  }

  function socialRinging() {
    var ring = SocialModel.ringingCall(socialService.events);
    if (!ring) return null;
    return { name: ring.sender.name, accountName: ring.platform, id: ring.id };
  }

  function socialThread(accountId, chatId) {
    var events = socialService.events;
    var out = [];
    for (var i = 0; i < events.length; i++) {
      var ev = events[i];
      if (ev.accountId !== accountId) continue;
      if (ev.chat.id !== chatId) continue;
      if (ev.kind !== "message") continue;
      out.push({
        sender: ev.sender.name,
        body: ev.body,
        timeLabel: SocialModel.timeLabel(ev.timestamp)
      });
    }
    return out;
  }

  function socialSend(accountId, chatId, text) {
    // Delega ao conector apropriado.
    // Cada conector expõe um método `send(chatId, text)`.
    root.notify("social", "Sent", "Message sent to " + chatId);
  }

  function socialAnswerCall(call) {
    // Abre o app nativo da rede.
    var url = "";
    if (call.accountName === "telegram") url = "tg://";
    else if (call.accountName === "whatsapp") url = "whatsapp://";
    else if (call.accountName === "signal") url = "sgnl://";
    if (url !== "") Quickshell.execDetached(["xdg-open", url]);
  }

  function socialDeclineCall(call) {
    // Apenas notifica; o app nativo decide.
  }

  // ---- Email ----
  function emailSend(accountId, to, subject, body) {
    // Chama scripts/email-fetch em modo send.
    root.notify("social", "Email sent", subject);
  }

  function emailReply(accountId, messageId, body) {
    // ...
  }
```

---

# PARTE B — SETTINGS

## 16. Layout da aba Settings

Substitui o conteúdo do painel, com botão `‹` de voltar. Scrollável.

Seções:
- **FOCUS**
- **FLOWTIME**
- **CALENDAR**
- **OBSIDIAN**
- **MARKETS**
- **SOCIAL**
- **EMAIL**
- **BAR**
- **STATS**
- **SHORTCUTS**
- **NOTIFICATIONS**
- **DATA**

---

## 17. `views/SettingsView.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var service: null
  signal back()

  property bool confirmingReset: false

  spacing: Style.space(12)
  Layout.fillWidth: true

  // ---- Header ----
  RowLayout {
    spacing: Style.space(10)
    Layout.fillWidth: true

    FlowIconButton {
      glyph: "\uf0141"     // nf-md-chevron-left
      onClicked: root.back()
    }
    Text {
      textFormat: Text.PlainText
      text: "SETTINGS"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 2
      Layout.fillWidth: true
    }
  }

  // ============================ FOCUS ============================
  Section {
    title: "Focus"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      RowLayout {
        spacing: Style.space(8)
        Layout.fillWidth: true
        SettingLabel { text: "Technique" }
        Item { Layout.fillWidth: true }
        Chip { label: "Pomodoro"; active: root.service && root.service.settings.focus.focusAction === "pomodoro"; onClicked: if (root.service) root.service.updateSettings("focus", { focusAction: "pomodoro" }) }
        Chip { label: "Flowtime"; active: root.service && root.service.settings.focus.focusAction === "flowtime"; onClicked: if (root.service) root.service.updateSettings("focus", { focusAction: "flowtime" }) }
      }
      NumberRow { label: "Focus duration"; unit: "min"; value: root.service ? root.service.settings.focus.focusSec / 60 : 25; onCommit: function(v) { if (root.service) root.service.updateSettings("focus", { focusSec: v * 60 }); } }
      NumberRow { label: "Short break"; unit: "min"; value: root.service ? root.service.settings.focus.shortBreakSec / 60 : 5; onCommit: function(v) { if (root.service) root.service.updateSettings("focus", { shortBreakSec: v * 60 }); } }
      NumberRow { label: "Long break"; unit: "min"; value: root.service ? root.service.settings.focus.longBreakSec / 60 : 15; onCommit: function(v) { if (root.service) root.service.updateSettings("focus", { longBreakSec: v * 60 }); } }
      NumberRow { label: "Sessions per long break"; unit: ""; value: root.service ? root.service.settings.focus.longBreakInterval : 4; onCommit: function(v) { if (root.service) root.service.updateSettings("focus", { longBreakInterval: v }); } }
    }
  }

  // ============================ FLOWTIME ============================
  Section {
    title: "Flowtime"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      RowLayout {
        spacing: Style.space(8)
        Layout.fillWidth: true
        SettingLabel { text: "Break mode" }
        Item { Layout.fillWidth: true }
        Chip { label: "Traditional"; active: root.service && root.service.settings.flowtime.flowBreakMode === "traditional"; onClicked: if (root.service) root.service.updateSettings("flowtime", { flowBreakMode: "traditional" }) }
        Chip { label: "Proportional"; active: root.service && root.service.settings.flowtime.flowBreakMode === "proportional"; onClicked: if (root.service) root.service.updateSettings("flowtime", { flowBreakMode: "proportional" }) }
      }
      NumberRow { label: "Break percentage"; unit: "%"; value: root.service ? Math.round(root.service.settings.flowtime.flowBreakPct * 100) : 20; onCommit: function(v) { if (root.service) root.service.updateSettings("flowtime", { flowBreakPct: v / 100 }); } }
      NumberRow { label: "Minimum break"; unit: "min"; value: root.service ? root.service.settings.flowtime.flowBreakMinSec / 60 : 5; onCommit: function(v) { if (root.service) root.service.updateSettings("flowtime", { flowBreakMinSec: v * 60 }); } }
      NumberRow { label: "Maximum break"; unit: "min"; value: root.service ? root.service.settings.flowtime.flowBreakMaxSec / 60 : 15; onCommit: function(v) { if (root.service) root.service.updateSettings("flowtime", { flowBreakMaxSec: v * 60 }); } }
    }
  }

  // ============================ CALENDAR ============================
  Section {
    title: "Calendar"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      ToggleRow { label: "Notifications"; checked: root.service ? root.service.settings.calendar.notifications : true; onToggled: function(v) { if (root.service) root.service.updateSettings("calendar", { notifications: v }); } }
      NumberRow { label: "Lead minutes"; unit: "min"; value: root.service ? root.service.settings.calendar.leadMinutes : 10; onCommit: function(v) { if (root.service) root.service.updateSettings("calendar", { leadMinutes: v }); } }
      NumberRow { label: "Agenda days"; unit: ""; value: root.service ? root.service.settings.calendar.agendaDays : 7; onCommit: function(v) { if (root.service) root.service.updateSettings("calendar", { agendaDays: v }); } }
      RowLayout {
        spacing: Style.space(8)
        Layout.fillWidth: true
        SettingLabel { text: "Time format" }
        Item { Layout.fillWidth: true }
        Chip { label: "khal"; active: root.service && root.service.settings.calendar.timeFormat === "Match khal"; onClicked: if (root.service) root.service.updateSettings("calendar", { timeFormat: "Match khal" }) }
        Chip { label: "12h"; active: root.service && root.service.settings.calendar.timeFormat === "12-hour"; onClicked: if (root.service) root.service.updateSettings("calendar", { timeFormat: "12-hour" }) }
        Chip { label: "24h"; active: root.service && root.service.settings.calendar.timeFormat === "24-hour"; onClicked: if (root.service) root.service.updateSettings("calendar", { timeFormat: "24-hour" }) }
      }
      NumberRow { label: "Sync every"; unit: "min"; value: root.service ? root.service.settings.calendar.syncIntervalMinutes : 15; onCommit: function(v) { if (root.service) root.service.updateSettings("calendar", { syncIntervalMinutes: v }); } }
      TextRow { label: "Sync command"; value: root.service ? root.service.settings.calendar.syncCommand : "vdirsyncer sync"; onCommit: function(v) { if (root.service) root.service.updateSettings("calendar", { syncCommand: v }); } }
    }
  }

  // ============================ OBSIDIAN ============================
  Section {
    title: "Obsidian"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      ToggleRow { label: "Enabled"; checked: root.service ? root.service.settings.obsidian.enabled : false; onToggled: function(v) { if (root.service) root.service.updateSettings("obsidian", { enabled: v }); } }
      PathRow { label: "Diary folder"; mode: "directory"; value: root.service ? root.service.settings.obsidian.diaryPath : ""; onCommit: function(v) { if (root.service) root.service.updateSettings("obsidian", { diaryPath: v }); } }
      TextRow { label: "Vault name (optional)"; value: root.service ? root.service.settings.obsidian.vaultName : ""; onCommit: function(v) { if (root.service) root.service.updateSettings("obsidian", { vaultName: v }); } }
      PathRow { label: "Template path"; value: root.service ? root.service.settings.obsidian.templatePath : ""; onCommit: function(v) { if (root.service) root.service.updateSettings("obsidian", { templatePath: v }); } }
      FlowButton {

      FlowButton {
        text: "Test connection"
        onClicked: if (root.service) root.service.obsidianTestConnection()
      }
    }
  }

  // ============================ MARKETS ============================
  Section {
    title: "Markets"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      ToggleRow { label: "Enabled"; checked: root.service ? root.service.settings.markets.enabled : true; onToggled: function(v) { if (root.service) root.service.updateSettings("markets", { enabled: v }); } }
      NumberRow { label: "Refresh every"; unit: "min"; value: root.service ? root.service.settings.markets.refreshMinutes : 5; onCommit: function(v) { if (root.service) root.service.updateSettings("markets", { refreshMinutes: v }); } }
      TextRow { label: "Default from"; value: root.service ? root.service.settings.markets.defaultCurrencyFrom : "EUR"; onCommit: function(v) { if (root.service) root.service.updateSettings("markets", { defaultCurrencyFrom: v }); } }
      TextRow { label: "Default to"; value: root.service ? root.service.settings.markets.defaultCurrencyTo : "USD"; onCommit: function(v) { if (root.service) root.service.updateSettings("markets", { defaultCurrencyTo: v }); } }
    }
  }

  // ============================ SOCIAL ============================
  Section {
    title: "Social"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      ToggleRow { label: "Telegram"; checked: root.service ? root.service.settings.social.telegram : false; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { telegram: v }); } }
      ToggleRow { label: "WhatsApp"; checked: root.service ? root.service.settings.social.whatsapp : false; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { whatsapp: v }); } }
      ToggleRow { label: "Signal"; checked: root.service ? root.service.settings.social.signal : false; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { signal: v }); } }
      ToggleRow { label: "Discord"; checked: root.service ? root.service.settings.social.discord : false; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { discord: v }); } }
      ToggleRow { label: "Matrix"; checked: root.service ? root.service.settings.social.matrix : false; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { matrix: v }); } }
      ToggleRow { label: "Notify messages"; checked: root.service ? root.service.settings.social.notifyMessages : true; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { notifyMessages: v }); } }
      ToggleRow { label: "Notify calls"; checked: root.service ? root.service.settings.social.notifyCalls : true; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { notifyCalls: v }); } }
      ToggleRow { label: "Show preview"; checked: root.service ? root.service.settings.social.showPreview : false; onToggled: function(v) { if (root.service) root.service.updateSettings("social", { showPreview: v }); } }
    }
  }

  // ============================ EMAIL ============================
  Section {
    title: "Email"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      ToggleRow { label: "Notify new"; checked: root.service ? root.service.settings.email.notifyNew : true; onToggled: function(v) { if (root.service) root.service.updateSettings("email", { notifyNew: v }); } }
      ToggleRow { label: "Show preview"; checked: root.service ? root.service.settings.email.showPreview : false; onToggled: function(v) { if (root.service) root.service.updateSettings("email", { showPreview: v }); } }

      // Lista de contas
      Repeater {
        model: root.service ? root.service.settings.email.accounts : []
        delegate: AccountEditor {
          required property var modelData
          account: modelData
          service: root.service
        }
      }

      FlowButton {
        text: "+ Add account"
        onClicked: if (root.service) root.service.emailAddAccount()
      }
    }
  }

  // ============================ BAR ============================
  Section {
    title: "Bar"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true
      ToggleRow { label: "Show focus timer"; checked: root.service ? root.service.settings.bar.showFocusTimer : true; onToggled: function(v) { if (root.service) root.service.updateSettings("bar", { showFocusTimer: v }); } }
    }
  }

  // ============================ STATS ============================
  Section {
    title: "Stats"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true
      NumberRow { label: "Daily streak minimum"; unit: "min"; value: root.service ? root.service.settings.stats.streakMinSec / 60 : 25; onCommit: function(v) { if (root.service) root.service.updateSettings("stats", { streakMinSec: v * 60 }); } }
    }
  }

  // ============================ SHORTCUTS ============================
  Section {
    title: "Shortcuts"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true
      TextRow { label: "Toggle panel"; value: root.service ? root.service.settings.shortcuts.toggleShortcut : "super+h"; onCommit: function(v) { if (root.service) root.service.updateSettings("shortcuts", { toggleShortcut: v }); } }
      TextRow { label: "Focus timer"; value: root.service ? root.service.settings.shortcuts.focusShortcut : "super+shift+h"; onCommit: function(v) { if (root.service) root.service.updateSettings("shortcuts", { focusShortcut: v }); } }
    }
  }

  // ============================ NOTIFICATIONS ============================
  Section {
    title: "Notifications"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true
      ToggleRow { label: "Enabled"; checked: root.service ? root.service.settings.notifications.enabled : true; onToggled: function(v) { if (root.service) root.service.updateSettings("notifications", { enabled: v }); } }
      ToggleRow { label: "Sound"; checked: root.service ? root.service.settings.notifications.sound : true; onToggled: function(v) { if (root.service) root.service.updateSettings("notifications", { sound: v }); } }
    }
  }

  // ============================ DATA ============================
  Section {
    title: "Data"
    ColumnLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true

      Text {
        textFormat: Text.PlainText
        text: root.service ? ("Stored at " + root.service.stateFilePath) : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: Style.space(8)
        Layout.alignment: Qt.AlignHCenter
        FlowButton { text: "Export"; onClicked: if (root.service) root.service.exportData() }
        FlowButton { text: "Import"; onClicked: if (root.service) root.service.importData() }
        FlowButton {
          text: root.confirmingReset ? "Confirm reset" : "Reset"
          onClicked: {
            if (root.confirmingReset) {
              if (root.service) root.service.resetAll();
              root.confirmingReset = false;
            } else root.confirmingReset = true;
          }
        }
      }
    }
  }

  // ============================ Componentes locais ============================
  component Section: ColumnLayout {
    id: sec
    property string title: ""
    spacing: Style.space(8)
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
    Layout.rightMargin: Style.space(4)
    Text {
      textFormat: Text.PlainText
      text: sec.title.toUpperCase()
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
      Layout.fillWidth: true
    }
    Rectangle {
      height: Math.max(1, Style.space(1))
      color: Color.popups.border
      opacity: 0.5
      Layout.fillWidth: true
    }
  }

  component SettingLabel: Text {
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    Layout.fillWidth: true
  }

  component NumberRow: RowLayout {
    id: num
    property string label: ""
    property string unit: ""
    property real value: 0
    signal commit(real v)
    spacing: Style.space(10)
    Layout.fillWidth: true
    SettingLabel { text: num.label }
    Text {
      textFormat: Text.PlainText
      text: num.unit
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      visible: num.unit !== ""
    }
    FlowInput {
      id: numInput
      numbersOnly: true
      text: String(Math.round(num.value))
      implicitWidth: Style.space(72)
      Layout.preferredWidth: Style.space(72)
      onAccepted: {
        var v = parseInt(numInput.text, 10);
        if (!isNaN(v) && v >= 0) num.commit(v);
        else numInput.text = String(Math.round(num.value));
      }
      onCancelled: numInput.text = String(Math.round(num.value))
    }
  }

  component ToggleRow: RowLayout {
    id: tog
    property string label: ""
    property bool checked: false
    signal toggled(bool v)
    spacing: Style.space(10)
    Layout.fillWidth: true
    SettingLabel { text: tog.label }
    Item { Layout.fillWidth: true }
    Rectangle {
      width: Style.space(44)
      height: Style.space(24)
      radius: height / 2
      color: "transparent"
      border.color: tog.checked ? Color.accent : Color.popups.border
      border.width: Math.max(1, Style.space(1))
      Rectangle {
        width: Style.space(16)
        height: Style.space(16)
        radius: width / 2
        color: tog.checked ? Color.accent : Color.muted
        anchors.verticalCenter: parent.verticalCenter
        x: tog.checked ? parent.width - width - Style.space(4) : Style.space(4)
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tog.toggled(!tog.checked)
      }
    }
  }

  component TextRow: RowLayout {
    id: row
    property string label: ""
    property string value: ""
    signal commit(string v)
    spacing: Style.space(10)
    Layout.fillWidth: true
    SettingLabel { text: row.label }
    FlowInput {
      id: input
      text: row.value
      Layout.fillWidth: true
      onAccepted: row.commit(input.text)
    }
  }

  component PathRow: RowLayout {
    id: pathRow
    property string label: ""
    property string value: ""
    signal commit(string v)
    spacing: Style.space(10)
    Layout.fillWidth: true
    SettingLabel { text: pathRow.label }
    FlowInput {
      id: input
      text: pathRow.value
      Layout.fillWidth: true
      onAccepted: pathRow.commit(input.text)
    }
    FlowIconButton {
      glyph: "…"
      onClicked: {
        // Abre file picker
        if (root.service) root.service.pickFile(function(p) {
          input.text = p;
          pathRow.commit(p);
        });
      }
    }
  }

  component AccountEditor: ColumnLayout {
    id: acc
    property var account: null
    property var service: null
    spacing: Style.space(6)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: acc.account ? acc.account.name : ""
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      Layout.fillWidth: true
    }

    TextRow {
      label: "Email"
      value: acc.account ? acc.account.email : ""
      onCommit: function(v) { if (acc.service) acc.service.emailUpdateAccount(acc.account.id, { email: v }); }
    }
    TextRow {
      label: "IMAP host"
      value: acc.account ? acc.account.imapHost : ""
      onCommit: function(v) { if (acc.service) acc.service.emailUpdateAccount(acc.account.id, { imapHost: v }); }
    }
    TextRow {
      label: "SMTP host"
      value: acc.account ? acc.account.smtpHost : ""
      onCommit: function(v) { if (acc.service) acc.service.emailUpdateAccount(acc.account.id, { smtpHost: v }); }
    }
    TextRow {
      label: "Username"
      value: acc.account ? acc.account.username : ""
      onCommit: function(v) { if (acc.service) acc.service.emailUpdateAccount(acc.account.id, { username: v }); }
    }

    FlowButton {
      text: "Remove account"
      onClicked: if (acc.service) acc.service.emailRemoveAccount(acc.account.id)
    }
  }
}
```

---

## 18. Métodos de Settings no `Service.qml`

```qml
  // ============================ Settings ============================

  function updateSettings(section, patch) {
    var next = {};
    for (var k in root.settings) next[k] = root.settings[k];
    var target = {};
    for (var s in next[section]) target[s] = next[section][s];
    for (var p in patch) target[p] = patch[p];
    next[section] = Model.sanitizeSettingsSection(section, target);
    root.settings = next;
    if (section === "shortcuts") root.applyShortcuts();
    root.bump();
    root.saveSoon();
  }

  // ---- Obsidian test connection ----
  function obsidianTestConnection() {
    // Valida diaryPath, templatePath, escrita.
    // Mostra resultado via toast.
    root.notify("obsidian", "Test connection",
      "Diary folder OK. Write access OK.");
  }

  // ---- File picker ----
  function pickFile(callback) {
    // Chama `omarchy file select`, captura stdout, invoca callback(path).
  }

  // ---- Email accounts ----
  function emailAddAccount() {
    var accounts = (root.settings.email.accounts || []).slice();
    accounts.push({
      id: Model.uid("email"),
      name: "New account",
      email: "",
      imapHost: "imap.example.com",
      imapPort: 993,
      smtpHost: "smtp.example.com",
      smtpPort: 587,
      username: "",
      password: "",
      useTLS: true
    });
    root.updateSettings("email", { accounts: accounts });
  }

  function emailUpdateAccount(id, patch) {
    var accounts = (root.settings.email.accounts || []).map(function(a) {
      if (a.id !== id) return a;
      var c = {};
      for (var k in a) c[k] = a[k];
      for (var p in patch) c[p] = patch[p];
      return c;
    });
    root.updateSettings("email", { accounts: accounts });
  }

  function emailRemoveAccount(id) {
    var accounts = (root.settings.email.accounts || []).filter(function(a) { return a.id !== id; });
    root.updateSettings("email", { accounts: accounts });
  }
```

---

## 19. Integração no `Panel.qml`

Substituir os placeholders finais:

```qml
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "social"

          SocialView {
            anchors.fill: parent
            service: root.service
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "settings"

          Flickable {
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: settingsView.implicitHeight
            interactive: contentHeight > height

            SettingsView {
              id: settingsView
              width: parent.width
              service: root.service
              onBack: root.currentView = root.returnView
            }
          }
        }
```

---

## 20. IPC final no `Service.qml`

```qml
  IpcHandler {
    target: "io.github.yks777.kairos"

    // ... IPC existente ...

    function social(): string {
      // Abre a aba Social
      root.openView("social");
      return "ok";
    }
    function emailAccounts(): string {
      return JSON.stringify(root.settings.email.accounts || []);
    }
    function emailInbox(accountId: string): string {
      var msgs = emailService.messages[accountId] || [];
      return JSON.stringify(msgs.slice(0, 20));
    }
    function emailSend(accountId: string, to: string, subject: string, body: string): string {
      root.emailSend(accountId, to, subject, body);
      return "ok";
    }
  }
```

---

# PARTE C — DOCUMENTAÇÃO E ENTREGA

## 21. `scripts/obsidian-write`

```bash
#!/usr/bin/env bash
# Atomic write helper for Obsidian notes.
# Usage: obsidian-write <path> <content-file>
set -euo pipefail

[[ -O $0 ]] || exit 1
mode=$(stat -c '%a' "$0" 2>/dev/null) || exit 1
if ((( 8#$mode & 8#022 ) != 0)); then exit 1; fi

path="$1"
content_file="$2"

dir=$(dirname "$path")
mkdir -p "$dir"

tmp=$(mktemp "$dir/.kairos-write.XXXXXX")
trap 'rm -f "$tmp"' EXIT

cat "$content_file" > "$tmp"
mv -f "$tmp" "$path"
```

Marcar como executável (`chmod +x`).

---

## 22. `scripts/email-fetch`

```bash
#!/usr/bin/env bash
# Fetch emails via IMAP for a given account.
# Usage: email-fetch <imapHost> <imapPort> <username> <password>
# Emits JSON: [{ id, from, to, subject, body, timestamp, hasAttachments }]
set -euo pipefail

[[ -O $0 ]] || exit 1

imap_host="$1"
imap_port="$2"
username="$3"
password="$4"

# Implementação: usa python3 com imaplib.
python3 - "$imap_host" "$imap_port" "$username" "$password" <<'PY'
import imaplib, json, sys, email
from email.header import decode_header

host, port, user, pwd = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]

try:
    m = imaplib.IMAP4_SSL(host, port)
    m.login(user, pwd)
    m.select("INBOX")
    status, data = m.search(None, "ALL")
    out = []
    for num in data[0].split()[-20:]:
        status, msg_data = m.fetch(num, "(RFC822)")
        raw = msg_data[0][1]
        msg = email.message_from_bytes(raw)
        out.append({
            "id": msg.get("Message-ID", ""),
            "from": msg.get("From", ""),
            "to": msg.get("To", ""),
            "subject": msg.get("Subject", ""),
            "body": "",
            "timestamp": 0,
            "hasAttachments": False
        })
    m.logout()
    print(json.dumps(out))
except Exception as e:
    print(json.dumps([]))
    sys.exit(1)
PY
```

Marcar como executável.

---

## 23. `README.md` — em inglês

Estrutura:

```markdown
# Kairos

![Kairos preview](docs/preview.png)

A single plugin for the Omarchy bar that unifies clock, focus timer, Eisenhower
matrix, calendar (khal), Obsidian daily notes, statistics, markets, social
networks, and email under one surface.

## Features

- **Bar:** clock + conditional focus timer.
- **Day tab:** month calendar, khal events, Obsidian tasks.
- **Focus tab:** Pomodoro and Flowtime timers.
- **Plan tab:** Eisenhower matrix with drag-and-drop.
- **Stats tab:** today grid, week bars, focus heatmap, session history.
- **Markets tab:** watchlist, chart, fiat/crypto/units converter.
- **Social tab:** Telegram, WhatsApp, Signal, Discord, Matrix, email.
- **Settings:** 12 sections covering everything.

## Install

### Via Git

    omarchy plugin add https://github.com/yks777/Kairos.git --enable

### Via ZIP

    unzip io.github.yks777.kairos.zip -d /tmp/kairos-install
    mv /tmp/kairos-install/io.github.yks777.kairos \
       ~/.config/omarchy/plugins/io.github.yks777.kairos
    omarchy plugin validate ~/.config/omarchy/plugins/io.github.yks777.kairos
    omarchy-shell shell rescanPlugins
    omarchy plugin enable io.github.yks777.kairos --section center
    omarchy restart shell

## Uninstall

    omarchy plugin disable io.github.yks777.kairos
    omarchy plugin remove io.github.yks777.kairos
    omarchy restart shell

## Usage

| Action | Result |
|---|---|
| Left click clock | Open panel on Day |
| Right click clock | Cycle label format |
| Middle click clock | Timezone picker |
| Left click timer | Open panel on Focus |
| Middle click timer | Pause / Resume |
| Right click timer | Stop |

## Settings

[full table of every section]

## Obsidian setup

1. Open Settings → Obsidian.
2. Set `diaryPath` to your diary folder's absolute path (e.g. `/home/yks/Obsidian/Meu-segundo-cerebro/0. YKS/Diario`).
3. (Optional) Set `vaultName` if your Obsidian vault name differs from the vault directory name.
4. (Optional) Set `templatePath` to a static template.
5. Click Test connection.

## khal setup

[step by step]

## Social setup

[per network]

## Email setup

[step by step]

## Dependencies

- Required: QtQuick, Quickshell, qs.Commons.
- Optional: khal, vdirsyncer, tdlib-json-cli, wa-cli, signal-cli, mautrix-python.
- Optional: `curl`, `jq`, `python3`.

## Security

[notes about shell scripts, links, credentials]

## License

MIT
```

---

## 24. Validação oficial

Executar:

```bash
PLUGIN_DIR="$HOME/.config/omarchy/plugins/io.github.yks777.kairos"

omarchy plugin validate "$PLUGIN_DIR"

qmllint -I "$OMARCHY_PATH/shell" \
  "$PLUGIN_DIR/BarWidget.qml" \
  "$PLUGIN_DIR/Panel.qml" \
  "$PLUGIN_DIR/Service.qml"

node --test tests/
```

Todos devem sair com exit 0.

---

## 25. Geração do ZIP

```bash
cd "$PLUGIN_DIR/.."
zip -r io.github.yks777.kairos.zip io.github.yks777.kairos/ \
  -x "*.DS_Store" -x "__MACOSX*" -x "*.git*" -x "*.log" -x "node_modules/*"

unzip -l io.github.yks777.kairos.zip | head -50
```

O listing deve mostrar exatamente uma pasta de topo `io.github.yks777.kairos/` com `manifest.json` dentro.

---

## ✅ CHECKPOINT FINAL — PARTE 6

Ao final desta parte, verificar:

### Aba Social
- [ ] AccountTabs mostra `[ All ]` + chips por rede ativa + chips por email.
- [ ] UNREAD lista conversas com preview e timestamp.
- [ ] RECENT CALLS mostra missed/outgoing/incoming com glyph correto.
- [ ] NOW RINGING aparece quando há chamada ativa com `[ Answer ]`/`[ Decline ]`.
- [ ] Clicar num item abre a thread.
- [ ] Composer envia mensagens (delega ao conector).
- [ ] Estado vazio explicativo para redes sem binário.

### Email
- [ ] Adicionar conta em Settings → Email funciona.
- [ ] `kairos email.inbox <accountId>` retorna mensagens.
- [ ] `kairos email.send` envia via SMTP.
- [ ] EmailComposer funciona para reply/reply-all/forward.

### Settings
- [ ] Todas as 12 seções renderizam.
- [ ] Cada campo grava via `updateSettings`.
- [ ] `Test connection` do Obsidian valida e mostra resultado.
- [ ] `+ Add account` de email adiciona nova entrada.
- [ ] Path inputs têm botão `…` que abre file picker.

### Documentação
- [ ] `README.md` completo em inglês.
- [ ] `CHANGELOG.md` atualizado com versão 1.0.0.
- [ ] `.Agents.md` documenta ritual de teste.

### Validação
- [ ] `omarchy plugin validate` sai com exit 0.
- [ ] `qmllint` sai com exit 0 em todos os entry points.
- [ ] `node --test tests/` passa em todos os arquivos de teste.
- [ ] `omarchy-shell shell summon io.github.yks777.kairos '{}'` abre o painel.
- [ ] `omarchy-shell shell hide io.github.yks777.kairos` fecha o painel.
- [ ] `omarchy-shell omarchy.clock refresh` responde.

### Aceitação final
- [ ] Barra mostra só relógio quando idle, relógio + timer quando ativo.
- [ ] Todas as 6 abas funcionam.
- [ ] Dia do calendário abre Obsidian (cria se não existir).
- [ ] Notas criadas têm o template exato.
- [ ] Tasks do Obsidian carregam e persistem.
- [ ] Focus inicia/para Pomodoro e Flowtime.
- [ ] Plan drag-and-drop funciona.
- [ ] Stats mostra grid + bars + heatmap.
- [ ] Markets tem 4 sub-abas.
- [ ] Social lista mensagens, chamadas e email.
- [ ] Zero emoji (só Nerd Font glyphs).
- [ ] Zero strings em português fora de conteúdo do usuário.
- [ ] Zero APIs pagas.
- [ ] Sem erros no console após 5 min.

### Entrega
- [ ] `io.github.yks777.kairos.zip` gerado.
- [ ] ZIP contém só `io.github.yks777.kairos/` no topo.
- [ ] Sem symlinks no ZIP.
- [ ] Scripts em `scripts/` com permissão `+x`.
- [ ] Manifest dentro da pasta, não na raiz do ZIP.

---

## 26. Considerações finais

**Ao concluir todas as 6 partes:**

O plugin **Kairos** está completo. Ele:

1. Substitui o relógio stock do Omarchy.
2. Mostra um timer condicional na barra.
3. Tem 6 abas funcionais + Settings.
4. Integra Obsidian, khal, Yahoo/Binance/CoinGecko, IMAP/SMTP e 5 redes sociais.
5. É 100% em inglês.
6. É 100% gratuito.
7. Usa apenas Nerd Font glyphs (zero emoji).
8. Passa em `omarchy plugin validate` e `qmllint`.
9. Tem cobertura de testes para toda a lógica pura.
10. É entregue como `io.github.yks777.kairos.zip` com estrutura correta.

**Filosofia final:** o Kairos é a resposta ao *momento oportuno*. Ele sabe a hora, sabe o que fazer, ajuda a focar, e mostra o que o mundo está fazendo enquanto você foca. E ele nunca duplica fontes de verdade — o Obsidian continua sendo o Obsidian, o khal continua sendo o khal, e o Kairos é apenas a superfície de ação.

**Entrega:** `io.github.yks777.kairos.zip`.

**Fim da série de 6 prompts.**

---

## ✅ SÉRIE COMPLETA

Você recebeu as 6 partes:

1. **Parte 1** — Fundação (missão, regras, referências, design system, arquitetura, manifest).
2. **Parte 2** — Bar widget + estrutura do painel.
3. **Parte 3** — Aba Day + Obsidian + khal.
4. **Parte 4** — Abas Focus e Plan.
5. **Parte 5** — Abas Stats e Markets.
6. **Parte 6** — Aba Social + Email + Settings + Validação + ZIP.

# Prompt de Auditoria Completa — Verificação do Plugin Kairos

> **Nota para você (usuário):** este prompt é para ser entregue à mesma IA que construiu o plugin. Ela vai fazer uma auditoria completa, adicionar o que faltar, e responder **"Tudo Pronto"** apenas se absolutamente tudo estiver conforme. Cole o bloco abaixo inteiro.

---

## PROMPT

You are performing a **complete audit** of the Kairos plugin for the Omarchy bar. Your job is to verify, item by item, whether the plugin matches the full specification that was given to you across the 6-part build series. **If anything is missing, incomplete, or incorrect, you must add or fix it.** If everything is present and correct, you must reply with exactly the following text and nothing else:

```
Tudo Pronto
```

Do not skip checks. Do not assume a file is correct without opening it. Do not mark something as done if it exists as an empty stub.

---

## 1. How to perform the audit

For every item below:

1. **Check if the file / feature exists.**
2. **If it does not exist** → create it fully, following the original spec.
3. **If it exists but is incomplete** → complete it fully.
4. **If it exists and is complete** → verify its correctness (imports, bindings, signals, no syntax errors, no emoji, no Portuguese strings, no hardcoded colors, no paid APIs, no symlinks).
5. **Never delete working code.** Add or fix, do not regress.

After every file you create or modify:

- Re-run the validation commands listed in section 12.
- Fix any error before continuing.

At the end, if and only if every single item in sections 2 through 11 passes, reply with `Tudo Pronto`.

---

## 2. File inventory — every file must exist

Verify these files exist at the plugin root (`~/.config/omarchy/plugins/io.github.yks777.kairos/`):

```
manifest.json
README.md
CHANGELOG.md
LICENSE
.Agents.md
BarWidget.qml
Service.qml
Panel.qml

services/CalendarService.qml
services/MarketsService.qml
services/ConverterService.qml
services/SocialService.qml
services/EmailService.qml
services/ObsidianService.qml

connectors/TelegramConnector.qml
connectors/WhatsAppConnector.qml
connectors/SignalConnector.qml
connectors/DiscordConnector.qml
connectors/MatrixConnector.qml
connectors/EmailConnector.qml

components/Chip.qml
components/FlowButton.qml
components/FlowIconButton.qml
components/FlowInput.qml
components/Header.qml
components/NavigationTabs.qml
components/Section.qml

views/DayView.qml
views/FocusView.qml
views/PomodoroView.qml
views/FlowtimeView.qml
views/PlanView.qml
views/StatsView.qml
views/MarketsView.qml
views/SocialView.qml
views/SettingsView.qml

components/day/MonthGrid.qml
components/day/DayEvents.qml
components/day/DayTasks.qml
components/day/EventCard.qml

components/plan/MatrixColumn.qml
components/plan/MatrixToolbar.qml
components/plan/TaskCard.qml
components/plan/TaskEditor.qml
components/plan/CompletedPopup.qml

components/markets/Watchlist.qml
components/markets/Chart.qml
components/markets/RangeSelector.qml
components/markets/KeyStats.qml
components/markets/CurrencyChip.qml
components/markets/SymbolSearch.qml
components/markets/PairEditor.qml
components/markets/UnitCategoryPicker.qml

components/social/AccountTabs.qml
components/social/UnreadList.qml
components/social/CallList.qml
components/social/RingingBanner.qml
components/social/Conversation.qml
components/social/EmailComposer.qml

logic/Model.js
logic/TimerEngine.js
logic/StatsEngine.js
logic/Storage.js
logic/ClockModel.js
logic/CalendarModel.js
logic/MarketsModel.js
logic/ConverterModel.js
logic/SocialModel.js
logic/EmailModel.js
logic/ObsidianModel.js
logic/NumberFormat.js

scripts/fetch-rates       (must have +x permission)
scripts/fetch-crypto      (must have +x permission)
scripts/obsidian-write    (must have +x permission)
scripts/email-fetch       (must have +x permission)

tests/model.test.js
tests/timer-engine.test.js
tests/stats-engine.test.js
tests/calendar-model.test.js
tests/markets-model.test.js
tests/converter-model.test.js
tests/social-model.test.js
tests/email-model.test.js
tests/obsidian-model.test.js
```

**If any file is missing → create it fully.**

---

## 3. Manifest check

Open `manifest.json` and verify:

- `schemaVersion: 1`
- `id: "io.github.yks777.kairos"`
- `name: "Kairos"`
- `version: "1.0.0"`
- `license: "MIT"`
- `kinds: ["service", "bar-widget", "panel"]`
- `keepLoaded: true`
- `entryPoints: { service: "Service.qml", barWidget: "BarWidget.qml", panel: "Panel.qml" }`
- `omarchy.clonedFrom: "omarchy.clock"` (present during development)
- `barWidget.displayName: "Kairos"`
- `barWidget.defaultSection: "center"`
- `barWidget.allowMultiple: false`

**If anything is wrong → fix it.**

---

## 4. Bar widget check

Open `BarWidget.qml` and verify:

- Module name is `"io.github.yks777.kairos"`.
- Contains a `SystemClock` (1-minute precision) or equivalent for the clock.
- Clock text uses `Qt.formatDateTime` with `format` / `formatAlt` / `verticalFormat` from `setting()`.
- `ww` token is substituted with the ISO week before formatting.
- Clock left click → opens panel on Day tab.
- Clock right click → cycles format and persists to `shell.json` via `shell.updateEntryInline`.
- Clock middle click → runs `omarchy-menu-timezone`.
- Timer segment is **conditional**: only visible when `timer.phase` is `running`, `paused`, or `break`.
- Timer glyph uses Nerd Font (no emoji).
- Timer text is `MM:SS` under one hour, `HH:MM:SS` at or above one hour, `SS` under one minute.
- Timer left click → opens panel on Focus tab.
- Timer middle click → pause/resume.
- Timer right click → stop.
- Vertical bar: clock uses `verticalFormat`, timer below in `MM\nSS`.
- **No `Loader` for `Panel.qml`.** The shell's panel-loader handles the panel; `BarWidget.qml` must NOT embed it.
- Runtime contract present: `open()`, `close()`, `toggle()`, `opened`, `popoutSwitchClosing`, `closeForPopoutSwitch()`.

**If anything is missing or wrong → fix it.**

---

## 5. Panel check

Open `Panel.qml` and verify:

- Module name `"io.github.yks777.kairos"`.
- `manageIpc: false`.
- Injected properties: `shell`, `manifest`, `service`, `omarchyPath`, `anchorItem`, `hostWidget`.
- `barShim` QtObject for the case where a live `bar` is not injected.
- `KeyboardPanel` centered with `centerOnBar: true`, internal `anchorItem`, `barShim`, reactive `gap`, manual `contentHeight`.
- `PanelKeyCatcher` with `onCloseRequested` and `onTabRequested`.
- Header shows `KAIROS` + board title + gear + close.
- NavigationTabs with 6 tabs: Day, Focus, Plan, Stats, Markets, Social.
- Settings is triggered by the gear, not a tab.
- All 6 views are wired (not empty placeholders).
- SettingsView is wired with `onBack`.
- `open(payloadJson)` switches view correctly.
- Card width and content height vary per view (Day: 560/620, Focus: 400/460, Plan: 880/500, Stats: 480/540, Markets: 640/520, Social: 620/620, Settings: 460/560).

**If any view is still a placeholder → implement it.**

---

## 6. Per-tab functional check

### 6.1. Day tab (`views/DayView.qml`)
- Renders month grid with 6 fixed weeks.
- Colored dots under days with events.
- Today highlighted in accent.
- Selected day has accent border + tint.
- Left click on a day:
  - Selects the day.
  - If Obsidian is enabled:
    - Note exists → opens via `obsidian://open?vault=<vault>&file=<path>`.
    - Note missing → creates with exact template, then opens.
    - Failure → toast in `Color.urgent`.
- **No footer, no "Open" button, no visible path.**
- Events list from khal with time range, title, meeting service.
- Clicking an event expands: Join, Directions, description, organizer, RSVP.
- Tasks list from Obsidian with Nerd Font checkboxes.
- Clicking a checkbox flips `[ ]` ↔ `[x]` in the `.md` atomically.
- `+ Add` inserts `- [ ] New task` in the first section with tasks.
- Navigation: `‹` `›` months, `{` `}` years, `Today`, `W`.

### 6.2. Focus tab
- TECHNIQUE heading + two chips `Pomodoro` / `Flowtime`.
- Chip active state reflects `settings.focus.focusAction`.
- Clicking a chip calls `updateFocusAction`.
- Counter displayed in `Style.font.displayLarge`, color varies by state.
- State line: `FOCUS · Session 2 of 4` or `FLOWTIME · N interruptions · Suggested break: Xm`.
- Working on line with `[ Change ]` picker (two sections: Obsidian + Matrix).
- Buttons per state (Stopped / Running / Paused / Break / Flowtime running / Flowtime paused).
- Today's sessions list.
- Timer segment appears in the bar when active.

### 6.3. Plan tab
- Toolbar with `MATRIX` + `[ Completed (n) ]`.
- Four quadrants Q1–Q4 with correct titles and subtitles.
- TaskCard with priority dot, title, duration, active indicator.
- Hover reveals Focus / Done / Edit / Delete.
- Focus starts timer with `focusAction`.
- Done hides from quadrant.
- Edit inline rename.
- Delete confirms first.
- Drag-and-drop between quadrants with ghost pixmap.
- `+ Add task` inline composer.
- Completed popup with search + Restore + Delete.

### 6.4. Stats tab
- TODAY grid (3×2): Focus, Pomodoro, Flowtime, Tasks done, Interruptions, Streak.
- `Tasks done` reads from Obsidian `[x]` count (fallback: matrix completed).
- THIS WEEK 7 bars.
- FOCUS HEATMAP (7 × N) with 5 color levels.
- HISTORY filters: `[Today] [Yesterday] [All]`, `[Both] [Pomo] [Flow]`.
- History list with dot, type + duration, time.

### 6.5. Markets tab
- Four sub-tabs: Watchlist, Convert, Crypto, Units.
- **Watchlist:** quotes with drag handle, symbol, name, price, change. Weather-night glyph for closed markets. Stale dimming. Chart with range selector. KeyStats (stock vs crypto). Currency chip. Open on Binance. Remove.
- **Convert:** bidirectional PairEditor with swap glyph.
- **Crypto:** same, picker accepts crypto and fiat.
- **Units:** category picker + bidirectional editor.

### 6.6. Social tab
- AccountTabs with `[ All ]` + one chip per active network + one per email account.
- UNREAD list with preview and timestamp.
- RECENT CALLS with missed / outgoing / incoming glyphs.
- NOW RINGING banner with `[ Answer ]` / `[ Decline ]` when a call is active.
- Clicking an item opens the Conversation.
- Conversation with messages + composer.
- EmailComposer for reply / reply-all / forward.
- Empty state for networks without their binary installed.

**If any tab is incomplete → implement the missing parts.**

---

## 7. Integration check

### 7.1. Obsidian
- `ObsidianService` resolves paths, reads, writes, creates notes.
- Template used is **exactly**:
  ```
  ---
  data e hora: YYYY-MM-DD HH:mm
  tags:
    - Diario
  ---
  -
  ```
- `data e hora:` is filled with the local `YYYY-MM-DD HH:mm` at creation.
- Task regex: `^(\s*)- \[([ xX])\] (.+)$`, code blocks ignored.
- Toggle preserves indentation and text.
- Add inserts after the last task of the first section with tasks.
- `FileView.watchChanges: true` on the current day's file.
- `obsidian://` URI used to open notes, `xdg-open` as fallback.

### 7.2. khal
- `khal printformats` run at startup, parsed, regex built.
- Parser round-trips its own sample correctly, otherwise `error` is set.
- Periodic fetch every aligned minute with `--day-format "" today Nd`.
- Month fetch on navigation with `<start> 48d`, cached per `YYYY-MM`.
- Sync every `syncIntervalMinutes` with `syncCommand`, 5-min watchdog.
- Notifications with `leadMinutes`, never all-day, never repeated.
- `notified.json` persists across restarts.

### 7.3. Markets APIs
- Yahoo Finance quotes via `curl`.
- Binance spot ticker for crypto.
- CoinGecko for metadata and market cap.
- open.er-api.com for fiat rates.
- All keyless.
- All caches in `~/.cache/omarchy/kairos/markets/`.

### 7.4. Social connectors
- Each connector checks if its binary is installed.
- Each exposes `available`, `events` with the unified model.
- Disabled networks show an explanatory empty state.

### 7.5. Email
- IMAP for reading (IDLE or polling).
- SMTP for sending.
- Multiple accounts supported.
- Each account becomes a chip.
- Credentials in `state.json` (documented).

**If any integration is missing → implement it.**

---

## 8. Settings check

Open `views/SettingsView.qml` and verify all 12 sections exist with all their keys wired:

1. **Focus:** focusAction, focusSec, shortBreakSec, longBreakSec, longBreakInterval.
2. **Flowtime:** flowBreakMode, flowBreakPct, flowBreakMinSec, flowBreakMaxSec.
3. **Calendar:** notifications, leadMinutes, agendaDays, timeFormat, mapsProvider, syncIntervalMinutes, syncCommand.
4. **Obsidian:** enabled, diaryPath, vaultName, templatePath, Test connection button.
5. **Markets:** enabled, refreshMinutes, currency, currencies, upColor, downColor, defaultCurrencyFrom, defaultCurrencyTo, cryptoIds.
6. **Social:** telegram, whatsapp, signal, discord, matrix, notifyMessages, notifyCalls, showPreview.
7. **Email:** accounts (add / edit / remove), notifyNew, showPreview.
8. **Bar:** showFocusTimer.
9. **Stats:** streakMinSec.
10. **Shortcuts:** toggleShortcut, focusShortcut.
11. **Notifications:** enabled, sound.
12. **Data:** state path, Export, Import, Reset.

All path fields have a `…` button that opens `omarchy file select`.

**If any section or key is missing → add it.**

---

## 9. Logic layer check

Verify each file under `logic/`:

- `Model.js` — defaults, sanitizeState, sanitizeSettings, migrate, blankState, blankTimer, format helpers.
- `TimerEngine.js` — pomodoroRemainingMs, flowElapsedMs, suggestedBreakSec.
- `StatsEngine.js` — filterSessions, summarize, tasksDoneOnDay, streak, lastWeek, **heatmap**.
- `Storage.js` — dataDir, statePath.
- `ClockModel.js` — formats, nextFormat, isoWeek, substituteIsoWeek.
- `CalendarModel.js` — parseFormats, parseEvents, parseIcsDetails, meetingService, dueNotifications, pruneNotified, agendaRows, ICS_LOOKUP_SCRIPT.
- `MarketsModel.js` — quote parsing, Binance, CoinGecko, watchlist, market session, staleness, formatPrice/Volume/MarketCap/Supply, ageLabel, isStale.
- `ConverterModel.js` — UNIT_CATEGORIES, CRYPTO_LIST, convertUnit, convertCross.
- `SocialModel.js` — mergeEvents, unreadCount, recentCalls, ringingCall, timeLabel, accountGlyph.
- `EmailModel.js` — formatAddress, formatDate, parseImapMessage, sanitizeBody.
- `ObsidianModel.js` — resolveDailyNotePath, renderTemplate, parseTasks, toggleTask, addTask, formatDateTime, obsidianUri.
- `NumberFormat.js` — parseAmount, formatResult.

All end with `module.exports` and start with `.pragma library`.

**If any function is missing → add it.**

---

## 10. Test coverage check

Run `node --test tests/`. Verify that at least these are covered:

- `model.test.js` — sanitization, migration, blank state.
- `timer-engine.test.js` — remaining, elapsed, suggested break.
- `stats-engine.test.js` — filter, summarize, streak, lastWeek, heatmap.
- `calendar-model.test.js` — formats, events, ICS, notifications.
- `markets-model.test.js` — crypto detection, display symbol, price format, market status, watchlist, binance pair.
- `converter-model.test.js` — unit conversion, temperature, cross currency, parseAmount.
- `social-model.test.js` — merge, unread, calls, ringing.
- `email-model.test.js` — address format, date format, body sanitization.
- `obsidian-model.test.js` — path resolution, template render, parse tasks, toggle, add.

**If a test file is missing → create it. If a test file has fewer than 5 asserts → expand it.**

---

## 11. Scripts and security check

For each of `scripts/fetch-rates`, `scripts/fetch-crypto`, `scripts/obsidian-write`, `scripts/email-fetch`:

- File exists.
- Executable (`chmod +x`).
- Starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Owner check (`[[ -O $0 ]]`).
- Refuses to run if group/other-writable.
- Uses absolute paths for external binaries where possible.
- Writes via `.tmp` + `rename(2)` (atomic).
- No `eval` on user input.
- No hardcoded credentials.

**If any script is missing or unsafe → fix it.**

---

## 12. Validation commands

Run all of the following and require exit 0:

```bash
PLUGIN_DIR="$HOME/.config/omarchy/plugins/io.github.yks777.kairos"

# 1. Manifest validation
omarchy plugin validate "$PLUGIN_DIR"

# 2. QML linting on entry points
qmllint -I "$OMARCHY_PATH/shell" \
  "$PLUGIN_DIR/BarWidget.qml" \
  "$PLUGIN_DIR/Panel.qml" \
  "$PLUGIN_DIR/Service.qml"

# 3. Logic tests
cd "$PLUGIN_DIR" && node --test tests/

# 4. No symlinks anywhere in the plugin
find "$PLUGIN_DIR" -type l -print

# 5. No emoji in any .qml, .js, .md, .json
grep -rP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' "$PLUGIN_DIR" \
  --include='*.qml' --include='*.js' --include='*.md' --include='*.json' \
  && echo "EMOJI FOUND" || echo "No emoji"

# 6. No Portuguese strings outside user content
grep -rP '\b(não|você|também|está|já|até|então|porque|enquanto|sobre|isso|aquilo)\b' \
  "$PLUGIN_DIR" --include='*.qml' --include='*.js' --include='*.md' \
  && echo "PORTUGUESE FOUND" || echo "No Portuguese"

# 7. No paid API hosts
grep -rE 'openai\.com|anthropic\.com|api\.stripe\.com|cloud\.google\.com' "$PLUGIN_DIR" \
  && echo "PAID API FOUND" || echo "No paid APIs"
```

If any of these fails, fix the issue and re-run until all pass.

---

## 13. Runtime sanity check

With the shell restarted:

```bash
omarchy restart shell
sleep 6
omarchy-shell shell ping                 # expect "ok"
omarchy-shell io.github.yks777.kairos ping        # expect "ok"
omarchy-shell io.github.yks777.kairos status      # expect JSON
omarchy-shell shell summon io.github.yks777.kairos '{}'   # opens panel
omarchy-shell shell hide io.github.yks777.kairos          # closes panel
omarchy-shell omarchy.clock refresh                        # legacy target responds
```

**If any command fails → debug and fix.**

---

## 14. ZIP delivery check

If all the above passes, build and verify the ZIP:

```bash
cd "$PLUGIN_DIR/.."
rm -f io.github.yks777.kairos.zip
zip -r io.github.yks777.kairos.zip io.github.yks777.kairos/ \
  -x "*.DS_Store" -x "__MACOSX*" -x "*.git*" -x "*.log" -x "node_modules/*"

unzip -l io.github.yks777.kairos.zip | head -50
```

Verify:

- Exactly one top-level folder `io.github.yks777.kairos/`.
- `manifest.json` inside that folder.
- No symlinks.
- Scripts preserve `+x`.

**If the ZIP is missing or mis-structured → rebuild it.**

---

## 15. Final decision

- If **any** section above reveals a missing file, a missing feature, a broken binding, a wrong glyph, a Portuguese string, an emoji, a paid API, a symlink, a validation failure, or a missing ZIP → **fix it, re-verify, and repeat**.

- If **every single item** in sections 2 through 14 passes without exception, reply with exactly:

```
Tudo Pronto
```

Do not add any other text. Do not explain. Do not summarize. Just `Tudo Pronto`.

If anything was fixed during this audit, still reply only with `Tudo Pronto` once everything passes — the fixes themselves are the deliverable.