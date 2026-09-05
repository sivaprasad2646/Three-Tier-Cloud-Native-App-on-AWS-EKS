import { useState, useEffect } from "react";

const API = "";

export default function App() {
  // ── Existing state
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState("");

  // ── New state for AI Assistant
  const [aiQuery, setAiQuery] = useState("");
  const [aiAnswer, setAiAnswer] = useState("");
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState("");
  const [aiLatency, setAiLatency] = useState(null);

  // ── Existing useEffect
  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    const res = await fetch(`${API}/api/tasks`);
    const data = await res.json();
    setTasks(data);
  };

  const addTask = async () => {
    if (!title.trim()) {
      setError("Task title cannot be empty");
      return;
    }

    setError("");

    await fetch(`${API}/api/tasks`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title }),
    });

    setTitle("");
    fetchTasks();
  };

  const toggleTask = async (id, completed) => {
    await fetch(`${API}/api/tasks/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ completed: !completed }),
    });

    fetchTasks();
  };

  const deleteTask = async (id) => {
    await fetch(`${API}/api/tasks/${id}`, {
      method: "DELETE",
    });

    fetchTasks();
  };

  // ── New function — AI Assistant call
  const askAI = async () => {
    if (!aiQuery.trim()) {
      setAiError("Please enter a question");
      return;
    }

    if (aiQuery.length > 500) {
      setAiError("Question too long — max 500 characters");
      return;
    }

    setAiError("");
    setAiAnswer("");
    setAiLatency(null);
    setAiLoading(true);

    try {
      const res = await fetch(`${API}/api/ai-assistant`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          query: aiQuery,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setAiError(data.error || "Something went wrong");
        return;
      }

      setAiAnswer(data.answer);
      setAiLatency(data.latency_seconds);
    } catch (err) {
      setAiError("Could not reach AI service — please try again");
    } finally {
      setAiLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      {/* ── EXISTING TASK MANAGER SECTION ── */}

      <h1 style={styles.heading}>Task Manager</h1>

      <div style={styles.inputRow}>
        <input
          style={styles.input}
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && addTask()}
          placeholder="Enter a new task..."
        />

        <button style={styles.addBtn} onClick={addTask}>
          Add
        </button>
      </div>

      {error && <p style={styles.error}>{error}</p>}

      <ul style={styles.list}>
        {tasks.map((task) => (
          <li key={task.id} style={styles.taskItem}>
            <span
              onClick={() => toggleTask(task.id, task.completed)}
              style={{
                ...styles.taskTitle,
                textDecoration: task.completed
                  ? "line-through"
                  : "none",
                color: task.completed ? "#888" : "#222",
                cursor: "pointer",
              }}
            >
              {task.completed ? "✅" : "⬜"} {task.title}
            </span>

            <button
              style={styles.deleteBtn}
              onClick={() => deleteTask(task.id)}
            >
              Delete
            </button>
          </li>
        ))}
      </ul>

      {/* ── NEW AI ASSISTANT SECTION ── */}

      <div style={styles.divider} />

      <div style={styles.aiSection}>
        <h2 style={styles.aiHeading}>
          🤖 DevOps AI Assistant
        </h2>

        <p style={styles.aiSubtext}>
          Powered by Amazon Bedrock (Nova Lite) — Ask anything about
          Kubernetes, CI/CD, Docker, AWS, or Terraform
        </p>

        <div style={styles.inputRow}>
          <input
            style={styles.input}
            value={aiQuery}
            onChange={(e) => setAiQuery(e.target.value)}
            onKeyDown={(e) =>
              e.key === "Enter" && !aiLoading && askAI()
            }
            placeholder="e.g. What is a CrashLoopBackOff?"
            disabled={aiLoading}
          />

          <button
            style={{
              ...styles.addBtn,
              background: aiLoading ? "#999" : "#6c3fc5",
              cursor: aiLoading ? "not-allowed" : "pointer",
            }}
            onClick={askAI}
            disabled={aiLoading}
          >
            {aiLoading ? "Thinking..." : "Ask"}
          </button>
        </div>

        {/* Error */}
        {aiError && <p style={styles.error}>{aiError}</p>}

        {/* Loading indicator */}
        {aiLoading && (
          <div style={styles.loadingBox}>
            <p style={styles.loadingText}>
              ⏳ Calling Amazon Bedrock Nova Lite...
            </p>
          </div>
        )}

        {/* AI Answer */}
        {aiAnswer && (
          <div style={styles.answerBox}>
            <div style={styles.answerHeader}>
              <span style={styles.answerLabel}>
                Answer
              </span>

              {aiLatency !== null && (
                <span style={styles.latencyBadge}>
                  ⚡ {aiLatency}s
                </span>
              )}
            </div>

            <p style={styles.answerText}>
              {aiAnswer}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

const styles = {
  // ── Existing styles
  container: {
    maxWidth: 600,
    margin: "60px auto",
    fontFamily: "sans-serif",
    padding: "0 20px",
  },

  heading: {
    fontSize: 28,
    marginBottom: 24,
    color: "#1a1a2e",
  },

  inputRow: {
    display: "flex",
    gap: 8,
    marginBottom: 8,
  },

  input: {
    flex: 1,
    padding: "10px 14px",
    fontSize: 16,
    border: "1px solid #ccc",
    borderRadius: 6,
  },

  addBtn: {
    padding: "10px 20px",
    background: "#4a90d9",
    color: "#fff",
    border: "none",
    borderRadius: 6,
    cursor: "pointer",
    fontSize: 16,
  },

  list: {
    listStyle: "none",
    padding: 0,
    marginTop: 20,
  },

  taskItem: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "12px 0",
    borderBottom: "1px solid #eee",
  },

  taskTitle: {
    fontSize: 16,
  },

  deleteBtn: {
    padding: "6px 12px",
    background: "#e74c3c",
    color: "#fff",
    border: "none",
    borderRadius: 4,
    cursor: "pointer",
  },

  error: {
    color: "red",
    fontSize: 14,
  },

  // ── New AI Assistant styles

  divider: {
    margin: "40px 0",
    borderTop: "2px dashed #e0e0e0",
  },

  aiSection: {
    background: "#f8f6ff",
    borderRadius: 12,
    padding: "24px",
    border: "1px solid #d4c5f9",
  },

  aiHeading: {
    fontSize: 22,
    color: "#4a1d96",
    marginBottom: 6,
  },

  aiSubtext: {
    fontSize: 13,
    color: "#666",
    marginBottom: 16,
  },

  loadingBox: {
    marginTop: 16,
    padding: "12px 16px",
    background: "#ede9fe",
    borderRadius: 8,
  },

  loadingText: {
    color: "#5b21b6",
    fontSize: 14,
    margin: 0,
  },

  answerBox: {
    marginTop: 16,
    padding: "16px",
    background: "#fff",
    borderRadius: 8,
    border: "1px solid #d4c5f9",
  },

  answerHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 10,
  },

  answerLabel: {
    fontWeight: "bold",
    color: "#4a1d96",
    fontSize: 14,
  },

  latencyBadge: {
    fontSize: 12,
    color: "#059669",
    background: "#d1fae5",
    padding: "2px 8px",
    borderRadius: 12,
  },

  answerText: {
    fontSize: 15,
    lineHeight: 1.7,
    color: "#333",
    margin: 0,
    whiteSpace: "pre-wrap",
  },
};