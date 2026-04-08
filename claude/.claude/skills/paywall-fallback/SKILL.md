---
name: paywall-fallback
description: Handles paywalled or access-restricted webpages gracefully. Trigger this skill whenever a web_fetch or web page retrieval returns content that appears to be blocked by a paywall, login wall, cookie wall, anti-bot protection, or similar access restriction. Also trigger when the user preemptively mentions that a URL they're sharing is behind a paywall or requires a subscription. Signs of a paywall include truncated article text, "subscribe to continue reading" messages, login prompts in place of content, HTTP 401/403 responses, or content that is clearly incomplete compared to what was expected.
---

# Paywall Fallback

When you detect that a webpage is paywalled or access-restricted, follow this workflow instead of giving up or working with incomplete content.

## How to detect a paywall

After fetching a URL, check for these signals:

- The page text contains phrases like "subscribe to read", "sign in to continue", "premium content", "members only", "paywall", "free articles remaining", or similar gating language
- The article body is suspiciously short or truncated mid-sentence
- The response is an HTTP 401 or 403 error
- The page content is mostly navigation/boilerplate with little or no article body
- Anti-bot or CAPTCHA content is returned instead of the article
- The user told you in advance that the page is paywalled

## What to do

When you detect a paywall (or the user warns you about one), ask the user for help getting the content. Present the situation clearly and offer two options:

1. **Alternative URL** — The user may have access through a cached version, an archive link, a different mirror, or another source that hosts the same content without a paywall.
2. **Paste the raw content** — The user can copy-paste the article text (or the page's HTML source) directly into the chat. They can often do this from their browser where they have an active subscription.

Here's the tone to strike — be matter-of-fact, not apologetic. Something like:

> It looks like [URL] is behind a paywall — I'm only seeing [brief description of what you got, e.g. "the first two paragraphs and a subscribe prompt"]. I can work with the full content if you can provide it in one of two ways:
>
> 1. An alternative URL where the content is freely accessible (e.g. a cached or archived version)
> 2. The article text or HTML pasted directly into the chat
>
> Which works better for you?

Adapt phrasing naturally — the above is a template, not a script. If the context makes one option obviously better, lead with that one.

## After receiving the content

- If the user provides an alternative URL, fetch it and proceed normally. If that URL is also blocked, let the user know and ask them to paste the content instead.
- If the user pastes text or HTML, work with it directly. For raw HTML, extract the meaningful article content and ignore boilerplate markup.
- If the user pastes a very large block of HTML, acknowledge it and focus on the article body rather than processing every element.

## Edge cases

- **Partial content is enough**: If the paywall only blocks part of the article and the visible portion is sufficient to answer the user's question, mention that you only have partial content and ask whether they'd like you to proceed with what's available or get the full text.
- **User says "never mind"**: That's fine — move on. Don't push.
- **Multiple paywalled links**: If the user shares several links and some are paywalled, handle them individually. Fetch all of them first, then report which ones you could access and which ones need alternatives.
- **User preemptively provides HTML**: If the user pastes HTML or article text alongside their request (anticipating the paywall), just use it — no need to try fetching the URL first or asking redundant questions.
