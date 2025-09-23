# logsai

Effortless journaling from voice, text, or photo. Logsai turns your day into a clean, structured entry using speech-to-text and intelligent summarization.

![OG_Image](https://github.com/user-attachments/assets/55fe4a9c-4e89-400f-a8da-27763402d4ef)



<p align="center">
  <a href="#demo">Demo</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#roadmap">Roadmap</a> •
  <a href="#team">Team</a>
</p>

---

## Preview


---

## Value Proposition
We make journaling effortless by turning your voice into natural, structured entries using speech-to-text and intelligent summarization, so you get a beautiful, organized journal without lifting a pen.

---

## The Pain We Solve
Journaling takes too much effort. Most people stop because typing or handwriting every day is hard to sustain.

---

## Features
- **Three ways to input your day**
  - **Speak**: record yourself. Logsai transcribes your audio with speech-to-text.
  - **Write**: type your day as you would in any journal.
  - **Snap**: add an image. We extract useful context and turn it into text for the journal entry.
- **AI summarization**: your raw input becomes a short, natural summary plus a structured outline with highlights, tasks, and tags.
- **Clean timeline**: entries are displayed as attractive cards with date, mood, key moments, and optional media.
- **Searchable memory**: find entries by keyword or tag.

> Built with **Ruby on Rails** and the **OpenAI API**.

---

## Demo
- Add a short video or GIF: `docs/demo.gif`
- Live app link if deployed: `https://your-deploy.example` (optional)

---

## Quick Start
**Prerequisites**: Ruby 3.x, Rails 7, Node.js, Yarn or Bun, SQLite or PostgreSQL, Git.

```bash
# 1) Clone
git clone https://github.com/<your-username>/logsai.git
cd logsai

# 2) Environment
cp .env.example .env
# open .env and set your keys
# OPENAI_API_KEY=sk-...

# 3) Install deps
bundle install
# if you use js bundling: yarn install

# 4) Database
bin/rails db:setup

# 5) Run the app
bin/rails server
# or if you use foreman or bin/dev
# bin/dev
