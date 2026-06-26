# Project Submission Document: The Last-Minute Life Saver

## 1. Executive Summary
**The Last-Minute Life Saver** is an AI-powered productivity companion designed specifically for students, professionals, and entrepreneurs who experience task paralysis and struggle with looming deadlines. By combining dynamic priority engines, generative milestone decomposition, context-aware nudge overlays, and an interactive NLP voice assistant, the app goes beyond traditional, passive calendar alerts. It acts as an active, stress-reducing copilot that guides users from planning to immediate execution.

* **Hackathon Track Alignment**: Vibe2Ship - Productivity & AI Companionship.
* **Core Philosophy**: Shift productivity from passive reminders (which are easily dismissed) to proactive, actionable assistance (which lowers the cognitive barrier to starting).

---

## 2. Problem Statement & Key Challenges
* **Task Paralysis**: When users face multiple high-stress deadlines, they experience cognitive overload and struggle to decide what to start first, leading to procrastination.
* **Passive Alert Fatigue**: Standard push notifications are easy to ignore or swipe away, doing nothing to help users transition into a state of focus.
* **Monolithic Objectives**: Setting large goals (e.g., "Build Hackathon App" or "Study for Exams") is overwhelming. Without broken-down milestones, execution stalling occurs.

---

## 3. Core Features & AI Mechanics

### A. Intelligent Priority Score Engine
The app calculates a real-time Priority Score (0 to 100) for every task:
$$\text{Priority} = \text{Urgency Factor} \times \text{Workload Ratio} \times \text{Complexity Weight} \times \text{Energy Weight}$$
* **Urgency**: Calculated using the time remaining before the deadline (increases exponentially as the deadline approaches).
* **Workload**: Compares the estimated task duration against the remaining hours before the deadline.
* **Complexity & Energy**: Modifies the base urgency score using the user's mental profile for the task.
Tasks are automatically sorted on the dashboard based on this priority score, showing users exactly what needs their attention first.

### B. AI-Decomposed Goal Milestones
Instead of a single monolithic goal, users enter their high-level objective, and the AI (powered by the Gemini API, with offline rule-based fallbacks) decomposes it into **5 progressive, actionable milestones**. Users can track the status (Pending, In Progress, Done) of each milestone to see their dynamic goal progress bar update.

### C. AI-Powered Auto-Scheduler
On the Timeline tab, clicking **AI Auto-Schedule** invokes an automated sequencing algorithm. It organizes all unscheduled tasks sequentially based on their priority scores and estimated durations, inserting a healthy 10-minute break between tasks to prevent burnout.

### D. Immersive Deep Focus Mode (Pomodoro Timer)
Clicking a task starts a full-screen Pomodoro focus session. It includes:
* Glowing double-ring visual timers ticking down.
* Integrated **Simulated Lo-Fi Wave Player** to aid concentration.
* **AI Productivity Coach** that cycles scientific tips for sustaining attention.
* An **Instant Complete** trigger that auto-updates task completion on the database and shows a celebration dialog.

### E. Proactive Context-Aware Nudge Overlay
An background timer checks task priorities every 30 seconds. If a high-importance task is due soon and the user is idle, a custom smart nudge toast slides down, prompting them to start a Pomodoro session immediately.

### F. Voice-Enabled NLP Assistant
Tapping the mic button opens a chatbot sheet. It processes natural language inputs (using Gemini AI/local regex parser) to:
* Add tasks ("add task write report due tomorrow")
* Start focus timers ("focus on top task")
* Auto-schedule ("schedule my day")

---

## 4. Technical Stack & Architecture
* **Frontend Framework**: Flutter (configured for Mobile, Desktop, and Web).
* **State Management**: flutter_bloc (BLoC Pattern) separating UI, Business Logic, and Data.
* **AI Integration**: google_generative_ai (Gemini 1.5 Flash Model).
* **Local Persistence**: SharedPreferences (JSON storage for offline reliability).
* **Linting & Quality**: Strict static analysis guidelines with `analysis_options.yaml` customized for clean compilations.

---

## 5. Deployment & Git Submission Instructions

### A. Initialize & Push to Git
Run these commands in your project root terminal to commit and push your code to your GitHub repository:
```bash
# 1. Initialize repository
git init

# 2. Stage all files
git add .

# 3. Create initial commit
git commit -m "feat: complete Last-Minute Life Saver MVP with navigation and memory fixes"

# 4. Create main branch and link your remote
git branch -M main
git remote add origin <PASTE_YOUR_GITHUB_REPOSITORY_URL_HERE>

# 5. Push to GitHub
git push -u origin main
```

### B. Deploying to GitHub Pages (Free Hosting)
Since we compiled the web build, you can host the application on GitHub Pages for free:
1. In your local terminal, install the `gh-pages` package globally or execute via npx:
   ```bash
   npx angular-cli-ghpages --dir=build/web
   # OR using the flutter gh-pages package:
   # Install peanut package to build automatically into a gh-pages branch:
   dart pub global activate peanut
   peanut
   git push origin gh-pages:gh-pages
   ```
2. Alternatively, simply drag-and-drop the `build/web` folder into **Netlify** or **Vercel** for instant, zero-config hosting.
