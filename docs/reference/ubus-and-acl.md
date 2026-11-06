---
title: "AWvoice ubus API and permissions"
description: "Every method the awvoice object answers with its arguments and replies, the front-end object, the events, the refusal words, and the grants that allow them."
updated: 2026-11-06
---

# The API and who may call it

The AWvoice page is a thin client over two things: the daemon's `ubus` object `awvoice`, and an rpcd
plugin that touches the files the daemon does not own. Everything the page can do, you can do from
the shell — with the same permissions.

```sh
ubus call awvoice status          # the line, right now
ubus call awvoice health          # everything the Health tab shows
ubus list 'awvoice*'              # what is published
```

## Object `awvoice`

### State

| method | arguments | replies |
|---|---|---|
| `status` | none | `state`, `line`, `hook`, `machine`, `quiet`, `call` (null, or `{id, direction, number, phase, elapsedSec}`), `voiceNetwork{registered, ims}`, `signal{rsrpDbm, network, operator, operatorName}`, `service{running}`, `myNumber` |
| `health` | none | the whole [Health tab](../awvoice/health-and-tests.md) payload: `atPort`, `line`, `modem`, `system`, `indicator`, `counters`, `machine`, `quiet`, `storage`, `web`, `sip` |
| `call_status` | none | the call view the browser phone draws: state, direction, number presence, held and waiting legs, the answer owner, the revision, the frame counters |
| `forwarding_get` | none | `network` as `on`/`off`/`unknown`, `to`, `delaySec`, `applying`, `error` |

### Acting on a call

| method | arguments | notes |
|---|---|---|
| `hangup` | none | ends the call from the line's side. A hang-up for a call that already ended is **accepted** |
| `send_dtmf` | `digit` | on the front-end object, below. The page's own keypad uses `web_dtmf` |
| `ring_test` | `seconds` | `1`–`10`. Anything else is refused as a bad argument before the daemon sees it |
| `line_test` | none | the reply is deferred until three samples 100 ms apart are in: `verdict`, `hook`, `batteryMv`, `expectedMv`, `loopUa`, `leakSuspect` |
| `reload` | none | re-reads `/etc/config/awvoice` without a restart |

### The browser phone

Every one of these is a request **as the browser**, and the daemon records the endpoint as
`browser` and the origin as `awvoice-web`.

| method | arguments | replies |
|---|---|---|
| `web_originate` | `number` | `{ok, refused}` |
| `web_answer`, `web_reject`, `web_hangup`, `web_flash` | none | `{ok, refused}` |
| `web_dtmf` | `digit` | the first character only |
| `web_audio_open` | `call_revision` | `{ok, refused, token, port, rate, frame_ms, expires_ms}` — the single-use token that admits one WebSocket session, valid 30 seconds |

### The log, the recordings, the messages, the greeting

| method | arguments | replies |
|---|---|---|
| `calls` | none | `{calls: [...]}`, one entry per record, newest first |
| `calls_delete` | `type` optional, `IN`, `OUT` or `MISS` | `{ok, removed}`. With no type, the whole log |
| `recordings` | none | `{recordings: [{name, bytes, rate, channels, seconds}]}` |
| `recording_get` | `name`, `offset` | `{name, total, offset, b64, more}` — 24 KiB of raw audio per reply |
| `recording_delete` | `name` | `{ok, removed}` |
| `messages` | none | as the recordings, with `ts` added |
| `message_get`, `message_delete` | as the recording pair | as the recording pair |
| `greeting_get` | `offset` | `{total, offset, b64, more}`. There is no `name`: one fixed file |
| `greeting_begin` | none | opens a staged write |
| `greeting_put` | `offset`, `b64` | up to 16 KiB of plain bytes per call |
| `greeting_commit` | `polish` | `1` asks for the trim-and-tone treatment. Waits for a quiet line and refuses with `-EBUSY` if it cannot get one |
| `greeting_abort` | none | discards the staged file |

!!! note "Every file name is checked before it is touched"
    `recording_get`, `recording_delete`, `message_get` and `message_delete` accept only a name of
    the exact form `<epoch>-<call id>.wav`, 7 to 64 characters. Anything else is refused before the
    filesystem is consulted, which is what makes the page's delete buttons safe to expose.

## Object `qmodem_voip`

This is the **front end** a network phone is carried through. It is published only while the SIP side
is on, the guards leave the line free, and no other program already holds the name.

