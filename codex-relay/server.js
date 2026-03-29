const express = require("express");
const { spawn } = require("child_process");
const { randomUUID } = require("crypto");
const path = require("path");
const fs = require("fs");

const app = express();
app.use(express.json());

// Config
const PORT = process.env.PORT || 4819;
const AUTH_TOKEN = process.env.RELAY_TOKEN || "chatgpt-watch-relay-2026";
const CODEX_PATH = process.env.CODEX_PATH || "/Users/adsol/.npm-global/bin/codex";
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || "";

// In-memory task store
const tasks = new Map();

// Auth middleware
function auth(req, res, next) {
  const token = req.headers.authorization?.replace("Bearer ", "");
  if (token !== AUTH_TOKEN) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
}

app.use(auth);

// POST /tasks — Create a new Codex task
app.post("/tasks", (req, res) => {
  const { prompt, workingDir, model } = req.body;
  if (!prompt) return res.status(400).json({ error: "prompt is required" });

  const taskId = randomUUID();
  const cwd = workingDir || process.env.HOME + "/Documents/techy-projects";

  // Validate working directory exists
  if (!fs.existsSync(cwd)) {
    return res.status(400).json({ error: `Directory not found: ${cwd}` });
  }

  const task = {
    id: taskId,
    prompt,
    workingDir: cwd,
    model: model || "gpt-5.3-codex",
    status: "running",
    output: "",
    error: null,
    createdAt: new Date().toISOString(),
    completedAt: null,
    filesChanged: [],
  };

  tasks.set(taskId, task);

  // Determine mode: cloud (shows in Codex app) vs local
  const env = req.body.env; // GitHub repo like "adsol6070/royaldusk-app"
  const useCloud = !!env;

  let args;
  if (useCloud) {
    // Codex Cloud — tasks show up in Codex desktop app + chatgpt.com/codex
    args = ["cloud", "exec", "--env", env, prompt];
    task.mode = "cloud";
    task.env = env;
  } else {
    // Local exec — runs directly on Mac filesystem
    args = [
      "exec",
      "--full-auto",
      "--skip-git-repo-check",
      "--model", task.model,
      "--json",
      "--cd", cwd,
      prompt,
    ];
    task.mode = "local";
  }

  console.log(`[${taskId.slice(0, 8)}] Mode: ${task.mode}`);
  console.log(`[${taskId.slice(0, 8)}] Starting: codex ${args.join(" ")}`);
  console.log(`[${taskId.slice(0, 8)}] CWD: ${cwd}`);

  const proc = spawn(CODEX_PATH, args, {
    cwd,
    env: {
      ...process.env,
      OPENAI_API_KEY,
      // Force non-interactive mode
      CI: "true",
      TERM: "dumb",
    },
    timeout: 300000, // 5 min max
  });

  let stdout = "";
  let stderr = "";
  let messages = [];
  let detectedFiles = [];

  proc.stdout.on("data", (data) => {
    const chunk = data.toString();
    stdout += chunk;

    // Parse JSONL events from codex --json output
    for (const line of chunk.split("\n")) {
      if (!line.trim()) continue;
      try {
        const evt = JSON.parse(line);
        if (evt.type === "item.completed" && evt.item) {
          if (evt.item.type === "agent_message" && evt.item.text) {
            messages.push(evt.item.text);
          }
          if (evt.item.type === "file_change" && evt.item.changes) {
            for (const c of evt.item.changes) {
              const action = c.kind === "add" ? "created" : c.kind === "delete" ? "deleted" : "modified";
              if (!detectedFiles.find(f => f.path === c.path)) {
                detectedFiles.push({ path: c.path, action });
              }
            }
          }
        }
      } catch {}
    }

    task.output = messages.join("\n\n") || stdout;
    task.filesChanged = detectedFiles;
    console.log(`[${taskId.slice(0, 8)}] event: ${chunk.slice(0, 120)}`);
  });

  proc.stderr.on("data", (data) => {
    stderr += data.toString();
  });

  proc.on("close", (code) => {
    task.status = code === 0 ? "completed" : "failed";
    task.completedAt = new Date().toISOString();
    task.output = stdout + (stderr && code !== 0 ? "\n--- error ---\n" + stderr : "");
    if (code !== 0) task.error = `Exit code ${code}: ${stderr.slice(0, 500)}`;

    // Detect changed files via git
    try {
      const { execSync } = require("child_process");
      const diff = execSync("git diff --name-status HEAD~1 2>/dev/null || git diff --name-status 2>/dev/null || echo ''", {
        cwd,
        encoding: "utf-8",
        timeout: 5000,
      }).trim();
      if (diff) {
        task.filesChanged = diff.split("\n").map((line) => {
          const [status, ...parts] = line.split("\t");
          const filePath = parts.join("\t");
          const action = status === "A" ? "created" : status === "D" ? "deleted" : "modified";
          return { path: filePath, action };
        });
      }
    } catch {}

    console.log(`[${taskId.slice(0, 8)}] Done: ${task.status} (code ${code})`);
  });

  proc.on("error", (err) => {
    task.status = "failed";
    task.error = err.message;
    task.completedAt = new Date().toISOString();
    console.error(`[${taskId.slice(0, 8)}] Error: ${err.message}`);
  });

  // Store process ref for cancellation
  task._proc = proc;

  res.status(201).json({
    id: task.id,
    status: task.status,
    prompt: task.prompt,
    workingDir: task.workingDir,
    model: task.model,
    createdAt: task.createdAt,
  });
});

