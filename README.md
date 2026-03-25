# macOS Setup Scripts

A collection of shell scripts to automate new Mac deployments.

## Scripts

| Script | Purpose | Run as |
|--------|---------|--------|
| `install_software.sh` | Homebrew, apps (Chrome, VLC, Acronis, OmniDiskSweeper, etc.) | user |
| `customize_system.sh` | Finder, Dock, trackpad, Stage Manager preferences | user |
| `reclaim-space.sh` | Remove bloatware (iMovie, GarageBand) and clean up caches | `sudo` |
| `setup_dcxadmin_account.sh` | Create hidden admin account for remote support | `sudo` |

## Shared library

`common.sh` provides color output functions (`print_status`, `print_success`, `print_warning`, `print_error`, `print_divider`) and input prompts (`prompt_with_default`, `prompt_yn`). All scripts source it automatically.

## Usage

```bash
# Clone the repo
git clone git@github.com:jjspreij/macos.setup.git /Users/Shared/macos.setup
cd /Users/Shared/macos.setup

# 1. Install software (interactive prompts)
./install_software.sh

# 2. Customize system preferences
./customize_system.sh

# 3. Reclaim disk space (requires root)
sudo ./reclaim-space.sh

# 4. Set up hidden admin account (requires root + secrets.env)
source secrets.env
sudo -E ./setup_dcxadmin_account.sh
```

## Configuration

Scripts that support it can load settings from `~/.macos-setup.cfg`:

```bash
./install_software.sh -c          # Load config, prompt for changes
./install_software.sh -s          # Load config, skip all prompts
./install_software.sh -o          # Save config only, don't run
./install_software.sh -f file.cfg # Use a specific config file
```

A template config is provided in `macos-setup.cfg`.

## Secrets

`setup_dcxadmin_account.sh` reads the password from the `DCXADMIN_PASS` environment variable. Create a `secrets.env` file (git-ignored) with the password, or look up the 1Password note "DCXADMIN_PASS" for instructions.
