set -euo pipefail

if [[ -n "${BAZARR_MOVIE_FILEPATH:-}" ]]; then
    echo "Bazarr: Movie detected. Running movie-cleaner..."
    exec movie-cleaner
elif [[ -n "${BAZARR_EPISODE_FILEPATH:-}" ]]; then
    echo "Bazarr: Episode detected. Running show-cleaner..."
    exec show-cleaner
else
    echo "Bazarr: Error - No filepath detected in environment variables."
    exit 1
fi
