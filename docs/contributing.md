# Contributing

Improvements are welcome: fixes, documentation, test reports and package suggestions.

## Reporting problems

See [Repositories](repositories.md) for which repository an issue belongs in.

Open an [issue](https://github.com/Pr0Luci/cleanwrt-aw1000/issues). Include:

- the CleanWRT version (`cat /etc/openwrt_release`),
- what you expected and what happened,
- the relevant log lines (`logread`, or the output of `cw-diag full`).

!!! danger "Never post secrets"
    Do not paste passwords, Wi-Fi keys, tokens or full IMEI/IMSI/ICCID numbers.

## Changing the repository

`main` is protected. The rules:

1. Every change is a **pull request**; nobody pushes to `main` directly.
2. The checks must pass before a pull request can be merged.
3. Pull requests are merged with **squash merge**, and the branch is deleted afterwards.

```sh
git clone https://github.com/Pr0Luci/cleanwrt-aw1000.git
cd cleanwrt-aw1000
git checkout -b my-change
# edit, then:
git commit -am "Short description of the change"
git push -u origin my-change
```

Then open a pull request on GitHub.

## Writing docs

The documentation is the `docs/` folder, built with MkDocs Material. Every page has an *Edit this
page* button that opens the right file on GitHub.

```sh
pip install mkdocs-material
mkdocs serve        # preview at http://127.0.0.1:8000
```

The package list page is generated from the build seed; do not edit it by hand.

## Rules for changes to the firmware

- Keep the overlay small. A new file in `files/` ships on every router.
- A new feed patch must apply with zero fuzz to the pinned commit. Say in its header what it
  changes and why.
- Anything that adds a listening service must ship **disabled**.
- Do not add translations or internal wording. Keep comments plain and short.
- Do not commit keys. `keys-release/` and `private-key.pem` are ignored for a reason.
