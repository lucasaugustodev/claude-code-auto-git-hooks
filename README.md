# Claude Code Auto Git Hooks

Automacao completa de Git + GitHub usando **Claude Code Hooks** + **Cline CLI**.

Toda vez que o Claude Code edita ou cria um arquivo, o Cline CLI entra em acao automaticamente para fazer commit semantico e push. Zero intervencao manual.

## O Problema

Quando voce usa o Claude Code para desenvolver, ele edita e cria arquivos mas nao faz git commit/push automaticamente. Voce precisa lembrar de commitar, escrever mensagens de commit, fazer push... tudo manualmente.

## A Solucao

Hooks do Claude Code que interceptam cada edicao de arquivo e delegam ao Cline CLI as operacoes de git:

```
Voce pede algo ao Claude Code
    |
    +-- Claude edita arquivo (Edit/Write)
    |   +-- Hook PostToolUse dispara
    |       +-- Le o JSON do stdin (contem file_path)
    |       +-- Encontra o diretorio do projeto
    |       +-- Sem repo git?
    |       |   +-- Cline: git init + .gitignore + commit + gh repo create + push
    |       +-- Com repo git?
    |           +-- Cline: analisa diff + commit semantico + push
    |
    +-- Claude encerra sessao (Stop)
        +-- Hook Stop dispara
            +-- Verifica commits pendentes
            +-- Cline: push + cria PR se branch != main
```

## Pre-requisitos

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado
- [Cline CLI](https://www.npmjs.com/package/@anthropics/cline) instalado (`npm install -g @anthropics/cline`)
- [GitHub CLI](https://cli.github.com/) (`gh`) instalado e autenticado (`gh auth login`)
- Python 3 (para parsing do JSON nos scripts)
- Git

## Instalacao

### 1. Crie a pasta dos hooks

```bash
mkdir -p ~/.claude/hooks
```

### 2. Copie os scripts

Copie os dois arquivos de `hooks/` para `~/.claude/hooks/`:

```bash
cp hooks/auto-git.sh ~/.claude/hooks/auto-git.sh
cp hooks/auto-push.sh ~/.claude/hooks/auto-push.sh
```

### 3. Configure o Claude Code

Edite (ou crie) o arquivo `~/.claude/settings.json` e adicione a secao `hooks`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/auto-git.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/auto-push.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. Reinicie o Claude Code

Os hooks sao carregados na inicializacao. Reinicie o Claude Code para ativar.

## Como Funciona

### Hook `auto-git.sh` (PostToolUse)

Dispara toda vez que o Claude Code usa a tool `Edit` ou `Write`.

1. **Le o stdin JSON** do Claude Code que contem o `tool_input.file_path`
2. **Extrai o diretorio** do arquivo editado com `dirname`
3. **Procura o git root** com `git rev-parse --show-toplevel`
4. **Se ja tem repo git**: o Cline analisa o diff, faz `git add`, commit com mensagem semantica (conventional commits) e `git push`
5. **Se nao tem repo git**: o Cline faz `git init`, cria `.gitignore`, faz o primeiro commit, cria repo no GitHub com `gh repo create` e faz push

### Hook `auto-push.sh` (Stop)

Dispara quando a sessao do Claude Code encerra.

1. **Le o `cwd`** do stdin JSON e/ou a env var `CLAUDE_PROJECT_DIR`
2. **Encontra o git root**
3. **Se ha commits nao pushados**: o Cline faz push
4. **Se a branch nao for main/master**: o Cline cria um PR com `gh pr create`

### O JSON do stdin (PostToolUse)

O Claude Code passa para os hooks um JSON via stdin com esta estrutura:

```json
{
  "session_id": "abc123",
  "cwd": "/path/to/working/dir",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/absolute/path/to/edited/file.txt",
    "content": "..."
  },
  "tool_response": {
    "filePath": "/absolute/path/to/edited/file.txt",
    "success": true
  }
}
```

O campo chave e `tool_input.file_path` - e o caminho absoluto do arquivo que foi editado/criado.

## Estrutura do Projeto

```
claude-code-auto-git-hooks/
├── README.md
├── hooks/
│   ├── auto-git.sh      # Hook PostToolUse - commit + push a cada edicao
│   └── auto-push.sh     # Hook Stop - push final + cria PR
└── settings-example.json # Exemplo de configuracao do Claude Code
```

## Conventional Commits

O Cline gera mensagens de commit seguindo o padrao [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - nova funcionalidade
- `fix:` - correcao de bug
- `refactor:` - refatoracao de codigo
- `docs:` - alteracoes em documentacao
- `chore:` - tarefas de manutencao
- `style:` - formatacao, ponto e virgula, etc

## Troubleshooting

### Hook roda no diretorio errado

**Problema**: O CWD do Claude Code pode ser diferente do diretorio do projeto (ex: `C:\Windows\system32`).

**Solucao**: Os scripts extraem o `file_path` do JSON via stdin e usam `dirname` para navegar ate o diretorio correto. Nao dependem do CWD.

### Cline sem creditos

**Problema**: Erro `402 Insufficient balance`.

**Solucao**: Recarregue os creditos em [app.cline.bot/credits](https://app.cline.bot/credits) ou configure o Cline para usar um modelo/provider diferente.

### Hook nao dispara

**Problema**: Nada acontece ao editar arquivos.

**Solucao**: Reinicie o Claude Code. Os hooks sao carregados na inicializacao.

### Python nao encontrado

**Problema**: O script precisa do Python para parsear o JSON do stdin.

**Solucao**: Instale Python 3 e certifique-se que esta no PATH do bash.

## Licenca

MIT
