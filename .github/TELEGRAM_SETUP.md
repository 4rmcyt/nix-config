# Telegram Notifications Setup Guide

This guide will help you set up Telegram notifications for your CI workflows.

## Prerequisites

- A Telegram account
- Access to your GitHub repository settings

## Step 1: Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send the command `/newbot`
3. Follow the prompts to:
   - Choose a name for your bot (e.g., "My NixOS CI Bot")
   - Choose a username for your bot (must end in 'bot', e.g., "mynixos_ci_bot")
4. **Save the API token** you receive (looks like `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`)

## Step 2: Get Your Chat ID

### Option A: For Personal Messages (Recommended for Private Notifications)

1. Start a chat with your newly created bot by clicking the link BotFather provides
2. Send any message to your bot (e.g., "hello")
3. Open this URL in your browser, replacing `<YOUR_BOT_TOKEN>` with the token from Step 1:
   ```
   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
4. Look for the `"chat":{"id":` field in the response
5. **Save this chat ID** (it's a number, e.g., `123456789`)

### Option B: For Channel Notifications

1. Create a new Telegram channel
2. Add your bot as an administrator to the channel
3. Send a message to the channel
4. Use the same URL from Option A to get updates
5. Look for the chat ID (for channels, it will be negative, e.g., `-1001234567890`)

## Step 3: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following two secrets:

### Secret 1: TELEGRAM_BOT_TOKEN
- **Name**: `TELEGRAM_BOT_TOKEN`
- **Value**: The API token from Step 1 (e.g., `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`)

### Secret 2: TELEGRAM_CHAT_ID
- **Name**: `TELEGRAM_CHAT_ID`
- **Value**: The chat ID from Step 2 (e.g., `123456789` or `-1001234567890`)

## Step 4: Verify Setup

You can manually trigger the update workflow to test notifications:

1. Go to **Actions** tab in your GitHub repository
2. Select **Update Flake Lock** workflow
3. Click **Run workflow**
4. Enable the "Send Telegram notification" option
5. Click **Run workflow**

You should receive a Telegram notification when the workflow completes!

## Notification Behavior

### Update Flake Lock Workflow (`update-flake.yml`)
- **Scheduled runs**: Always sends notifications (daily at 3am UTC)
- **Manual runs**: Sends notifications only if you enable the "Send Telegram notification" option
- **Notifications sent**:
  - ✅ When flake.lock is updated (includes PR link)
  - ℹ️ When no updates are available

### CI Workflow (`ci.yml`)
- **Build failures**: Always notifies (except for pull requests)
- **Build successes**: Only notifies on main branch pushes
- **Pull requests**: No notifications (to avoid spam)
- **Per-system notifications**: You'll get separate messages for each system (desktop, homeserver, matebook, wsl)

## Customization

### Change Notification Frequency

Edit the schedule in `.github/workflows/update-flake.yml`:

```yaml
schedule:
  # Run daily at 3am UTC
  - cron: "0 3 * * *"
```

Use [crontab.guru](https://crontab.guru/) to create different schedules:
- `0 3 * * *` - Daily at 3am UTC
- `0 3 * * 1` - Weekly on Monday at 3am UTC
- `0 3 1 * *` - Monthly on the 1st at 3am UTC
- `0 */6 * * *` - Every 6 hours

### Disable Notifications for Specific Events

In `.github/workflows/ci.yml`, you can modify the `if` conditions:

```yaml
# Only notify on failures (remove success notifications)
- name: Send Telegram notification - Build Success
  if: false  # Disables this notification
```

### Change Notification Format

You can customize the message content in the `message:` field of any notification step.

## Troubleshooting

### Not Receiving Notifications?

1. **Check that secrets are set correctly**:
   - Go to Settings → Secrets and variables → Actions
   - Verify both `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` exist

2. **Verify bot can send messages**:
   - Send a message to your bot on Telegram
   - The bot should appear in your chat list
   - If you used a channel, ensure the bot is an admin

3. **Check workflow logs**:
   - Go to Actions tab → Select the failed workflow
   - Look for the notification step
   - Check for error messages

4. **Test the bot manually**:
   ```bash
   curl -X POST \
     "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage" \
     -d "chat_id=<YOUR_CHAT_ID>" \
     -d "text=Test message"
   ```

### Chat ID Issues

- Personal chat IDs are positive numbers (e.g., `123456789`)
- Channel/group IDs are negative numbers (e.g., `-1001234567890`)
- Make sure you don't include quotes around the ID in GitHub secrets

## Security Notes

- **Never commit bot tokens or chat IDs** to your repository
- Bot tokens grant access to send messages - keep them secret
- You can regenerate your bot token via @BotFather if it's compromised
- GitHub secrets are encrypted and only accessible to GitHub Actions

## Additional Resources

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [appleboy/telegram-action GitHub Action](https://github.com/appleboy/telegram-action)
