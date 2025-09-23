# Logsai

Effortless journaling from voice, text, or photo. Logsai turns your day into a clean, structured entry using speech-to-text and intelligent summarization.

![OG_Image](https://github.com/user-attachments/assets/55fe4a9c-4e89-400f-a8da-27763402d4ef)

<p align="center">
  <a href="#preview">Preview</a> •
  <a href="#value-proposition">Value Proposition</a> •
  <a href="#the-pain-we-solve">The Pain We Solve</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#important">Important</a> •
  <a href="#environment-variables">Environment Variables</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#api-usage-notes">API Usage Notes</a> •
  <a href="#roadmap">Roadmap</a> •
  <a href="#team">Team</a> •
  <a href="#license">License</a> •
  <a href="#repo-about-and-topics">Repo About and Topics</a>
</p>

## Preview

<img width="1200" height="630" alt="Frame 43" src="https://github.com/user-attachments/assets/61523229-a9c2-4b0d-916d-76c7c39c9ff8" />

## Value Proposition
We make journaling effortless by turning your voice into natural, structured entries using speech-to-text and intelligent summarization, so you get a beautiful, organized journal without lifting a pen.

## The Pain We Solve
Journaling takes too much effort. Most people stop because typing or handwriting every day is hard to sustain.

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

```
### Important
Never commit your real API keys. Use `.env` and ensure `.gitignore` excludes it.

### Environment Variables
- `OPENAI_API_KEY` - required for speech to text and summarization.
- `OPENAI_MODEL` - optional, default set in code. Example: `gpt-4o`.
- `STORAGE_SERVICE` - optional. Example: `local` or `amazon` for Active Storage.

## How It Works
1. **Capture**
   - Voice is recorded and stored via Active Storage.
   - Text is submitted through a rich textarea.
   - Images are uploaded as attachments.
2. **Understand**
   - Audio is sent to a speech to text model for transcription.
   - Images are described and text is extracted. A short caption is generated.
3. **Summarize**
   - A prompt turns the raw text into an entry with: title, summary, key moments, optional tasks, and tags.
4. **Save and Display**
   - The final entry is stored as structured JSON plus rendered HTML for a nice card.

> Models you might see: `User`, `Entry`, `Attachment`, `Transcription`.

## Tech Stack
- Ruby on Rails 7
- OpenAI API for transcription and text generation
- Hotwire or React for smooth UX (choose one in your build)
- Active Storage for uploads
- SQLite in development, PostgreSQL in production (recommended)

## API Usage Notes
- Keep prompts short and consistent for cheaper runs.
- Rate limit and queue background jobs if you process long recordings.
- Show token counts in dev logs so you can estimate cost.

## Roadmap
- [ ] Mood extraction from text and voice
- [ ] Calendar view
- [ ] Export to PDF or Markdown
- [ ] Mobile-friendly audio recorder with silence trimming
- [ ] Private share links

## Team
- **Marlon Steiner**
- **Italo De Campo**

## License
MIT

## Repo About and Topics
Use this short About text in the GitHub sidebar:

> Effortless journaling from voice, text, or photo. Rails app that turns daily inputs into structured entries with AI summarization.

Suggested topics: `journaling`, `rails`, `ruby`, `openai`, `speech-to-text`, `summarization`, `cs50`, `ai`.

