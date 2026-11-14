#!/bin/sh
# cw-gh-pages.sh - the gh-pages worktree, in one place.
#
# Two things publish to gh-pages: the documentation build, and the version list the router's
# upgrade notice reads. They must never write the branch at the same time (the workflow keeps
# them in one concurrency group) and they must not carry two copies of the same fetch/commit/push
# steps, because a mistake then happens twice.
#
# Usage:
#   tools/cw-gh-pages.sh prepare <dir>       create <dir> as a worktree of the published
#                                            gh-pages branch, or an empty orphan branch when
#                                            the repository has never published one
#   tools/cw-gh-pages.sh commit <dir> <msg>  stage everything in <dir>, commit it unless
#                                            nothing changed, and push the branch
#   tools/cw-gh-pages.sh done <dir>          remove the worktree again
#
# Run from inside the repository checkout that has `origin`.
set -eu

cmd="${1:?usage: cw-gh-pages.sh prepare|commit|done <dir> [<message>]}"
dir="${2:?usage: cw-gh-pages.sh prepare|commit|done <dir> [<message>]}"

case "$cmd" in
prepare)
    [ -d "$dir" ] && { echo "ERROR: $dir already exists" >&2; exit 1; }
    # The site commits carry the GitHub Actions bot identity: the site is generated, and a
    # personal identity hardcoded here would put one person's name on every fork's commits.
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    if git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
        git fetch -q origin gh-pages
        git worktree add -q "$dir" FETCH_HEAD
        git -C "$dir" checkout -q -B gh-pages
    else
        git worktree add -q --detach "$dir"
        git -C "$dir" checkout -q --orphan gh-pages
        git -C "$dir" rm -rqf . || true
    fi
    ;;
commit)
    msg="${3:?a commit message is required}"
    git -C "$dir" add -A
    # A run that changed nothing must not push an empty commit onto the site.
    if git -C "$dir" diff --cached --quiet; then
        echo "nothing to commit: gh-pages already holds this content"
        exit 0
    fi
    git -C "$dir" commit -q -m "$msg"
    git -C "$dir" push -q origin gh-pages
    echo "pushed gh-pages: $msg"
    ;;
done)
    git worktree remove --force "$dir" 2>/dev/null || rm -rf "$dir"
    ;;
*)
    echo "ERROR: unknown command '$cmd' (prepare|commit|done)" >&2
    exit 1
    ;;
esac