| method | what you pass | notes |
|---|---|---|
| `status` | nothing | state, origin (always `cellular`), endpoint, `number_present`, `caller_id_withheld`, `remote_number`, duration, `held`, `waiting`, `revision`, `restart_epoch`, `sequence`, `drop_count`, `reconcile_pending`, `answer_owner`, `media_engine`, and the two media frame counters |
| `capabilities` | none | `media: "qmsk"`, `sample_rate: 8000`, `frame_ms: 20`, `frame_samples: 160`, `wideband: 0`, `calls: 1`, `endpoints: ["lan_sip", "cellular", "browser"]` |
| `originate` | `endpoint`, `number`, `origin`, `username` | the endpoint must be one of the three words, or the refusal is `refused-mode` |
| `answer` | none | takes over a call the answering machine holds. The reply waits up to 6 seconds for the call to list as active, and answers `no-answer` if it never does |
| `reject`, `hangup` | none | a hang-up with nothing to end is accepted |
| `send_dtmf` | `digit` | first character only |
| `issue_socket_session` | `call_revision` | returns `session_id`. Eight live bindings at once |

`flash` is **not** on this object — it is the browser page's own key.

## Events

| topic | payload | when |
|---|---|---|
| `awvoice.line` | `state`, `line` | the line changed |
| `awvoice.call` | `id`, `direction`, `phase` | a call started, changed, or `ended` |
| `qmodem_voip.call` | `ring`, `release`, `call_state` | the front end's own view. A DTMF digit is **not** published on it |

Events never carry a number. A ring during quiet hours is suppressed rather than announced.

## The refusal words

A refusal is always one fixed word, never a sentence, so a script can act on it.

| where | the words |
|---|---|
| line and call actions | `NO_CALL`, `OFF_HOOK`, `ACTIVE_CALL`, `SERVICE_DOWN`, `NOT_AVAILABLE` |
| the front end | `refused-busy`, `refused-nocall`, `refused-revision`, `refused-mode`, `refused-rate`, `refused-port`, `refused-object`, `dropped-slow`, `call-ended`, `internal` |
| the greeting | `MISSING`, `FORMAT`, `EMPTY`, `TRUNCATED`, `TOO_BIG`, `MEMORY`, `SYMLINK`, `BUSY`, `OFFSET`, `IO`, `UNREADABLE` |

## The rpcd plugin `luci.awvoice`

Three methods. They exist because the phone daemon does not own these things.

| method | arguments | what it does |
|---|---|---|
| `service` | `action` = `start`, `stop`, `restart` | drives `/etc/init.d/qmodem_voip_sipd` through `ubus call rc init`. Stop and restart are **refused while a call is active**, decided by reading `awvoice status` first. Refusals: `ACTIVE_CALL`, `NOT_AVAILABLE` |
| `sipdiag` | none | the service's settings file, its init script, the media socket, the credential file, the socket path, and the two process ids |
| `provision` | none | writes the provisioning file and answers `{file, url, expires, ttl, username, realm}` — or the reason it could not |

## Who may call what

rpcd reads the grants **when you log in** and keeps them for that visit. A method added by a new
`acl.d` file is not seen by a tab that logged in before the upgrade.

| if a control says *"This account may not do that"* | do this |
|---|---|
| on a router you upgraded in place | log out of LuCI and back in, and the new grants are read |
| still, after that | the grant is genuinely not there for that user. The page's ACL file is `root/usr/share/rpcd/acl.d/luci-app-awvoice.json` in the package |

What the shipped grants cover:

| grant | who has it |
|---|---|
| read and write `uci awvoice` | the AWvoice page's users |
| read and write `uci qmodem_sip` | the same — this is how the SIP card edits another package's file |
| read `uci uhttpd`, `uci network` | read-only, to find the plain listener and the interface addresses |
| call `awvoice` methods | the page |
| call `luci.awvoice` `service`, `sipdiag`, `provision` | the page. `service` is the one exact-string grant that lets the switch start and stop another package's init script |
| `ubus call awvoice health` from the shell | root, as always over SSH |

## From the shell

```sh
ubus call awvoice status
ubus call awvoice health | jq '.modem | {hdVoice, audioRate, voiceLayout}'
ubus call awvoice calls | jq '.calls | length'
ubus -v list awvoice                      # the method signatures, as the daemon declares them
ubus call luci.awvoice sipdiag            # what the SIP card reads
logread -e awvoice-phoned | tail -20
```

## Next

| | |
|---|---|
| What the fields mean | [health and tests](../awvoice/health-and-tests.md) |
| Where the files are | [files and ports](files-and-ports.md) |
| The options | [settings reference](../awvoice/settings-reference.md) |
