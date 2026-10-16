// Agent 連接懶人包・hello Worker
// /api/check（POST）：寫入一筆測試資料到 D1 的 connect_check，再讀回總筆數。
// 其他路徑：交給靜態網頁（public/）。
// 不需要任何金鑰：Worker 透過 wrangler.jsonc 的 d1_databases（binding: DB）直接存取資料庫。

const JSON_HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'no-store',
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

function explain(err) {
  const msg = String((err && err.message) || err);
  if (/no such table/i.test(msg)) {
    return msg + '｜資料表 connect_check 不存在：還沒跑 migrations apply（請 Agent 重做 AGENTS.md 第 5 步）。';
  }
  return msg;
}

async function check(env) {
  if (!env.DB) {
    return json({
      ok: false,
      error: '找不到資料庫綁定 DB：wrangler.jsonc 還沒有 d1_databases（請 Agent 重做 AGENTS.md 第 4 步，再重新部署）。',
    }, 500);
  }
  try {
    const note = 'hello ' + new Date().toISOString();
    await env.DB.prepare('INSERT INTO connect_check(note) VALUES (?)').bind(note).run();
    const row = await env.DB.prepare('SELECT count(*) AS count FROM connect_check').first();
    return json({ ok: true, count: row ? Number(row.count) : 0 });
  } catch (err) {
    return json({ ok: false, error: explain(err) }, 500);
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/api/check') {
      if (request.method !== 'POST') {
        return json({ ok: false, error: '請用 POST 呼叫 /api/check' }, 405);
      }
      return check(env);
    }
    if (url.pathname.startsWith('/api/')) {
      return json({ ok: false, error: '找不到這個 API：' + url.pathname }, 404);
    }
    return env.ASSETS.fetch(request);
  },
};
