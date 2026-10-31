# Getting the API keys

A step-by-step guide for everyone who installs Framebook, the developer and
friends alike. The keys are free, and everyone has their own. Why the app
doesn't ship with keys of its own is in [project-brief.md](project-brief.md):
in short, without a server a built-in key can be pulled out of the APK, and
the limits would be shared by everyone.

A Russian translation for the app's users is in
[api-keys.ru.md](api-keys.ru.md); the app opens it when its interface is in
Russian. Keep the two in step.

| Service | Required | What it gives in the app | Time to get it |
|---|---|---|---|
| TMDB | **yes** | search, title cards, seasons and episodes, posters, TMDB rating | 10–15 minutes, key right away |
| PoiskKino | no | Kinopoisk rating, sorting by divergence from Kinopoisk | Telegram registration |
| OMDb | no | IMDb, Rotten Tomatoes, Metacritic | 5 minutes + an activation email |

Without a PoiskKino key there is no Kinopoisk rating. Without an OMDb key
there is no RT or Metacritic, and IMDb for films and series comes from
PoiskKino, if its key is set. Details are in
[external-sources.md](external-sources.md).

The PoiskKino bot registration steps reflect the user's experience; its
[site](https://poiskkino.dev/) confirms the bot and free-plan limit. The
sites' forms are described as of October 2026. If a field is named a
little differently, go by its meaning.

---

## 1. TMDB (The Movie Database)

**Use a computer to register the account and request the API key.**
[TMDB says](https://developer.themoviedb.org/docs/getting-started) its key
registration is not adapted for phones.

### 1.1. Account

1. Sign up at [themoviedb.org/signup](https://www.themoviedb.org/signup):
   username, password, email.
2. Confirm the email with the link in the message. The API section won't
   open until you do.

### 1.2. Applying for a key

1. Open [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)
   (profile → Settings → API) and press **Create** (or "click here" in the
   text about requesting a key).
2. Key type: **Developer**. Professional is for commercial projects, which
   this isn't.
3. Read and accept the terms of use (**Accept**).
4. Fill in the form, all in English.

**About the application:**

| Field | What to enter |
|---|---|
| Type of Use | **Mobile Application**. If there is no such option, the closest one (Personal / Other) |
| Application Name | `Framebook` |
| Application URL | `https://github.com/tiltozavr2545/Framebook` — fine for everyone, friends included: it is the project's real page |
| Application Summary | the text below, as is |

Application Summary:

```
Framebook is a personal, non-commercial Android app for keeping my own
film and TV ratings and comparing them with public ratings. TMDB is used
for search, title details, seasons and episodes, and posters. The key is
used only by me, from my own phone; no data is resold, cached publicly or
redistributed, and the app shows TMDB attribution on its About screen.
Source code: https://github.com/tiltozavr2545/Framebook
```

**Contact details:**

| Field | What to enter |
|---|---|
| First Name / Last Name | your first and last name in Latin letters |
| Email Address | the account's email |
| Phone Number | in international format, with the country code (`+31…`, `+7…`) |
| Address 1 | street and house number |
| Address 2 | may stay empty |
| Zip Code | postal code |
| City | city |
| State / Province | region; if your country has no states, repeat the city or region |
| Country | country |

TMDB needs the contacts to reach the key's owner; they are not published.
The terms of use require accurate details, so fill them in truthfully. The
country is where you actually live.

5. **Submit**. A Developer key is usually approved instantly: after
   submitting, the same Settings → API page opens, now with the keys.

### 1.3. Which key to take

The Settings → API page shows two values:

- **API Key** — short, 32 characters (`a1b2c3…`);
- **API Read Access Token** — long, starts with `eyJ…`.

They have the same rights. Take the **API Read Access Token**: it travels in
a header rather than in the request URL, so it doesn't end up in logs. The
app accepts the short key too, if that is handier.

### 1.4. Checking it

```sh
curl -s https://api.themoviedb.org/3/movie/603 \
  -H "Authorization: Bearer YOUR_TOKEN" | head -c 200
```

You should get JSON with `"title":"The Matrix"`. `"status_code":7` means the
key is wrong; `"status_code":34` means the film id is wrong (so the key
works).

### 1.5. Limits

- Non-commercial use only; TMDB attribution in the app is mandatory (it is
  on the About screen).
- No daily limit, only a rate limit of a few dozen requests a second —
  unreachable for one person.

---

## 2. PoiskKino (Kinopoisk rating)

An unofficial API over Kinopoisk data (formerly kinopoisk.dev). The key comes
from a Telegram bot; there is no website account.

1. Open the bot **[@poiskkinodev_bot](https://t.me/poiskkinodev_bot)** and
   press **Start**.
2. The bot asks you to join **both** its discussion group and its Telegram
   channel. Open the links it provides, join both, then return to the bot
   and complete its membership check.
3. Follow the bot's prompts and select the free **"Демо"** plan (200
   requests a day). Paid plans are not needed for Framebook.
4. Copy the entire key the bot provides and paste it into Framebook.

**Stay subscribed to both the group and the channel:** the bot disables the
key if you leave either one. If a key stops working, check both memberships
and follow the bot's instructions.

The bot's buttons may be named differently from this; the point is to get a
key on the free plan. The bot is also where you check the remaining limit
and reissue a key that leaked.

**Checking it** (spends 1 of the 200 daily requests):

```sh
curl -s https://api.poiskkino.dev/v1.5/movie/301 \
  -H "X-API-KEY: YOUR_KEY" | head -c 200
```

You should get JSON about The Matrix (`"id":301`). `401` means a wrong key;
an error mentioning the limit means today's requests are used up, and the
key works again the next day.

**Limits:** 200 requests a day per key. The app spends them sparingly
(cache, request budget — see [external-sources.md](external-sources.md)), but
a large library of ratings fills up with Kinopoisk ratings gradually, over
several days.

---

## 3. OMDb (IMDb, Rotten Tomatoes, Metacritic)

1. Open [omdbapi.com/apikey.aspx](https://www.omdbapi.com/apikey.aspx).
2. Account Type: **FREE! (1,000 daily limit)**. Patreon is paid and not
   needed.
3. Fill in:

   | Field | What to enter |
   |---|---|
   | Email | a working mailbox — the key is sent there |
   | First Name / Last Name | first and last name |
   | Use | `Personal non-commercial Android app to compare my own film ratings with IMDb, Rotten Tomatoes and Metacritic.` |

4. **Submit**. An email arrives with the key (7–8 characters, e.g.
   `1a2b3c4d`) and an **activation link**. You **must open the link**: until
   then the key answers with an error.
5. The email can take up to an hour. Outlook, Hotmail and Live receive it
   worst — Gmail is better. Nothing after an hour: check spam; if it isn't
   there either, the service's author asks to be contacted directly (the
   contact is on omdbapi.com).

**Checking it:**

```sh
curl -s "https://www.omdbapi.com/?i=tt0133093&apikey=YOUR_KEY" | head -c 200
```

You should get JSON with `"Title":"The Matrix"` and `"Response":"True"`.
`"Error":"Invalid API key!"` means the key is wrong or not activated (see
step 4); `"Error":"Request limit reached!"` means today's limit is used up.

**Limits:** 1,000 requests a day; OMDb data is CC BY-NC 4.0, so
non-commercial use only.

---

## 4. Where the keys go

**In the app:** on first launch there is a key entry screen, later Settings
→ Sources. The app checks each key with a trial request and stores it in the
phone's secure storage. Optionally enable encrypted key sync in Settings →
Sync and backup to keep a password-encrypted copy in your own Google Drive.
A new phone can restore it from the first-launch screen. Rating exports and
daily rating backups do not contain the keys. Each service is merged
independently, so unlocking does not replace a key that exists only on one
phone; removals are synchronized too.

**For the developer, to capture fixtures** — in a file outside the
repository:

```sh
mkdir -p ~/.config/framebook
umask 077
nano ~/.config/framebook/keys.env
```

```sh
TMDB_TOKEN=eyJ...
POISKKINO_KEY=...
OMDB_KEY=...
```

Then run `scripts/capture-fixtures.sh` — more in [operations.md](operations.md).

---

## 5. Keeping keys safe

- A key is personal. Don't commit it, don't send it to chats (including a
  chat with an AI assistant), don't show it in screenshots.
- If it leaked or was exposed:
  - **PoiskKino** — reissue it in the bot;
  - **OMDb** — request a new one on the same page (with another email) and
    write to the service's author to disable the old one;
  - **TMDB** — look for key regeneration in Settings → API; if it isn't
    there, write to TMDB support.

  Then put the new key into the app and into `keys.env`.
- Don't hand your keys to friends: limits are counted per key, not per
  person, and someone else's app will spend your 200 PoiskKino requests.
