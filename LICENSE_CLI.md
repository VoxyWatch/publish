# Product license command-line installation

VoxyWatch can install or replace its product license without opening the web portal. The command
validates the vendor RSA signature, hardware binding and expiry **before** changing the active file.
It never stops or restarts the HEP sniffer.

## Install from a file

Transfer the license file to the server through your normal secure administration channel, then run:

```sh
sudo /opt/voxywatch/voxywatch-portal license install /path/to/license.key
```

## Install through standard input

To avoid keeping another copy on the server:

```sh
sudo /opt/voxywatch/voxywatch-portal license install --stdin < license.key
```

The full `/opt/voxywatch/voxywatch-portal license` entrypoint is canonical and works immediately on
the first signed upgrade from any older installer. Fresh installations, and systems where the current
installer has already run, also provide the shorter convenience alias:

```sh
sudo voxywatch-license install /path/to/license.key
```

Do not paste the license value as a command-line argument or place it in a shell variable. The CLI
accepts only a file path or `--stdin`, so license material does not appear in process listings or in
normal command output.

## Safety behavior

- Root is required because the canonical destination is `/etc/voxywatch/license.key`.
- Input is capped at 64 KiB and rejected unless signature, HWID and expiration are valid.
- Invalid input leaves the current license unchanged.
- Installation uses a same-directory temporary file, `fsync`, atomic rename and mode `0640`
  (`root:voxywatch`).
- If `voxywatch.service` is active, only that portal service is restarted. The sniffer remains live.
- If the portal restart fails, the previous license is restored and the restart is retried.
- If the portal is stopped, the valid license is installed and takes effect on its next start.

Successful output contains only safe status metadata (plan and expiration), never the license value.

## Exit codes

| Code | Meaning |
|---:|---|
| 0 | License installed and validated. |
| 2 | Invalid command syntax. |
| 3 | Command was not run as root. |
| 4 | Source could not be read. |
| 5 | Source exceeds 64 KiB. |
| 6 | Signature, HWID, expiration or license format was rejected. |
| 7 | Activation failed; the previous license was restored. |

The portal remains an equivalent activation path under **Settings → License**.
