// MarocTV - Cloudflare Worker HLS Proxy
// يحول كل طلبات البث عبر Cloudflare لتجاوز حجب *6

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)

  // CORS preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Headers': '*',
      }
    })
  }

  const targetParam = url.searchParams.get('url')
  if (!targetParam) {
    return new Response(JSON.stringify({ status: 'MarocTV Proxy OK', usage: '?url=https://stream.example.com/stream.m3u8' }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }

  let targetUrl
  try {
    targetUrl = new URL(decodeURIComponent(targetParam))
  } catch {
    return new Response('Invalid URL', { status: 400 })
  }

  const response = await fetch(targetUrl.toString(), {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    },
    cf: { cacheEverything: false }
  })

  if (!response.ok && response.status !== 206) {
    return new Response(`Upstream error: ${response.status}`, { status: response.status })
  }

  const contentType = response.headers.get('content-type') || ''
  const isM3U8 = contentType.includes('mpegurl') || contentType.includes('x-mpegurl') ||
                 targetUrl.pathname.endsWith('.m3u8')

  if (isM3U8) {
    let body = await response.text()
    const workerBase = `${url.origin}${url.pathname}`

    // Rewrite absolute URLs
    body = body.replace(/^(https?:\/\/[^\s\r\n]+)$/gm, (match) => {
      return `${workerBase}?url=${encodeURIComponent(match)}`
    })

    // Rewrite relative URLs (../path or just path.ts)
    body = body.replace(/^(?!#)(?!https?:\/\/)([^\s\r\n]+)$/gm, (match) => {
      try {
        const absolute = new URL(match, targetUrl).toString()
        return `${workerBase}?url=${encodeURIComponent(absolute)}`
      } catch {
        return match
      }
    })

    return new Response(body, {
      status: response.status,
      headers: {
        'Content-Type': 'application/vnd.apple.mpegurl',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache',
      }
    })
  }

  // For .ts segments — stream directly
  return new Response(response.body, {
    status: response.status,
    headers: {
      'Content-Type': response.headers.get('content-type') || 'video/mp2t',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'public, max-age=60',
    }
  })
}
