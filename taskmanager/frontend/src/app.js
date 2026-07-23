import { useState, useEffect } from "react";

const API = "";

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState("");

  // Fetch all tasks on load
  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    const res = await fetch(`${API}/api/tasks`);
    const data = await res.json();
    setTasks(data);
  };

  const addTask = async () => {
    if (!title.trim()) { setError("Task title cannot be empty"); return; }
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
    await fetch(`${API}/api/tasks/${id}`, { method: "DELETE" });
    fetchTasks();
  };

  return (
    <div style={styles.container}>
      <h1 style={styles.heading}>Task Manager</h1>
      <div style={styles.inputRow}>
        <input
          style={styles.input}
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && addTask()}
          placeholder="Enter a new task..."
        />
        <button style={styles.addBtn} onClick={addTask}>Add</button>
      </div>
      {error && <p style={styles.error}>{error}</p>}
      <ul style={styles.list}>
        {tasks.map((task) => (
          <li key={task.id} style={styles.taskItem}>
            <span
              onClick={() => toggleTask(task.id, task.completed)}
              style={{
                ...styles.taskTitle,
                textDecoration: task.completed ? "line-through" : "none",
                color: task.completed ? "#888" : "#222",
                cursor: "pointer",
              }}
            >
              {task.completed ? "✅" : "⬜"} {task.title}
            </span>
            <button style={styles.deleteBtn} onClick={() => deleteTask(task.id)}>
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

const styles = {
  container: { maxWidth: 600, margin: "60px auto", fontFamily: "sans-serif", padding: "0 20px" },
  heading: { fontSize: 28, marginBottom: 24, color: "#1a1a2e" },
  inputRow: { display: "flex", gap: 8, marginBottom: 8 },
  input: { flex: 1, padding: "10px 14px", fontSize: 16, border: "1px solid #ccc", borderRadius: 6 },
  addBtn: { padding: "10px 20px", background: "#4a90d9", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", fontSize: 16 },
  list: { listStyle: "none", padding: 0, marginTop: 20 },
  taskItem: { display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 0", borderBottom: "1px solid #eee" },
  taskTitle: { fontSize: 16 },
  deleteBtn: { padding: "6px 12px", background: "#e74c3c", color: "#fff", border: "none", borderRadius: 4, cursor: "pointer" },
  error: { color: "red", fontSize: 14 },
};