# Yall 🗣️

**Y**et **A**nother **L**ink **L**ogger - Because shouting into the void is only fun when you can do it across MULTIPLE voids simultaneously! 

A cross-platform desktop application that lets you post to Mastodon, Bluesky, Nostr, X (Twitter), and Micro.blog all at once. Because why have one social media addiction when you can have five? 🤷‍♂️

## Features 🚀

- 🎯 **Multi-Platform Posting**: Spam your thoughts to Mastodon, Bluesky, Nostr, X, and Micro.blog simultaneously (your followers will thank you... maybe)
- 🔒 **Secure Credential Storage**: Your API keys are safer than your browser history
- 🎨 **Modern UI**: So pretty you'll actually want to use it (revolutionary concept)
- 💻 **Desktop Native**: System tray integration because closing apps is for quitters
- ⌨️ **Keyboard Shortcuts**: For when clicking is too mainstream
- 🔄 **Auto-Retry Logic**: Persistent like your ex, but actually helpful
- 🛡️ **Error Handling**: Fails gracefully, unlike my life choices
- ♿ **Accessibility**: Everyone deserves to post regrettable content equally
- 🧹 **Auto-Clear Success Messages**: Because staring at "success" for eternity gets old
- 🗂️ **Collapsible Platform Selector**: Saves space and your sanity

## Why "Yall"? 🤔

Because "Y'all need to stop using so many different social media platforms" was too long for a repo name. Also, it's like "Y'all" but shorter. We're efficient here.

## Installation 📦

### Linux (The Chosen OS)

#### Quick Install
```bash
# Download and run our installer (trust us, we're basically professionals)
wget https://github.com/timappledotcom/yall/releases/latest/download/install-linux.sh
chmod +x install-linux.sh
./install-linux.sh
```

#### Package Managers (For the Sophisticated)
```bash
# Debian/Ubuntu (.deb package)
wget https://github.com/timappledotcom/yall/releases/latest/download/yall_1.0.4_amd64.deb
sudo dpkg -i yall_1.0.4_amd64.deb

# RedHat/Fedora (.rpm package)
wget https://github.com/timappledotcom/yall/releases/latest/download/yall-1.0.4-1.x86_64.rpm
sudo rpm -i yall-1.0.4-1.x86_64.rpm
```

#### Building from Source (For the Brave)
```bash
git clone https://github.com/timappledotcom/yall.git
cd yall
flutter pub get
flutter build linux --release
./install-linux.sh
```

## Platform Setup 🛠️

### X (Twitter) - The Social Media That Shall Not Be Named 🐦‍⬛

Setting up X is like getting a driver's license - unnecessarily complicated and requires way too much paperwork. But hey, at least you only have to do it once!

