import type { Plugin } from "@opencode-ai/plugin"

export default (async ({ client, project, directory, $ }) => {
  return {
    config: async (cfg) => {
      const LITELLM_INFO_URL = "http://localhost:1337/model/info"
      try {
        const response = await fetch(LITELLM_INFO_URL)
        if (!response.ok) {
          console.warn(`[sync-models] Failed to fetch model info from ${LITELLM_INFO_URL}: ${response.statusText}`)
          return
        }
        let data = await response.json()
        if (data && !Array.isArray(data) && Array.isArray(data.data)) {
          data = data.data
        }
        if (!Array.isArray(data)) {
          console.warn("[sync-models] Expected model info to be an array")
          return
        }

        const liveModels: Record<string, any> = {}
        for (const item of data) {
          if (!item.model_name) continue
          
          const modelId = item.model_name
          const info = item.model_info || {}
          
          // Derive a pretty name from modelId
          const segments = modelId.split("-")
          const nameParts: string[] = []
          let pendingDigits: string | null = null
          
          for (const seg of segments) {
            if (/^[0-9]+$/.test(seg)) {
              if (pendingDigits) {
                pendingDigits += "." + seg
              } else {
                pendingDigits = seg
              }
            } else {
              if (pendingDigits) {
                nameParts.push(pendingDigits)
                pendingDigits = null
              }
              nameParts.push(seg.charAt(0).toUpperCase() + seg.slice(1))
            }
          }
          if (pendingDigits) {
            nameParts.push(pendingDigits)
          }
          const prettyName = nameParts.join(" ")

          // LiteLLM reports pricing per single token; opencode's `cost` object
          // expects price per 1,000,000 tokens. Convert here so the built-in
          // TUI "$ spent" footer computes real spend.
          const PER_MILLION = 1_000_000
          const toMillion = (v: any) =>
            typeof v === "number" ? v * PER_MILLION : undefined

          const cost: Record<string, any> = {}
          const input = toMillion(info.input_cost_per_token)
          const output = toMillion(info.output_cost_per_token)
          const cacheRead = toMillion(info.cache_read_input_token_cost)
          const cacheWrite = toMillion(info.cache_creation_input_token_cost)
          if (input !== undefined) cost.input = input
          if (output !== undefined) cost.output = output
          if (cacheRead !== undefined) cost.cache_read = cacheRead
          if (cacheWrite !== undefined) cost.cache_write = cacheWrite

          // Optional tiered pricing above 200k tokens.
          const inputOver = toMillion(info.input_cost_per_token_above_200k_tokens)
          const outputOver = toMillion(info.output_cost_per_token_above_200k_tokens)
          if (inputOver !== undefined && outputOver !== undefined) {
            cost.context_over_200k = { input: inputOver, output: outputOver }
          }

          // `limit` drives the context/output token gauges.
          const limit: Record<string, any> = {}
          if (typeof info.max_input_tokens === "number") {
            limit.context = info.max_input_tokens
          }
          if (typeof info.max_output_tokens === "number") {
            limit.output = info.max_output_tokens
          }

          const model: Record<string, any> = {
            id: modelId,
            name: prettyName,
            release_date: (info.created_at || new Date().toISOString()).slice(0, 10)
          }
          // opencode requires cost.input & cost.output together; only attach
          // the cost object when both are present.
          if (cost.input !== undefined && cost.output !== undefined) {
            model.cost = cost
          }
          // opencode requires limit.context & limit.output together.
          if (limit.context !== undefined && limit.output !== undefined) {
            model.limit = limit
          }

          liveModels[modelId] = model
        }

        if (Object.keys(liveModels).length > 0) {
          if (!cfg.provider) cfg.provider = {}
          if (!cfg.provider.litellm) cfg.provider.litellm = {}
          cfg.provider.litellm.models = liveModels
          console.log(`[sync-models] Dynamic sync loaded ${Object.keys(liveModels).length} models from /model/info.`)
        }
      } catch (err: any) {
        console.warn(`[sync-models] Could not dynamically sync models from ${LITELLM_INFO_URL}: ${err.message}`)
      }
    }
  }
}) satisfies Plugin
