// In-TUI code annotator for OpenCode V2.
//
// Flow: `/annotate` opens a session panel with a file loaded (changed files are
// offered first), or `/annotate last` loads the session's last message.
// Click-drag to select a range of lines (or click to clear), right-click (or
// `c`) to comment the range, then `s` sends the annotations into the session.
// Keyboard-only selection: j/k or arrows move, shift+arrows extend the range.
//
// Built against the V2 CLI plugin contract: default export `{ id, setup }`
// with the `context.*` API (keymap layers, promise dialogs, session.panel).

/** @jsxImportSource @opentui/solid */
import { createEffect, createMemo, createSignal, For, Show } from "solid-js"
import { exec } from "node:child_process"
import { promisify } from "node:util"
import { readFileSync } from "node:fs"
import { isAbsolute, join, relative } from "node:path"

const MAX_LINES = 5000

interface Row {
  n: number // 1-based display line number within the source
  text: string
  messageID?: string // set when the row comes from a session message
  cont?: boolean // wrapped continuation of the previous source line
}

interface Source {
  kind: "file" | "message"
  path?: string
  sessionID?: string
  messageID?: string
  role?: string
}

interface Annotation {
  sourceKey: string
  start?: number
  end?: number
  comment: string
  excerpt: string
  messageID?: string
  role?: string
}

// No imports from `@opencode/plugin` needed — the loader validates a plain
// `{ id, setup }` default export, and OpenCode injects `context` into `setup`.

// Unquote a porcelain path and, for rename/copy entries, keep the destination.
function porcelainPath(rest: string): string {
  if (rest.startsWith('"') && rest.endsWith('"')) {
    try {
      rest = JSON.parse(rest)
    } catch {
      rest = rest.slice(1, -1)
    }
  }
  const arrow = rest.indexOf(" -> ")
  return arrow >= 0 ? rest.slice(arrow + 4) : rest
}

async function listChangedFiles(directory: string): Promise<string[]> {
  try {
    const { stdout } = await promisify(exec)("git status --porcelain=v1", {
      cwd: directory,
      encoding: "utf8",
      maxBuffer: 10 * 1024 * 1024,
    })
    return stdout
      .split("\n")
      .filter((line) => line.length > 3)
      .map((line) => porcelainPath(line.slice(3).trim()))
      .filter((path) => path.length > 0)
  } catch {
    return []
  }
}

function readLines(path: string): string[] | null {
  try {
    return readFileSync(path, "utf8").split("\n")
  } catch {
    return null
  }
}

// Soft-wrap a line into segments that fit `width` cells, breaking at spaces
// when one is close enough to the edge, hard-breaking otherwise.
function wrapText(text: string, width: number): string[] {
  if (width < 4 || text.length <= width) return [text]
  const out: string[] = []
  let rest = text
  while (rest.length > width) {
    let cut = rest.lastIndexOf(" ", width)
    if (cut < Math.floor(width / 2)) cut = width
    else cut = cut + 1
    out.push(rest.slice(0, cut).replace(/\s+$/, ""))
    rest = rest.slice(cut).replace(/^\s+/, "")
  }
  if (rest.length || out.length === 0) out.push(rest)
  return out
}

