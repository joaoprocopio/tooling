import http from "node:http";
import https from "node:https";
import fs from "node:fs";
import path from "node:path";

/*
ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude -p "say ok" --model haiku

1. System prompt → markdown
jq -r '[.system[].text] | join("\n\n---\n\n")' request.json > system.md

2. Tools → markdown
jq -r '.tools[] | "# \(.name)\n\n\(.description)\n\n```json\n\(.input_schema|tojson)\n```\n"' request.json > tools.md

3. Nomes das tools
jq -r '.tools[].name' request.json

4. Peso por seção
jq '{system:   ([.system[].text]|join("")|length),
     tools:    ([.tools[]|tojson]|join("")|length),
     messages: ([.messages[].content[]?|.text//""]|join("")|length)}' request.json

5. Maiores blocos ordenados
jq -r '.tools | map({name, chars:(tojson|length)}) | sort_by(-.chars) | .[] | "\(.chars)\t\(.name)"' request.json
*/

const OUT = import.meta.dirname;
const UP = "api.anthropic.com";
let n = 0;

http
  .createServer((req, res) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const body = Buffer.concat(chunks);
      if (req.url.includes("/v1/messages") && body.length) {
        const f = path.join(OUT, "request.json");
        fs.writeFileSync(f, body);
        console.error(`[captured] ${f} (${body.length} bytes)`);
      }
      const headers = { ...req.headers, host: UP };
      delete headers["content-length"];
      const up = https.request(
        { hostname: UP, port: 443, path: req.url, method: req.method, headers },
        (r) => {
          res.writeHead(r.statusCode, r.headers);
          r.pipe(res);
        },
      );
      up.on("error", (e) => {
        console.error("upstream err", e.message);
        res.writeHead(502);
        res.end();
      });
      if (body.length) up.write(body);
      up.end();
    });
  })
  .listen(8787, "127.0.0.1", () => console.error("proxy on 8787"));