#### Step 1: Get Developer Access (Good Luck!)
1. Apply for Twitter Developer access at [developer.twitter.com](https://developer.twitter.com)
2. Wait for approval (could be minutes, could be months, could be never - it's like dating!)
3. Pray to the API gods
4. Sacrifice a rubber duck to Elon

#### Step 2: Create Your App
1. Once approved (congratulations, you're one of the chosen ones!), create a new app
2. Give it a name (may we suggest "YallBot" or "SocialMediaSinner")
3. Description: "For posting regrettable thoughts across multiple platforms"
4. **Callback URL**: Use `http://localhost:8080/callback` or `yall://oauth/callback`
5. Enable "Read and Write" permissions (we're not here to just lurk)

#### Step 3: Get Your Keys (The Sacred Ritual)
You'll need FOUR keys (because one wasn't complicated enough):

1. **API Key** (Consumer Key) - Think of it as your app's first name
2. **API Secret** (Consumer Secret) - Your app's embarrassing middle name
3. **Access Token** - Your personal "yes I can post" badge  
4. **Access Token Secret** - The secret handshake that proves you're legit

#### Step 4: Configure Yall
1. Open Yall (obviously)
2. Go to Settings → Accounts → Add Account → X
3. Enter all four keys (yes, all four, we're thorough here)
4. Cross your fingers, toes, and any other crossable appendages
5. Test with a humble "hello world" (save the controversial takes for later)

**Pro Tips for X Setup:**
- Keep your keys secret, keep them safe (like Gollum, but with APIs)
- The callback URL doesn't need to actually exist (Twitter's quirky like that)
- If it doesn't work, try turning Twitter off and on again (kidding, don't)
- Remember: With great API access comes great responsibility (and rate limits)

### Mastodon - The Civilized Social Network 🐘

1. Go to your Mastodon instance (you know, that place where people are actually nice)
2. Settings → Development → New Application
3. Name it whatever makes you happy
4. Grant "read" and "write" permissions (we promise to be responsible)
5. Copy the access token (it's the long scary-looking string)
6. Paste it into Yall's Mastodon settings
7. Enjoy civilized discourse!

### Bluesky - The Twitter Alternative That Might Actually Work 🦋

1. Get your Bluesky handle (the `@something.bsky.social` thingy)
2. Go to Settings → App Passwords in Bluesky
3. Create a new app password (not your real password, that would be silly)
4. Use your handle and app password in Yall
5. Post about how much better Bluesky is than Twitter (it's tradition)

### Nostr - The Decentralized Wildcard ⚡

1. Generate a key pair in Yall (we'll do the crypto magic for you)
2. Or import your existing private key (if you're already part of the resistance)
3. Configure relay servers (or use our defaults and trust our questionable judgment)
4. Welcome to the decentralized future!

### Micro.blog - The Blogger's Paradise 📝

1. Get your Micro.blog username
2. Generate an app token in your Micro.blog account settings
3. Enter both in Yall
4. Blog responsibly!

## Keyboard Shortcuts ⌨️

Because clicking is so last century:

- `Ctrl+N`: Focus on new post (like Ctrl+N for "New regret")
- `Ctrl+Enter`: Send post to the void(s)
- `Ctrl+,`: Open settings (comma for "configure")
- `Escape`: Cancel operation (escape your poor life choices)
- `F1`: Show help (when all else fails)

## FAQ 🤔

**Q: Why does X require so many credentials?**
A: Because Twitter's API was designed by people who think "simple" is a four-letter word.

**Q: Will this make me internet famous?**
A: Probably not, but you'll fail spectacularly across multiple platforms simultaneously!

**Q: Is this app spying on me?**
A: Only if you consider "making your posts visible on social media" spying. We're not the NSA, we're just developers who like over-engineering solutions.

**Q: What if a platform goes down?**
A: The app will retry a few times, then gracefully give up (unlike your Twitter addiction).

**Q: Can I schedule posts?**
A: Not yet, but it's on our roadmap (somewhere between "fix that one bug" and "achieve world peace").

## Contributing 🤝

Want to make Yall even more chaotically useful? We accept:
- Bug reports (with detailed descriptions of how you broke it)
- Feature requests (the more ridiculous, the better)
- Pull requests (code quality optional, enthusiasm required)
- Memes (always welcome)

## Support 💬

If something's broken (and it probably is), check our [GitHub Issues](https://github.com/timappledotcom/yall/issues) or create a new one. Include:
- What you did
- What you expected to happen  
- What actually happened
- Your favorite emoji (for emotional support)

## License 📄

MIT License - because we believe in freedom (and limiting our liability).

## Roadmap 🗺️

Coming soon(ish):
- [ ] Post scheduling (for when you want to regret things in advance)
- [ ] Draft management (save your bad ideas for later)
- [ ] Thread support (because one post isn't enough chaos)
- [ ] Post analytics (see how your content performs across the void)
- [ ] More platforms (because 5 isn't enough, apparently)
- [ ] Mobile app (for portable regret)
- [ ] AI integration (because everything needs AI these days)

## Credits 🙏

Built with Flutter, caffeine, and questionable life decisions. Thanks to:
- The Flutter team (for making cross-platform development slightly less painful)
- All the social media platforms (for existing and giving us things to complain about)
- You (for reading this far - you're the real MVP)

---

*Remember: With great posting power comes great responsibility. Use Yall wisely, or at least entertainingly.* 🚀
