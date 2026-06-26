# Project Description: The Last-Minute Life Saver

## 1. Project Title
**The Last-Minute Life Saver** - An AI-powered productivity companion built for the Vibe2Ship Hackathon.

## 2. Description
The Last-Minute Life Saver is an interactive, stress-reducing copilot that proactively helps students, professionals, and entrepreneurs plan, prioritize, and complete their tasks before deadlines are missed. Instead of passive alerts that are easily dismissed, the app helps users combat task paralysis and take immediate action through smart priority calculation and immersive focus sessions.

---

## 3. Key Features

* **Intelligent Task Prioritization**: Real-time priority scores (0-100) are calculated dynamically based on urgency, workload, complexity, and energy level. Tasks are automatically sorted on the dashboard.
* **AI Auto-Scheduler**: Sequentially arranges unscheduled tasks into optimal hourly time slots on the Timeline tab, introducing 10-minute breaks to avoid burnout.
* **Proactive Nudge Reminders**: A background task checks deadlines every 30 seconds, popping up a custom alert to prompt the user to start focusing on critical tasks.
* **Immersive Deep Focus Mode**: A full-screen Pomodoro timer (25 minutes) with glowing progress indicators, simulated Lo-Fi focus beats, and scientific AI coaching tips.
* **AI Goal Decomposition**: Breaks down broad goals (like "Study for Exam" or "Prepare Hackathon") into 5 actionable, progressive milestones.
* **Streaks & Habits**: Daily consistency tracking with category chips (Health/Sleep, Study, Work, Personal) and streak flames.
* **Voice-Enabled NLP Assistant**: A conversational assistant powered by Gemini to add tasks, schedule timelines, or start timers using natural speech/text.

---

## 4. Tech Stack & Architecture
* **Frontend**: Flutter (Mobile, Web, Desktop)
* **State Management**: BLoC Pattern (TaskBloc, FocusBloc, GoalBloc, HabitBloc)
* **AI Models**: Google Generative AI (Gemini 1.5 Flash)
* **Local Storage**: SharedPreferences (Offline data persistence)