// GET /tasks — List all tasks
app.get("/tasks", (req, res) => {
  const list = Array.from(tasks.values())
    .map(({ _proc, ...t }) => t)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  res.json({ tasks: list });
});

// GET /tasks/:id — Get task detail
app.get("/tasks/:id", (req, res) => {
  const task = tasks.get(req.params.id);
  if (!task) return res.status(404).json({ error: "Task not found" });
  const { _proc, ...safe } = task;
  res.json(safe);
});

// POST /tasks/:id/cancel — Cancel a running task
app.post("/tasks/:id/cancel", (req, res) => {
  const task = tasks.get(req.params.id);
  if (!task) return res.status(404).json({ error: "Task not found" });
  if (task.status !== "running") return res.json({ status: task.status });

  if (task._proc && !task._proc.killed) {
    task._proc.kill("SIGTERM");
  }
  task.status = "cancelled";
  task.completedAt = new Date().toISOString();
  const { _proc, ...safe } = task;
  res.json(safe);
});

// GET /cloud/tasks — List Codex Cloud tasks (shows in Codex app)
app.get("/cloud/tasks", (req, res) => {
  const { execSync } = require("child_process");
  try {
    const output = execSync(`${CODEX_PATH} cloud list --json --limit 20`, {
      encoding: "utf-8",
      timeout: 15000,
      env: { ...process.env, OPENAI_API_KEY, CI: "true", TERM: "dumb" },
    });
    const tasks = JSON.parse(output);
    res.json(tasks);
  } catch (err) {
    // Fallback: parse text output
    try {
      const output = execSync(`${CODEX_PATH} cloud list --limit 20`, {
        encoding: "utf-8",
        timeout: 15000,
        env: { ...process.env, OPENAI_API_KEY, CI: "true", TERM: "dumb" },
      });
      res.json({ raw: output });
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  }
});

// GET /health — Health check
app.get("/health", (_, res) => {
  res.json({ status: "ok", tasks: tasks.size, uptime: process.uptime() });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n🚀 Codex Relay Server running on port ${PORT}`);
  console.log(`   Auth token: ${AUTH_TOKEN}`);
  console.log(`   Codex CLI: ${CODEX_PATH}`);
  console.log(`   Ready to receive tasks from Apple Watch\n`);
});
