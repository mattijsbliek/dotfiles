/** @jsxImportSource @opentui/solid */
import { createSignal, onMount, onCleanup, createMemo, Show } from "solid-js"
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui"

const BAR_WIDTH = 20

function formatMoney(value: number): string {
  return `$${value.toFixed(2)}`
}

function fmtCountdown(s: number): string {
  if (s < 0) s = 0
  const m = Math.floor(s / 60)
  const sec = Math.floor(s % 60)
  return `${m}m ${sec.toString().padStart(2, "0")}s`
}

function capitalize(label: string): string {
  return label.charAt(0).toUpperCase() + label.slice(1)
}

function View(props: { api: TuiPluginApi }) {
  // Mirrors the internal "sidebar-mcp" section: expanded by default, header
  // row toggles on click, collapsed state shows an inline muted summary.
  const [expanded, setExpanded] = createSignal(true)
  const [budget, setBudget] = createSignal<any>(null)
  let pollInterval: any

  const fetchBudget = async () => {
    try {
      const response = await fetch("http://localhost:1337/budget/me")
      if (response.ok) setBudget(await response.json())
    } catch (e) {
      // keep last known value; offline state is handled in render
    }
  }

  onMount(() => {
    fetchBudget()
    pollInterval = setInterval(fetchBudget, 500)
  })

  onCleanup(() => {
    if (pollInterval) clearInterval(pollInterval)
  })

  const theme = () => props.api.theme.current

  const pct = createMemo(() => Math.round(budget()?.window?.utilization_pct ?? 0))

  const statusColor = createMemo(() => {
    if (!budget()) return theme().textMuted
    const p = pct()
    if (p >= 90) return theme().error
    if (p >= 70) return theme().warning
    return theme().success
  })

  const summary = createMemo(() => {
    const b = budget()
    if (!b) return "offline"
    return `${pct()}%, reset in ${fmtCountdown(b.window.seconds_remaining ?? 0)}`
  })

  function Row(rowProps: { label: string; value: string; color?: string }) {
    return (
      <box flexDirection="row" gap={1}>
        <text fg={theme().textMuted}>{"\u2022"}</text>
        <text fg={theme().textMuted}>{capitalize(rowProps.label)}</text>
        <text fg={rowProps.color ?? theme().text}>{rowProps.value}</text>
      </box>
    )
  }

  return (
    <box flexDirection="column">
      <box flexDirection="row" gap={1} onMouseDown={() => setExpanded((v) => !v)}>
        <text fg={theme().text}>{expanded() ? "\u25BC" : "\u25B6"}</text>
        <text fg={statusColor()}>
          <b>Budget</b>
          
            <span style={{ fg: statusColor() }}> {summary()}</span>
        </text>
      </box>

      <Show when={expanded()}>
        <box flexDirection="column">
          <Show
            when={budget()}
            fallback={<text fg={theme().error}>offline (localhost:1337)</text>}
          >
            <Row label="spent" value={formatMoney(budget().window.user_spent ?? 0)} />
            <Row label="left" value={formatMoney(budget().window.user_remaining ?? 0)} />
            <Row label="users" value={String(budget().window.active_users ?? 0)} />
            <Row
              label="phase"
              value={budget().window.is_peak ? "peak" : "off-peak"}
              color={budget().window.is_peak ? theme().warning : theme().success}
            />
            <Row label="pool" value={formatMoney(budget().window.global_budget ?? 0)} />
          </Show>
        </box>
      </Show>
    </box>
  )
}

const tui: TuiPlugin = async (api) => {
  const { slots } = api

  slots.register({
    order: 10,
    slots: {
      sidebar_content(_ctx, _props) {
        return <View api={api} />
      },
    },
  })
}

const plugin: TuiPluginModule & { id: string } = {
  id: "mollie.budget-sidebar",
  tui,
}

export default plugin