export default {
  id: "annotate.tui",
  setup(context: any) {
    const [source, setSource] = createSignal<Source | null>(null)
    const [rows, setRows] = createSignal<Row[]>([])
    const [anns, setAnns] = createSignal<Annotation[]>([])
    const [status, setStatus] = createSignal("Drag to select, right-click to comment")
    const [cursor, setCursor] = createSignal(0) // 0-based row index
    const [offset, setOffset] = createSignal(0) // first visible row index
    const [visible, setVisible] = createSignal(20) // measured panel height in rows
    const [sessionID, setSessionID] = createSignal<string | null>(null)
    const [sel, setSel] = createSignal<{ start: number; end: number } | null>(null)
    const [panelWidth, setPanelWidth] = createSignal(80)
    const [captured, setCaptured] = createSignal<string | null>(null) // last drag-selected text anywhere
    const [anchor, setAnchor] = createSignal<number | null>(null) // source line number anchoring a keyboard selection

    let container: any
    let pendingAnchor: number | null = null // row n awaiting the mouse-up
    let nativeStash: [number, number] | null = null // renderer selection captured on right-down

    const dir = () => context.location?.directory ?? process.cwd()

    // Theme tokens degrade gracefully if this beta names them differently.
    const color = (path: string, fallback?: string) => {
      let node: any = context.theme
      for (const part of path.split(".")) {
        if (node == null) return fallback
        node = node[part]
      }
      return node == null ? fallback : node
    }
    const look = () => ({
      text: color("text.default", "#d6d6d6"),
      muted: color("text.subdued", "#8b8b8b"),
      accent: color("accent.primary", color("primary", "#7aa2f7")),
      panel: color("backgroundMenu", undefined as string | undefined),
      highlight: color("warning", "#4d3f1e"),
      selBg: "#25335a",
    })

    const viewHeight = () => Math.max(4, visible())

    // Wrap source rows into display rows so long lines stay readable. One
    // display row per cell keeps the selection mapping intact.
    const wrappedRows = createMemo(() => {
      const gutterWidth = source()?.kind === "file" ? 7 : 0
      const width = Math.max(16, panelWidth() - gutterWidth)
      const out: Row[] = []
      for (const row of rows()) {
        const segments = wrapText(row.text, width)
        for (let i = 0; i < segments.length; i++) {
          out.push({ n: row.n, text: segments[i], messageID: row.messageID, cont: i > 0 })
        }
      }
      return out.length > MAX_LINES ? out.slice(0, MAX_LINES) : out
    })

    const windowed = createMemo(() => {
      const start = Math.max(0, Math.min(offset(), Math.max(0, wrappedRows().length - 1)))
      const end = Math.min(wrappedRows().length, start + viewHeight())
      return wrappedRows().slice(start, end)
    })

    const annotated = createMemo(() => {
      const set = new Set<number>()
      for (const a of anns()) {
        if (a.start == null) continue
        const end = a.end ?? a.start
        for (let n = a.start; n <= end; n++) set.add(n)
      }
      return set
    })

    const selected = createMemo(() => {
      const s = sel()
      if (!s) return new Set<number>()
      const set = new Set<number>()
      for (let n = s.start; n <= s.end; n++) set.add(n)
      return set
    })

    function clampOffset(value: number, preferCursor = -1) {
      const max = Math.max(0, wrappedRows().length - viewHeight())
      const next = Math.max(0, Math.min(value, max))
      setOffset(next)
      if (preferCursor >= 0) {
        if (preferCursor < next) setOffset(Math.max(0, preferCursor))
        else if (preferCursor >= next + viewHeight()) setOffset(preferCursor - viewHeight() + 1)
      }
    }

    function moveCursor(delta: number, keepAnchor = false) {
      if (!wrappedRows().length) return
      const next = Math.max(0, Math.min(cursor() + delta, wrappedRows().length - 1))
      setCursor(next)
      if (!keepAnchor) setAnchor(null)
      clampOffset(offset(), next)
    }

    // Extend the selection around the anchor with the keyboard (shift+arrows).
    function extendSelection(delta: number) {
      if (!wrappedRows().length) return
      const a = anchor() ?? wrappedRows()[cursor()]?.n
      if (a == null) return
      setAnchor(a)
      moveCursor(delta, true)
      const n = wrappedRows()[cursor()]?.n
      if (n != null) setSel(a <= n ? { start: a, end: n } : { start: n, end: a })
    }

    // Map a global Y (or an OpenTUI selection) onto row numbers: rows render
    // one cell tall in order, so a Y range indexes the visible window.
    function lineAt(globalY: number): number | null {
      if (!container) return null
      const items = windowed()
      if (!items.length) return null
      const index = Math.max(0, Math.min(globalY - container.screenY, items.length - 1))
      return items[index].n
    }

    function nativeSelectionLines(): [number, number] | null {
      const selection = context.renderer?.getSelection?.()
      if (!selection || !container) return null
      const excerpt = (selection.getSelectedText?.() ?? "").trim()
      if (!excerpt) return null
      const bounds = selection.bounds ?? { y: 0, height: 0 }
      const first = lineAt(bounds.y)
      const last = lineAt(bounds.y + Math.max(0, bounds.height - 1))
      if (first == null || last == null) return null
      return first <= last ? [first, last] : [last, first]
    }

    function selectedRange(): [number, number] | null {
      const s = sel()
      if (s) return [s.start, s.end]
      return nativeSelectionLines()
    }

    function resetSelection() {
      setSel(null)
      pendingAnchor = null
      nativeStash = null
      setAnchor(null)
    }

    // Left button: down anchors a drag, up finalizes it. A plain click
    // (same row) clears the selection.
    function onLeftDown(rowNo: number) {
      pendingAnchor = rowNo
    }

    function onLeftUp(rowNo: number) {
      if (pendingAnchor == null) return
      if (rowNo === pendingAnchor) {
        setSel(null)
      } else {
        setSel({ start: Math.min(pendingAnchor, rowNo), end: Math.max(pendingAnchor, rowNo) })
      }
      pendingAnchor = null
    }

    function onRightDown() {
      // Capture the renderer's text selection now — it may not survive
      // until the mouse-up event.
      nativeStash = nativeSelectionLines()
    }

    function onRightUp(rowNo: number) {
      const stash = nativeStash
      nativeStash = null
      const range = sel() ? selectedRange()! : stash ?? nativeSelectionLines() ?? [rowNo, rowNo]
      queueMicrotask(async () => comment(range[0], range[1]))
    }

    function loadRows(next: Row[], header: string) {
      setRows(next.length > MAX_LINES ? next.slice(0, MAX_LINES) : next)
      setAnns([])
      setCursor(0)
      setOffset(0)
      resetSelection()
      setStatus(
        next.length > MAX_LINES
          ? `${header} — showing first ${MAX_LINES} of ${next.length} lines`
          : `${header} — ${next.length} lines`,
      )
    }

    function loadFile(abs: string, content: string[]) {
      setSource({ kind: "file", path: abs })
      loadRows(
        content.map((text, i) => ({ n: i + 1, text })),
        relative(dir(), abs) || abs,
      )
    }

    async function loadLastMessage() {
      const target = context.ui.panel.current?.()?.sessionID ?? sessionID()
      if (!target) {
        toast("No session attached — open the panel inside a session", "error")
        return
      }
      let list: any[] = []
      try {
        // Documented data layer: typed, cached, with sync/invalidate.
        await context.data.session.message.sync(target)
        list = context.data.session.message.list(target) ?? []
      } catch (error: any) {
        toast(`Could not load messages: ${error?.message ?? error}`, "error")
        return
      }

      // Sort newest first so we don't depend on the server's ordering.
      const sorted = [...list].sort(
        (a, b) => (b.info?.time?.created ?? b.time?.created ?? 0) - (a.info?.time?.created ?? a.time?.created ?? 0),
      )
      const roles = new Set(["user", "assistant"])
      for (const entry of sorted) {
        const info = entry.info ?? entry
        // Assistant messages carry a content[] array; user messages carry
        // flat text. Handle both plus the historical {info, parts} wrapper.
        const parts = entry.parts ?? info.content ?? []
        const joined = (Array.isArray(parts) ? parts : [])
          .filter((p: any) => p.type === "text" && !p.synthetic && !p.ignored && typeof p.text === "string")
          .map((p: any) => p.text)
          .join("\n\n")
          .trim()
        const text = joined || (typeof info.text === "string" ? info.text.trim() : "")
        if (!text) continue
        const role: string = info.role ?? info.type ?? entry.type ?? "assistant"
        if (!roles.has(role)) continue
        setSource({ kind: "message", sessionID: target, messageID: info.id, role })
        loadRows(
          text.split("\n").map((t: string, idx: number) => ({ n: idx + 1, text: t, messageID: info.id })),
          `last ${role} message`,
        )
        return
      }
      toast("No text messages found in this session")
    }

    function onWheel(event: any) {
      const direction = event?.scroll?.direction
      if (direction !== "up" && direction !== "down") return
      event?.preventDefault?.()
      event?.stopPropagation?.()
      clampOffset(offset() + (direction === "down" ? 3 : -3))
    }

    async function comment(start: number, end: number) {
      const text = await context.ui.dialog.prompt({
        title: `Comment L${start}–L${end}`,
        placeholder: "What about this code?",
      })
      if (!text || !text.trim()) return
      const slice = rows().slice(start - 1, end)
      const excerpt = slice
        .map((r) => r.text)
        .join("\n")
        .trim()
        .slice(0, 240)
      const ids = new Set(slice.map((r) => r.messageID).filter(Boolean))
      const messageID = ids.size === 1 ? [...ids][0] : undefined
      const current = source()
      const src: Source = current ?? { kind: "file", path: "" }
      const sourceKey = src.kind === "file" ? `file:${src.path ?? ""}` : `msg:${messageID ?? ""}`
      setAnns((prev) => [
        ...prev,
        { sourceKey, start, end, comment: text.trim(), excerpt, messageID, role: src.role },
      ])
      resetSelection()
      setStatus(`L${start}–L${end} annotated — s to send, x to remove`)
    }

    async function commentSelection() {
      const range = selectedRange()
      if (range) {
        await comment(range[0], range[1])
        return
      }
      const n = wrappedRows()[cursor()]?.n ?? 1
      await comment(n, n)
    }

    // Annotate text selected anywhere in the TUI — including the session
    // transcript — without opening the panel. The renderer's "selection"
    // event fires when a drag selection finishes.
    async function commentCaptured() {
      const quote =
        captured() ?? (context.renderer?.getSelection?.()?.getSelectedText?.() ?? "").trim()
      if (!quote) {
        toast("Drag-select some text first (session or panel)")
        return
      }
      const text = await context.ui.dialog.prompt({
        title: "Comment on selection",
        description: quote.length > 160 ? `${quote.slice(0, 160)}…` : quote,
        placeholder: "What about it?",
      })
      if (!text || !text.trim()) return
      setAnns((prev) => [
        ...prev,
        { sourceKey: "selection", comment: text.trim(), excerpt: quote.slice(0, 2000) },
      ])
      setCaptured(null)
      setStatus(`${anns().length} annotations — ctrl+shift+s to send`)
    }

    function removeLast() {
      setAnns((prev) => prev.slice(0, -1))
    }

    function toast(message: string, variant: string = "info") {
      context.ui.toast.show({ message, variant })
    }

    async function pickFile(): Promise<string | null> {
      const files = await listChangedFiles(dir())
      const options = [{ title: "▸ Last message in this session", value: "@last" }]
      if (files.length === 0) {
        return context.ui.dialog.prompt({
          title: "Annotate",
          placeholder: "Path to a file (no changed files found)",
        })
      }
      options.push(...files.slice(0, 200).map((f) => ({ title: f, value: f })))
      return context.ui.dialog.select({
        title: "Annotate what?",
        options,
      })
    }

    function resolvePath(input: string): string {
      const trimmed = input.trim()
      return isAbsolute(trimmed) ? trimmed : join(dir(), trimmed)
    }

    function measure() {
      const height = container?.height
      if (typeof height === "number" && height > 2) setVisible(Math.floor(height))
    }

    async function openPanel(input?: string) {
      const arg = typeof input === "string" ? input.trim().toLowerCase() : ""

      // Slash fallbacks that don't need the alt bindings.
      if (arg === "sel" || arg === "selection" || arg === "quote") return commentCaptured()
      if (arg === "send") return send()

      const wantsMessage = arg === "last" || arg === "message" || arg === "msg"

      if (arg && !wantsMessage) {
        const abs = resolvePath(arg)
        const content = readLines(abs)
        if (!content) {
          toast(`Could not read ${arg}`, "error")
          return
        }
        const opened = await context.ui.panel.open("annotate.review")
        if (!opened) {
          toast("Open (or focus) a session first — annotations attach to it")
          return
        }
        loadFile(abs, content)
        globalThis.setTimeout(measure, 50)
        return
      }

      const opened = await context.ui.panel.open("annotate.review")
      if (!opened) {
        toast("Open (or focus) a session first — annotations attach to it")
        return
      }
      if (wantsMessage) {
        await loadLastMessage()
        globalThis.setTimeout(measure, 50)
        return
      }
      const picked = await pickFile()
      if (!picked || !picked.trim()) {
        context.ui.panel.close()
        return
      }
      if (picked.trim() === "@last") {
        await loadLastMessage()
        globalThis.setTimeout(measure, 50)
        return
      }
      const abs = resolvePath(picked)
      const content = readLines(abs)
      if (!content) {
        toast(`Could not read ${picked.trim()}`, "error")
        context.ui.panel.close()
        return
      }
      loadFile(abs, content)
      globalThis.setTimeout(measure, 50)
    }

    // Server contract (openapi): POST /api/session/{sessionID}/prompt with a
    // flat body. The path/body variant covers the generated-client's shape.
    async function sendToSession(target: string, text: string) {
      const client: any = context.client
      try {
        await client.session.prompt({ sessionID: target, text })
      } catch (error) {
        await client.session.prompt({ path: { sessionID: target }, body: { text } })
      }
    }

    async function send() {
      const current = anns()
      if (current.length === 0) {
        toast("No annotations to send")
        return
      }
      // The host wires the route under ui.router; current() is {type, sessionID}.
      const route: any = context.ui?.router?.current?.()
      const target = sessionID() ?? (route?.type === "session" ? route.sessionID : null)
      if (!target) {
        toast("No session to send to — open one first", "error")
        return
      }

      // Group annotations by what they refer to, preserving order.
      const groups: Array<{ label: string; items: Annotation[] }> = []
      const index = new Map<string, { label: string; items: Annotation[] }>()
      for (const a of current) {
        let group = index.get(a.sourceKey)
        if (!group) {
          if (a.sourceKey === "selection") {
            group = { label: "this session's conversation", items: [] }
          } else if (a.messageID) {
            group = { label: `the ${a.role ?? "assistant"}'s message`, items: [] }
          } else {
            const rel = relative(dir(), source()?.path ?? "") || source()?.path || "file"
            group = { label: `\`${rel}\``, items: [] }
          }
          index.set(a.sourceKey, group)
          groups.push(group)
        }
        group.items.push(a)
      }

      const body = [
        "Code annotations — please address these review comments:",
        "",
        ...groups.flatMap((group) => [
          `**On ${group.label}:**`,
          ...group.items.map((a) => {
            const range = a.start == null ? "" : a.start === a.end ? `**L${a.start}**: ` : `**L${a.start}–L${a.end}**: `
            const excerpt = a.excerpt ? `\n   > ${a.excerpt.split("\n").join("\n   > ")}` : ""
            return `- ${range}${a.comment}${excerpt}`
          }),
          "",
        ]),
      ].join("\n")

      try {
        await sendToSession(target, body)
        setAnns([])
        resetSelection()
        setCaptured(null)
        setStatus("Sent — annotate more, or esc to close")
        toast(`Sent ${current.length} annotation(s) to the session`, "success")
      } catch (error: any) {
        toast(`Send failed: ${error?.message ?? error}`, "error")
      }
    }

    // The panel contribution: its keymap layer registers once per mount and
    // the host disposes it when the panel closes.
    function AnnotatePanel(props: { panel: any }) {
      const panel = props.panel
      const colors = look()

      context.keymap.layer(() => ({
        priority: 100,
        commands: [
          { id: "annotate.comment", bind: "c", run: () => void commentSelection() },
          { id: "annotate.enter", bind: "return", run: () => void commentSelection() },
          { id: "annotate.send", bind: "s", run: () => void send() },
          { id: "annotate.remove", bind: "x", run: () => removeLast() },
          {
            id: "annotate.close",
            bind: "escape",
            run: () => {
              // First escape clears the selection, second closes the panel.
              if (pendingAnchor != null || sel()) {
                resetSelection()
                return
              }
              panel.close()
            },
          },
          { id: "annotate.up", bind: "up", run: () => moveCursor(-1) },
          { id: "annotate.down", bind: "down", run: () => moveCursor(1) },
          { id: "annotate.extend.up", bind: "shift+up", run: () => extendSelection(-1) },
          { id: "annotate.extend.down", bind: "shift+down", run: () => extendSelection(1) },
          { id: "annotate.k", bind: "k", run: () => moveCursor(-1) },
          { id: "annotate.j", bind: "j", run: () => moveCursor(1) },
          {
            id: "annotate.page.up",
            bind: "pageup",
            run: () => clampOffset(offset() - Math.floor(viewHeight() / 2)),
          },
          {
            id: "annotate.page.down",
            bind: "pagedown",
            run: () => clampOffset(offset() + Math.floor(viewHeight() / 2)),
          },
        ],
        bindings: [
          "annotate.comment",
          "annotate.enter",
          "annotate.send",
          "annotate.remove",
          "annotate.close",
          "annotate.up",
          "annotate.down",
          "annotate.extend.up",
          "annotate.extend.down",
          "annotate.k",
          "annotate.j",
          "annotate.page.up",
          "annotate.page.down",
        ],
      }))

      // Track the session this panel is attached to so `s` can send to it,
      // and keep the wrap width in sync with the panel's real width (the
      // outer box adds 1 cell of padding on each side). Both are reactive
      // host properties; re-measure the height whenever they move so a
      // terminal resize doesn't leave a stale scroll window.
      createEffect(() => setSessionID(panel.sessionID))
      createEffect(() => {
        setPanelWidth(Math.max(24, Math.floor((panel.width ?? 80) - 2)))
        globalThis.setTimeout(measure, 0)
      })
      createEffect(() => {
        void panel.height
        globalThis.setTimeout(measure, 0)
      })

      const header = () => {
        const src = source()
        if (!src) return "No file"
        if (src.kind === "message") return `last ${src.role ?? "assistant"} message`
        return relative(dir(), src.path!) || src.path!
      }

      return (
        <box
          flexDirection="column"
          width="100%"
          height="100%"
          backgroundColor={colors.panel}
          paddingLeft={1}
          paddingRight={1}
        >
          <box flexShrink={0} flexDirection="row" width="100%">
            <text wrapMode="none" fg={colors.accent} flexShrink={0}>
              {`${header()}  `}
            </text>
            <text wrapMode="none" fg={colors.muted} flexGrow={1}>
              {`${status()}   L${cursor() + 1}`}
            </text>
            <text
              wrapMode="none"
              fg={colors.muted}
              flexShrink={0}
              onMouseUp={(e: any) => {
                if (e?.button != null && e.button !== 0) return
                panel.close()
              }}
            >
              {" esc close"}
            </text>
          </box>
          <Show
            when={source()}
            fallback={
              <box flexGrow={1} alignItems="center" justifyContent="center">
                <text fg={colors.muted}>No file loaded</text>
              </box>
            }
          >
            <box
              ref={(el: any) => {
                container = el
              }}
              flexGrow={1}
              flexShrink={0}
              flexDirection="column"
              onMouseScroll={(e: any) => onWheel(e)}
              onMouseDown={(e: any) => {
                if (!container || e?.type !== "down") return
                if (e?.button === 2) {
                  e?.preventDefault?.()
                  e?.stopPropagation?.()
                  onRightDown()
                  return
                }
                if (e?.button === 0) {
                  const rowNo = lineAt(e.y)
                  if (rowNo != null) onLeftDown(rowNo)
                }
              }}
              onMouseUp={(e: any) => {
                if (!container || e?.type !== "up") return
                if (e?.button === 2) {
                  e?.preventDefault?.()
                  e?.stopPropagation?.()
                  const rowNo = lineAt(e.y)
                  if (rowNo != null) onRightUp(rowNo)
                  return
                }
                if (e?.button === 0 && pendingAnchor != null) {
                  const rowNo = lineAt(e.y)
                  if (rowNo != null) onLeftUp(rowNo)
                }
              }}
            >
              <For each={windowed()}>
                {(item) => (
                  <box
                    flexShrink={0}
                    width="100%"
                    backgroundColor={
                      annotated().has(item.n)
                        ? colors.highlight
                        : selected().has(item.n)
                          ? colors.selBg
                          : undefined
                    }
                    onMouseDown={(e: any) => {
                      if (e?.type !== "down") return
                      e?.stopPropagation?.()
                      if (e?.button === 2) onRightDown()
                      else if (e?.button === 0) onLeftDown(item.n)
                    }}
                    onMouseUp={(e: any) => {
                      if (e?.type !== "up") return
                      e?.stopPropagation?.()
                      if (e?.button === 2) onRightUp(item.n)
                      else if (e?.button === 0) onLeftUp(item.n)
                    }}
                  >
                    <text wrapMode="none">
                      <Show when={source()?.kind === "file"}>
                        <span style={{ fg: colors.muted }}>
                          {item.cont ? "       " : `${String(item.n).padStart(4)} ╎ `}
                        </span>
                      </Show>
                      <span style={{ fg: colors.text }}>{item.text}</span>
                    </text>
                  </box>
                )}
              </For>
            </box>
          </Show>
          <Show when={anns().length > 0}>
            <box flexShrink={0} flexDirection="column" width="100%" paddingTop={1}>
              <For each={anns().slice(-4)}>
                {(a) => (
                  <text wrapMode="none">
                    <span style={{ fg: colors.accent }}>
                      {a.start == null ? "" : `L${a.start}${a.end !== a.start ? `–L${a.end}` : ""} `}
                    </span>
                    <span style={{ fg: colors.text }}>{a.comment}</span>
                  </text>
                )}
              </For>
              <Show when={anns().length > 4}>
                <text wrapMode="none" fg={colors.muted}>{`  … ${anns().length - 4} more`}</text>
              </Show>
              <box flexDirection="row" width="100%">
                <text
                  wrapMode="none"
                  fg={colors.accent}
                  onMouseUp={(e: any) => {
                    if (e?.button != null && e.button !== 0) return
                    void send()
                  }}
                >
                  {"[s] send  "}
                </text>
                <text
                  wrapMode="none"
                  fg={colors.muted}
                  onMouseUp={(e: any) => {
                    if (e?.button != null && e.button !== 0) return
                    removeLast()
                  }}
                >
                  {"[x] remove last  "}
                </text>
                <text
                  wrapMode="none"
                  fg={colors.muted}
                  onMouseUp={(e: any) => {
                    if (e?.button != null && e.button !== 0) return
                    void commentSelection()
                  }}
                >
                  {"[c] comment selection"}
                </text>
              </box>
            </box>
          </Show>
        </box>
      )
    }

    // Global `/annotate` command (palette + slash). The app slot render is the
    // documented place to register global keymap layers.
    context.ui.slot({
      append: "app",
      render: () => {
        context.keymap.layer(() => ({
          mode: "global",
          priority: 10,
          commands: [
            {
              id: "annotate.open",
              title: "Annotate a file",
              description: "Pick a changed file (or `/annotate last` for the last message), highlight lines, right-click to comment.",
              group: "Annotate",
              palette: true,
              suggested: true,
              slash: { name: "annotate", arguments: true },
              run: (input?: string) => openPanel(input),
            },
            {
              id: "annotate.quick",
              title: "Comment on selection",
              description: "Comment on text you drag-selected anywhere (session transcript included).",
              group: "Annotate",
              palette: true,
              bind: "ctrl+shift+k",
              run: () => commentCaptured(),
            },
            {
              id: "annotate.send.all",
              title: "Send annotations",
              description: "Send all pending annotations into the current session.",
              group: "Annotate",
              palette: true,
              bind: "ctrl+shift+s",
              run: () => send(),
            },
            {
              id: "annotate.remove.last",
              title: "Remove last annotation",
              group: "Annotate",
              bind: "ctrl+shift+x",
              run: () => removeLast(),
            },
          ],
          bindings: ["annotate.quick", "annotate.send.all", "annotate.remove.last"],
        }))
        return null
      },
    })

    context.ui.slot({
      append: "session.panel",
      render: (panel: any) => (
        <Show when={panel.name === "annotate.review"}>
          <AnnotatePanel panel={panel} />
        </Show>
      ),
    })

    // Pending-annotation counter in the prompt footer (visible without the
    // panel being open).
    context.ui.slot({
      append: "prompt.footer",
      render: () => {
        const colors = look()
        return (
          <Show when={anns().length > 0}>
            <text wrapMode="none" fg={colors.accent}>
              {`annotate: ${anns().length} pending — ctrl+shift+s send, ctrl+shift+x remove last`}
            </text>
          </Show>
        )
      },
    })

    // Capture drag selections made anywhere in the TUI (the session
    // transcript included) so ctrl+shift+k can comment them without the panel.
    const onSelection = (selection: any) => {
      try {
        const text = (selection?.getSelectedText?.() ?? "").trim()
        setCaptured(text ? text.slice(0, 4000) : null)
      } catch {}
    }
    context.renderer?.on?.("selection", onSelection)

    return () => {
      context.renderer?.off?.("selection", onSelection)
    }
  },
}
